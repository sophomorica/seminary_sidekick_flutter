import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sidekick_response.dart';
import '../models/sidekick_snapshot.dart';

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

  /// Send a direct chat message to the Sidekick with conversation history.
  ///
  /// [history] contains previous messages (role: user/assistant).
  /// [snapshot] provides context about the user's current state.
  /// [userMessage] is the new message from the user.
  ///
  /// Returns the assistant's reply as a plain string.
  Future<String> chat({
    required SidekickSnapshot snapshot,
    required List<SidekickMessage> history,
    required String userMessage,
  }) async {
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': _chatSystemPrompt},
      {
        'role': 'user',
        'content': 'Context — my current progress:\n'
            '```json\n${jsonEncode(snapshot.toJson())}\n```\n\n'
            'Please keep this context in mind but respond conversationally.',
      },
      {'role': 'assistant', 'content': 'Got it — I have your progress context. How can I help?'},
      // Include recent chat history
      ...history.take(20).map((m) => m.toApiMessage()),
      // New user message
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

    try {
      final res = await client.functions.invoke(
        _proxyFunction,
        body: {
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 1500,
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
    } on FunctionException catch (e) {
      throw SidekickServiceException(
        'Sidekick request failed (status ${e.status}): ${e.details}',
      );
    }
  }

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
  "generatedAt": "ISO timestamp"
}

Guidelines:
- Keep it SHORT. Students scan, they don't read essays.
- Reference specific scriptures from their progress when possible.
- If they have scriptures needing review, nudge them gently.
- If they're on a streak, celebrate it.
- If they're new, welcome them warmly and suggest starting small.
- Always include at least dailyPrompt and one other field.
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
