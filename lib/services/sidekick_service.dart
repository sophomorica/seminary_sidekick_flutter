import 'dart:convert';

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sidekick_response.dart';
import '../models/sidekick_snapshot.dart';
import 'crash_reporting_service.dart';

/// Returns the most recent [window] messages for the API context.
///
/// Prefer this over [Iterable.take] — `take(n)` keeps the *oldest* n, which
/// permanently drops recent context once a conversation exceeds the window.
List<SidekickMessage> selectRecentChatHistory(
  List<SidekickMessage> history, {
  int window = SidekickService.apiHistoryWindow,
}) {
  if (history.length <= window) return List<SidekickMessage>.of(history);
  return history.sublist(history.length - window);
}

/// Low-level service that talks to the Seminary Sidekick AI.
///
/// Requests are routed through the `sidekick-proxy` Supabase Edge Function,
/// which holds the xAI (Grok) API key server-side and injects an authoritative
/// safety system prompt. The key is therefore NEVER shipped in the app binary.
/// See `supabase/functions/sidekick-proxy/index.ts` and `SUPABASE_SETUP.md`.
///
/// The service is stateless — all state lives in `SidekickProvider`.
class SidekickService {
  /// Name of the deployed Supabase Edge Function that proxies to xAI.
  static const String _proxyFunction = 'sidekick-proxy';

  /// Send the user's snapshot to the Sidekick and get a structured response.
  ///
  /// Returns a [SidekickResponse] parsed from the AI's JSON output.
  /// Throws on network errors — caller should catch and use cached fallback.
  Future<SidekickResponse> getSessionResponse(SidekickSnapshot snapshot) async {
    final messages = [
      {'role': 'system', 'content': _systemPrompt},
      {
        'role': 'user',
        'content': 'Here is my current progress snapshot. '
            'Please respond with a JSON object following the SidekickResponse schema.\n\n'
            '```json\n${jsonEncode(snapshot.toJson())}\n```',
      },
    ];

    final body = await _chatCompletion(messages);
    return _parseResponse(body);
  }

  /// How many prior messages are included in the API context (excludes the
  /// new user turn, which is appended separately). Tunable.
  static const int apiHistoryWindow = 20;

  /// Send a direct chat message to the Sidekick with conversation history.
  ///
  /// [history] contains previous messages (role: user/assistant) — do **not**
  /// include [userMessage]; it is appended once at the end.
  /// [snapshot] provides context about the user's current state.
  /// [userMessage] is the new message from the user.
  ///
  /// Returns the assistant's reply as a plain string.
  Future<String> chat({
    required SidekickSnapshot snapshot,
    required List<SidekickMessage> history,
    required String userMessage,
  }) async {
    final recent = selectRecentChatHistory(history);
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': _chatSystemPrompt},
      {
        'role': 'user',
        'content': 'Context — my current progress:\n'
            '```json\n${jsonEncode(snapshot.toJson())}\n```\n\n'
            'Please keep this context in mind but respond conversationally.',
      },
      {'role': 'assistant', 'content': 'Got it — I have your progress context. How can I help?'},
      // Most recent prior turns (not the oldest — see selectRecentChatHistory)
      ...recent.map((m) => m.toApiMessage()),
      // New user message (exactly once)
      {'role': 'user', 'content': userMessage},
    ];

    final body = await _chatCompletion(messages);
    return _extractTextContent(body);
  }

  /// Forward a chat-completion request to the `sidekick-proxy` Edge Function.
  ///
  /// The function injects the xAI key + the authoritative safety system prompt
  /// server-side and returns the raw xAI/OpenAI-format completion JSON. The
  /// current (anonymous) Supabase session authorizes the call automatically.
  Future<Map<String, dynamic>> _chatCompletion(
    List<Map<String, dynamic>> messages,
  ) async {
    final SupabaseClient client;
    try {
      client = Supabase.instance.client;
    } catch (_) {
      // Supabase was never initialized (no credentials at build time) — the
      // backend that holds the Grok key is unreachable. Caller falls back to
      // the cached / offline response.
      throw const SidekickServiceException(
        'Sidekick is unavailable — backend not configured.',
      );
    }

    // RevenueCat app-user ID lets the proxy verify the `premium` entitlement
    // server-side before spending xAI tokens. Null when RevenueCat isn't
    // configured (dev builds) — the proxy only enforces the check when its
    // REVENUECAT_SECRET_KEY secret is set.
    //
    // The `isConfigured` guard is load-bearing: calling `Purchases.appUserID`
    // before `Purchases.configure(...)` triggers a native Swift fatalError
    // that Dart try/catch CANNOT intercept — the app hard-crashes.
    String? appUserId;
    try {
      if (await Purchases.isConfigured) {
        appUserId = await Purchases.appUserID;
      }
    } catch (_) {
      appUserId = null;
    }

    try {
      final res = await client.functions.invoke(
        _proxyFunction,
        body: {
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 1500,
          if (appUserId != null) 'app_user_id': appUserId,
        },
      );

      final data = res.data;
      if (data is Map<String, dynamic>) return data;
      if (data is String && data.isNotEmpty) {
        return jsonDecode(data) as Map<String, dynamic>;
      }
      throw const SidekickServiceException(
        'Unexpected response from the Sidekick proxy.',
      );
    } on FunctionException catch (e, st) {
      if (e.status == 403) {
        // Proxy entitlement gate — subscription lapsed, stale client cache,
        // or RevenueCat API unreachable (gate fails closed). Never surface
        // the raw status/details string to the user (TASK-067).
        CrashReportingService.addBreadcrumb(
          'sidekick-proxy 403 entitlement gate',
          category: 'sidekick',
        );
        await CrashReportingService.recordError(
          e,
          st,
          hint: 'sidekick-proxy entitlement 403',
        );
        throw const SidekickEntitlementException();
      }
      if (isTransientSidekickStatus(e.status)) {
        // Upstream overload / gateway blip (incl. xAI 529). Expected and
        // retryable — breadcrumb only; do not open a Sentry issue (FLUTTER-6).
        CrashReportingService.addBreadcrumb(
          'sidekick-proxy transient upstream ${e.status}',
          category: 'sidekick',
        );
        throw const SidekickUnavailableException();
      }
      throw SidekickServiceException(
        'Sidekick request failed (status ${e.status}): ${e.details}',
      );
    }
  }

  /// True for retryable upstream / gateway statuses from `sidekick-proxy`.
  ///
  /// Includes Cloudflare / provider overload `529` (FLUTTER-6).
  static bool isTransientSidekickStatus(int? status) =>
      status != null && _transientUpstreamStatuses.contains(status);

  static const Set<int> _transientUpstreamStatuses = {429, 502, 503, 529};

  /// Parse a structured SidekickResponse from the API's JSON output.
  SidekickResponse _parseResponse(Map<String, dynamic> apiResponse) {
    try {
      final content = _extractTextContent(apiResponse);

      // The AI should return JSON, but it might wrap it in markdown code fences.
      final jsonStr = _extractJsonFromText(content);
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
      return SidekickResponse.fromJson(parsed);
    } catch (e) {
      // If the AI returned something unparseable, wrap whatever we got.
      final content = _extractTextContent(apiResponse);
      return SidekickResponse(
        dailyPrompt: content,
        generatedAt: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Extract the text content from an xAI/OpenAI-format chat completion.
  String _extractTextContent(Map<String, dynamic> apiResponse) {
    final choices = apiResponse['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw const SidekickServiceException('Empty response from API');
    }
    final message = choices[0]['message'] as Map<String, dynamic>;
    return message['content'] as String? ?? '';
  }

  /// Strip markdown code fences from AI output to get raw JSON.
  String _extractJsonFromText(String text) {
    final trimmed = text.trim();

    // Try to find JSON in code fences: ```json ... ``` or ``` ... ```
    final fencePattern = RegExp(r'```(?:json)?\s*\n?([\s\S]*?)\n?```');
    final match = fencePattern.firstMatch(trimmed);
    if (match != null) {
      return match.group(1)!.trim();
    }

    // If it starts with { or [, assume it's raw JSON
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      return trimmed;
    }

    // Last resort — return as-is and let the caller handle parse failure
    return trimmed;
  }

  /// No persistent resources to release (the proxy uses the shared Supabase
  /// client). Kept for API compatibility with callers that dispose the service.
  void dispose() {}

  // ─── System Prompts ──────────────────────────────────────────────────────

  /// Shared safety + scope guardrails appended to every Sidekick prompt.
  ///
  /// Note: the `sidekick-proxy` Edge Function ALSO prepends an authoritative
  /// copy of these rules server-side, so they hold even if a tampered client
  /// alters the prompts below. Keep the two in sync when editing.
  static const String _safetyGuardrails = '''
SAFETY & SCOPE (these rules always take priority):
- Your audience is seminary students, and many are minors (roughly ages 14–18). Keep everything strictly age-appropriate. Never produce sexual, violent, graphic, hateful, or otherwise mature content, and never ask for personal identifying information.
- You are a study aid, NOT an ecclesiastical authority. You do not speak for The Church of Jesus Christ of Latter-day Saints or its leaders, and you do not issue official doctrinal rulings or worthiness judgments. For doctrinal questions, personal spiritual matters, or questions about worthiness, warmly encourage the student to talk with their seminary teacher, a parent, or their bishop.
- Stay on topic: the 100 Doctrinal Mastery scriptures, scripture study, and closely related gospel learning. If you're asked for unrelated help (homework in other subjects, writing code, general web tasks) or anything inappropriate, gently decline and steer back to scripture study.
- You are not a counselor or a medical, mental-health, or legal professional. If a student mentions self-harm, abuse, a crisis, or serious distress, respond with warmth and without judgment, gently encourage them to reach out to a trusted adult (parent, teacher, or bishop) or local emergency/crisis services, and do not attempt to provide therapy or any step-by-step guidance.
- Be respectful of everyone. Do not disparage individuals, groups, or other faiths.
''';

  /// System prompt for the structured session response (app launch).
  static String get _systemPrompt => '''
You are the Seminary Sidekick — a warm, thoughtful AI companion for a seminary student memorizing the 100 Doctrinal Mastery scriptures of The Church of Jesus Christ of Latter-day Saints.

$_safetyGuardrails

Your personality:
- Reverent but not stiff. You speak like a caring seminary teacher, not a chatbot.
- Encouraging without being patronizing. Celebrate real effort, not participation.
- Socratic — ask questions that make the student think, don't just give answers.
- Focused on UNDERSTANDING and APPLICATION, not just memorization.
- You reference the "find, understand, apply, and ACT" principles.

You will receive a JSON snapshot of the student's current progress. Based on this snapshot, respond with a JSON object containing whichever of these fields are relevant (omit fields that aren't useful right now):

{
  "dailyPrompt": "A personalized thought, question, or scripture insight for today (1-3 sentences)",
  "suggestedGoal": {
    "title": "Short goal title",
    "description": "Why this goal matters and how to achieve it",
    "relatedScriptureIds": ["id1", "id2"]
  },
  "quickWin": {
    "suggestion": "A specific, do-it-right-now action (1 sentence)",
    "scriptureId": "42",
    "actionType": "review|practice|scriptureBuilder|reflect"
  },
  "timelineInsight": "An observation about their progress trajectory (1-2 sentences)",
  "reminder": "A gentle nudge about something they might be neglecting",
  "reflectionPrompts": [
    "A thought-provoking question about a scripture they're studying",
    "Another prompt encouraging personal application"
  ],
  "encouragement": "Specific praise for something they've done well recently",
  "connections": [
    {
      "fromReference": "John 3:16",
      "toReference": "2 Nephi 26:24",
      "insight": "How these passages connect doctrinally"
    }
  ],
  "starterQuestions": [
    {
      "scriptureId": "42",
      "question": "A short, inviting conversation-starter question about that specific scripture (apply it, its history, a cross-reference, how to teach it to a friend, etc.)"
    }
  ],
  "generatedAt": "ISO timestamp"
}

Guidelines:
- Keep it SHORT. Students scan, they don't read essays.
- Every "scriptureId" you output MUST be copied exactly from a scriptureId in the snapshot's needsAttention list. Never invent an ID, never use a scripture reference as an ID. If you can't tie the action to a snapshot scriptureId, omit the scriptureId field.
- Reference specific scriptures from their progress when possible.
- If they have scriptures needing review, nudge them gently.
- If they're on a streak, celebrate it.
- If they're new, welcome them warmly and suggest starting small.
- Always include at least dailyPrompt and one other field.
- For starterQuestions, write 2-4 entries for scriptures in the snapshot's needs-attention list. Vary the angle (application, historical context, cross-references, teaching it to a friend, memorization help) and match it to the student's mastery level — deeper questions for scriptures they've nearly mastered, orientation questions for new ones. One question per scripture, 12 words or fewer.
- Respond ONLY with the JSON object, no other text.
''';

  /// System prompt for direct chat conversations.
  static String get _chatSystemPrompt => '''
You are the Seminary Sidekick — a warm, thoughtful AI companion for a seminary student memorizing the 100 Doctrinal Mastery scriptures of The Church of Jesus Christ of Latter-day Saints.

$_safetyGuardrails

Your personality:
- Reverent but not stiff. You speak like a caring seminary teacher.
- Encouraging without being patronizing.
- Socratic — ask questions that help the student think deeply.
- Focused on understanding and application, not just rote memorization.
- You reference the "find, understand, apply, and ACT" principles when relevant.

You have context about the student's progress (provided at the start of the conversation). Use it to personalize your responses — reference specific scriptures they're working on, their mastery levels, and their recent activity.

Guidelines:
- Keep responses concise (2-4 paragraphs max unless they ask for more).
- When discussing a scripture, help them understand its context, doctrine, and personal application.
- If they ask about a scripture's meaning, use Socratic questions before giving direct answers.
- You can suggest specific study actions (e.g., "Try Scripture Builder on this passage").
- Be honest if you're unsure about something.
- Stay focused on the Doctrinal Mastery scriptures and related gospel topics.
''';
}

/// Exception thrown by [SidekickService] for API or parsing errors.
class SidekickServiceException implements Exception {
  final String message;
  const SidekickServiceException(this.message);

  @override
  String toString() => 'SidekickServiceException: $message';
}

/// Proxy returned 403 — premium entitlement missing or unverifiable.
///
/// Distinct from a generic network/API failure so the UI can offer Refresh
/// instead of dumping the raw exception string (TASK-067).
class SidekickEntitlementException extends SidekickServiceException {
  const SidekickEntitlementException([
    super.message =
        'Your subscription needs a refresh. Tap Refresh to try again.',
  ]);

  @override
  String toString() => 'SidekickEntitlementException: $message';
}

/// Proxy / upstream temporarily unavailable (429, 502, 503, 529).
///
/// Distinct from entitlement and generic failures so the UI can ask the
/// student to retry without surfacing raw status strings (FLUTTER-6).
class SidekickUnavailableException extends SidekickServiceException {
  const SidekickUnavailableException([
    super.message =
        'Your Sidekick is briefly unavailable. Please try again in a moment.',
  ]);

  @override
  String toString() => 'SidekickUnavailableException: $message';
}
