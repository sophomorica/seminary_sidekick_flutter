import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/enums.dart';
import '../models/sidekick_response.dart';
import '../models/sidekick_snapshot.dart';
import '../providers/activity_provider.dart';
import '../providers/goals_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/scripture_mastery_provider.dart';
import '../providers/scripture_provider.dart';
import '../providers/spaced_repetition_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/sidekick_service.dart';
import '../utils/scripture_reference_resolver.dart';

// ─── Chat history helpers (TASK-068) ────────────────────────────────────────

/// Keeps only the most recent [max] messages (rolling storage cap).
List<SidekickMessage> trimChatHistory(
  List<SidekickMessage> history, {
  int max = SidekickNotifier.maxStoredMessages,
}) {
  if (history.length <= max) return List<SidekickMessage>.of(history);
  return history.sublist(history.length - max);
}

// ─── State ──────────────────────────────────────────────────────────────────

/// State for the Seminary Sidekick AI orchestration layer.
class SidekickState {
  /// Latest structured response from the Sidekick (app launch).
  final SidekickResponse? sessionResponse;

  /// Chat message history.
  final List<SidekickMessage> chatHistory;

  /// Whether a session request is in flight.
  final bool isLoadingSession;

  /// Whether a chat message is in flight.
  final bool isLoadingChat;

  /// Last error, if any.
  final String? error;

  /// True when [error] is from a sidekick-proxy entitlement 403 (TASK-067).
  final bool isEntitlementError;

  /// Message to put back in the chat input after a failed send (403 / retry).
  final String? pendingRetryMessage;

  /// The snapshot that was last sent (for chat context reuse).
  final SidekickSnapshot? lastSnapshot;

  const SidekickState({
    this.sessionResponse,
    this.chatHistory = const [],
    this.isLoadingSession = false,
    this.isLoadingChat = false,
    this.error,
    this.isEntitlementError = false,
    this.pendingRetryMessage,
    this.lastSnapshot,
  });

  SidekickState copyWith({
    SidekickResponse? sessionResponse,
    List<SidekickMessage>? chatHistory,
    bool? isLoadingSession,
    bool? isLoadingChat,
    String? error,
    bool? isEntitlementError,
    String? pendingRetryMessage,
    SidekickSnapshot? lastSnapshot,
    bool clearError = false,
    bool clearResponse = false,
    bool clearPendingRetry = false,
  }) {
    return SidekickState(
      sessionResponse:
          clearResponse ? null : (sessionResponse ?? this.sessionResponse),
      chatHistory: chatHistory ?? this.chatHistory,
      isLoadingSession: isLoadingSession ?? this.isLoadingSession,
      isLoadingChat: isLoadingChat ?? this.isLoadingChat,
      error: clearError ? null : (error ?? this.error),
      isEntitlementError:
          clearError ? false : (isEntitlementError ?? this.isEntitlementError),
      pendingRetryMessage: clearPendingRetry
          ? null
          : (pendingRetryMessage ?? this.pendingRetryMessage),
      lastSnapshot: lastSnapshot ?? this.lastSnapshot,
    );
  }
}

// ─── Notifier ───────────────────────────────────────────────────────────────

/// Orchestrates the Seminary Sidekick AI:
/// - Builds snapshots from the user's current state
/// - Sends them to the Grok API via [SidekickService]
/// - Caches responses for offline fallback
/// - Manages chat history
class SidekickNotifier extends StateNotifier<SidekickState> {
  final Ref _ref;
  final SidekickService _service = SidekickService();

  static const String _cacheBoxName = 'sidekick_cache';
  static const String _responseCacheKey = 'last_session_response';
  static const String _chatHistoryKey = 'chat_history';

  /// Rolling cap for persisted + in-memory chat history. Tunable.
  static const int maxStoredMessages = 50;

  SidekickNotifier(this._ref) : super(const SidekickState());

  /// The real scripture IDs ('1'..'100'). AI-supplied IDs are validated
  /// against this set before they can reach navigation — Grok occasionally
  /// hallucinates IDs, which used to dead-end on "Scripture not found".
  Set<String> get _validScriptureIds =>
      _ref.read(scripturesProvider).map((s) => s.id).toSet();

  /// Initialize: load cached data, then trigger a session refresh if premium.
  Future<void> init() async {
    await _loadCache();

    // Auto-refresh on launch if premium
    final isPremium = _ref.read(isPremiumProvider);
    if (isPremium) {
      await refreshSession();
    }
  }

  /// Build a snapshot and send it to the Sidekick for a fresh session response.
  Future<void> refreshSession() async {
    if (state.isLoadingSession) return;

    state = state.copyWith(isLoadingSession: true, clearError: true);

    try {
      final snapshot = _buildSnapshot();
      state = state.copyWith(lastSnapshot: snapshot);

      final response = (await _service.getSessionResponse(snapshot)).sanitized(
        _validScriptureIds,
        resolveIdFromText: findScriptureIdInText,
      );

      state = state.copyWith(
        sessionResponse: response,
        isLoadingSession: false,
      );

      await _cacheResponse(response);
    } on SidekickEntitlementException catch (e, stack) {
      developer.log(
        'Sidekick session refresh blocked by entitlement gate',
        name: 'sidekick',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(
        isLoadingSession: false,
        error: e.message,
        isEntitlementError: true,
      );
      if (state.sessionResponse == null) {
        state = state.copyWith(
          sessionResponse: SidekickResponse.offlineFallback(),
        );
      }
    } on SidekickUnavailableException catch (e, stack) {
      developer.log(
        'Sidekick session refresh blocked by transient upstream',
        name: 'sidekick',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(
        isLoadingSession: false,
        error: e.message,
      );
      if (state.sessionResponse == null) {
        state = state.copyWith(
          sessionResponse: SidekickResponse.offlineFallback(),
        );
      }
    } catch (e, stack) {
      developer.log(
        'Sidekick session refresh failed',
        name: 'sidekick',
        error: e,
        stackTrace: stack,
      );
      // On failure, keep cached response and set error
      state = state.copyWith(
        isLoadingSession: false,
        error: 'Could not reach your Sidekick. Using cached insights.',
      );

      // If we have no response at all, use offline fallback
      if (state.sessionResponse == null) {
        state = state.copyWith(
          sessionResponse: SidekickResponse.offlineFallback(),
        );
      }
    }
  }

  /// Send a chat message to the Sidekick and get a reply.
  Future<void> sendMessage(String userMessage) async {
    if (state.isLoadingChat || userMessage.trim().isEmpty) return;

    final trimmed = userMessage.trim();

    // Prior turns only — the service appends [trimmed] once. Passing the
    // optimistic history (which already includes the new user bubble) would
    // duplicate the newest message in the API payload.
    final priorHistory = List<SidekickMessage>.of(state.chatHistory);

    // Add user message to history
    final userMsg = SidekickMessage(
      role: 'user',
      content: trimmed,
      timestamp: DateTime.now(),
    );
    final updatedHistory = trimChatHistory([...priorHistory, userMsg]);
    state = state.copyWith(
      chatHistory: updatedHistory,
      isLoadingChat: true,
      clearError: true,
      clearPendingRetry: true,
    );

    try {
      // Build a fresh snapshot for context
      final snapshot = state.lastSnapshot ?? _buildSnapshot();

      final reply = await _service.chat(
        snapshot: snapshot,
        history: priorHistory,
        userMessage: trimmed,
      );

      final assistantMsg = SidekickMessage(
        role: 'assistant',
        content: reply,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        chatHistory: trimChatHistory([...updatedHistory, assistantMsg]),
        isLoadingChat: false,
      );

      await _cacheChatHistory();
    } on SidekickEntitlementException catch (e, stack) {
      developer.log(
        'Sidekick chat blocked by entitlement gate',
        name: 'sidekick',
        error: e,
        stackTrace: stack,
      );
      // Pull the optimistic user bubble back out and keep the text for retry.
      final withoutFailedSend = List<SidekickMessage>.of(updatedHistory)
        ..removeLast();
      state = state.copyWith(
        chatHistory: withoutFailedSend,
        isLoadingChat: false,
        error: e.message,
        isEntitlementError: true,
        pendingRetryMessage: trimmed,
      );
      await _cacheChatHistory();
    } on SidekickUnavailableException catch (e, stack) {
      developer.log(
        'Sidekick chat blocked by transient upstream',
        name: 'sidekick',
        error: e,
        stackTrace: stack,
      );
      // Keep the typed text retryable — same UX path as entitlement, without
      // the Refresh action (generic banner dismiss / re-send).
      final withoutFailedSend = List<SidekickMessage>.of(updatedHistory)
        ..removeLast();
      state = state.copyWith(
        chatHistory: withoutFailedSend,
        isLoadingChat: false,
        error: e.message,
        pendingRetryMessage: trimmed,
      );
      await _cacheChatHistory();
    } catch (e, stack) {
      developer.log(
        'Sidekick chat failed',
        name: 'sidekick',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(
        isLoadingChat: false,
        error: 'Could not send message. Please try again.',
      );
    }
  }

  /// Clear chat history.
  void clearChat() {
    state = state.copyWith(chatHistory: [], clearPendingRetry: true);
    _cacheChatHistory();
  }

  /// Clear error state (keeps [pendingRetryMessage] so the input can retain it).
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Clear a pending retry after the UI has restored it to the input (or sent).
  void clearPendingRetry() {
    state = state.copyWith(clearPendingRetry: true);
  }

  // ─── Snapshot Builder ───────────────────────────────────────────────────

  /// Build a [SidekickSnapshot] from the current app state.
  SidekickSnapshot _buildSnapshot() {
    final stats = _ref.read(holisticStatsProvider);
    final activities = _ref.read(activityProvider);
    final dueScriptures = _ref.read(dueScripturesProvider);
    final userStats = _ref.read(userStatsProvider);

    // Build "needs attention" list: due scriptures + decaying ones
    final needsAttention = <ScriptureProgressSummary>[];
    final attentionIds = <String>{};

    ScriptureProgressSummary summarize(
        String id, String reference, String topic) {
      final mastery = _ref.read(scriptureMasteryProvider(id));
      final daysSince = mastery.lastPracticedAny != null
          ? DateTime.now().difference(mastery.lastPracticedAny!).inDays
          : 999;
      return ScriptureProgressSummary(
        scriptureId: id,
        reference: reference,
        topic: topic,
        masteryLevel: mastery.level.label,
        accuracy: mastery.overallAccuracy,
        needsReview: mastery.needsReview,
        daysSinceLastPractice: daysSince,
      );
    }

    for (final scripture in dueScriptures.take(8)) {
      if (attentionIds.add(scripture.id)) {
        needsAttention.add(
          summarize(scripture.id, scripture.reference, scripture.name),
        );
      }
    }

    // Also include recently practiced scriptures so the Sidekick has valid
    // IDs for "build on your recent quiz"-style suggestions, not just the
    // SR-due subset.
    for (final a in activities) {
      if (needsAttention.length >= 12) break;
      if (a.scriptureId.isEmpty || !attentionIds.add(a.scriptureId)) continue;
      final scripture = _ref.read(scriptureByIdProvider(a.scriptureId));
      if (scripture == null) continue;
      needsAttention.add(
        summarize(scripture.id, scripture.reference, scripture.name),
      );
    }

    // Build recent activity summaries (structured, with scripture IDs)
    final recentActivity = activities.take(10).map((a) {
      final meta = a.metadata;
      final String summary;
      switch (a.type.name) {
        case 'gameCompleted':
          summary = '${a.scriptureReference}: ${meta['gameType'] ?? 'game'} '
              '${meta['difficulty'] ?? ''} — score ${meta['score'] ?? '?'}';
        case 'masteryLevelUp':
          summary =
              '${a.scriptureReference}: leveled up to ${meta['newLevel'] ?? '?'}';
        case 'perfectRun':
          summary =
              '${a.scriptureReference}: perfect run on ${meta['difficulty'] ?? '?'}';
        case 'streakMilestone':
          summary = 'Streak milestone: ${meta['streakCount'] ?? '?'} in a row';
        case 'firstAttempt':
          summary = '${a.scriptureReference}: first attempt!';
        default:
          summary = '${a.scriptureReference}: ${a.type.displayName}';
      }
      return ActivitySummary(
        scriptureId: a.scriptureId,
        reference: a.scriptureReference,
        summary: summary,
      );
    }).toList();

    // Estimate seminary curriculum week (Sept start, 36 weeks)
    final now = DateTime.now();
    final seminaryStart = DateTime(
      now.month >= 9 ? now.year : now.year - 1,
      9,
      1,
    );
    final weeksSinceStart = now.difference(seminaryStart).inDays ~/ 7;
    final curriculumWeek = (weeksSinceStart % 36) + 1;

    // Include active goal titles so the Sidekick knows what the user is working on
    final goalTitles = _ref.read(goalTitlesForSnapshotProvider);

    return SidekickSnapshot(
      masteryStats: MasteryStats(
        total: stats.totalScriptures,
        eternal: stats.eternal,
        mastered: stats.mastered,
        memorized: stats.memorized,
        familiar: stats.familiar,
        learning: stats.learning,
        notStarted: stats.totalScriptures - stats.attempted,
        needsReview: stats.needsReview,
        overallAccuracy: stats.overallAccuracy,
      ),
      needsAttention: needsAttention,
      recentActivity: recentActivity,
      curriculumWeek: curriculumWeek,
      goals: goalTitles,
      daysActive: _estimateDaysActive(
          activities.isNotEmpty ? activities.last.timestamp : now),
      currentStreak: userStats.currentStreak,
      generatedAt: now.toIso8601String(),
    );
  }

  /// Rough estimate of days since first activity.
  int _estimateDaysActive(DateTime earliestActivity) {
    return DateTime.now().difference(earliestActivity).inDays.clamp(0, 9999);
  }

  // ─── Cache ──────────────────────────────────────────────────────────────

  Future<void> _loadCache() async {
    try {
      final box = await Hive.openBox(_cacheBoxName);

      // Load cached session response
      final cachedJson = box.get(_responseCacheKey) as String?;
      if (cachedJson != null) {
        final parsed = jsonDecode(cachedJson) as Map<String, dynamic>;
        // Sanitize cached responses too — a bad ID cached before this
        // validation existed would otherwise keep resurfacing.
        state = state.copyWith(
          sessionResponse: SidekickResponse.fromJson(parsed).sanitized(
            _validScriptureIds,
            resolveIdFromText: findScriptureIdInText,
          ),
        );
      }

      // Load cached chat history (trim in case a prior build stored more)
      final chatJson = box.get(_chatHistoryKey) as String?;
      if (chatJson != null) {
        final chatList = jsonDecode(chatJson) as List<dynamic>;
        final messages = trimChatHistory(
          chatList
              .map((m) => SidekickMessage.fromJson(m as Map<String, dynamic>))
              .toList(),
        );
        state = state.copyWith(chatHistory: messages);
      }
    } catch (_) {
      // Cache load failure is non-fatal
    }
  }

  Future<void> _cacheResponse(SidekickResponse response) async {
    try {
      final box = Hive.box(_cacheBoxName);
      await box.put(_responseCacheKey, jsonEncode(response.toJson()));
    } catch (_) {
      // Cache write failure is non-fatal
    }
  }

  Future<void> _cacheChatHistory() async {
    try {
      final trimmed = trimChatHistory(state.chatHistory);
      if (trimmed.length != state.chatHistory.length) {
        state = state.copyWith(chatHistory: trimmed);
      }
      final box = Hive.box(_cacheBoxName);
      final jsonList = trimmed.map((m) => m.toJson()).toList();
      await box.put(_chatHistoryKey, jsonEncode(jsonList));
    } catch (_) {
      // Cache write failure is non-fatal
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

// ─── Providers ──────────────────────────────────────────────────────────────

final sidekickProvider = StateNotifierProvider<SidekickNotifier, SidekickState>(
  (ref) => SidekickNotifier(ref),
);

/// Convenience: the latest session response (may be cached or offline fallback).
final sidekickResponseProvider = Provider<SidekickResponse?>((ref) {
  return ref.watch(sidekickProvider).sessionResponse;
});

/// Convenience: the daily prompt string, if available.
final dailyPromptProvider = Provider<String?>((ref) {
  return ref.watch(sidekickResponseProvider)?.dailyPrompt;
});

/// Convenience: the quick win suggestion, if available.
final quickWinProvider = Provider<QuickWin?>((ref) {
  return ref.watch(sidekickResponseProvider)?.quickWin;
});

/// Convenience: reflection prompts for the journal.
final reflectionPromptsProvider = Provider<List<String>>((ref) {
  return ref.watch(sidekickResponseProvider)?.reflectionPrompts ?? const [];
});

/// Convenience: AI-generated starter question for a specific scripture, if
/// the current session response included one. Null → caller falls back to
/// local templates.
final starterQuestionForScriptureProvider =
    Provider.family<String?, String>((ref, scriptureId) {
  final questions =
      ref.watch(sidekickResponseProvider)?.starterQuestions ?? const [];
  for (final q in questions) {
    if (q.scriptureId == scriptureId && q.question.isNotEmpty) {
      return q.question;
    }
  }
  return null;
});

/// Convenience: chat messages.
final chatHistoryProvider = Provider<List<SidekickMessage>>((ref) {
  return ref.watch(sidekickProvider).chatHistory;
});

/// Convenience: is the chat currently waiting for a reply?
final isChatLoadingProvider = Provider<bool>((ref) {
  return ref.watch(sidekickProvider).isLoadingChat;
});

// ─── Engagement Enhancements (TASK-040) ──────────────────────────────────────

/// Convenience: the encouragement message from the Sidekick, if available.
final encouragementProvider = Provider<String?>((ref) {
  return ref.watch(sidekickResponseProvider)?.encouragement;
});

/// Convenience: scripture connections from the Sidekick.
final connectionsProvider = Provider<List<ScriptureConnection>>((ref) {
  return ref.watch(sidekickResponseProvider)?.connections ?? const [];
});

/// "Next best win" — the quick win from the Sidekick, enhanced with local data.
/// Returns a human-readable action string + the scripture ID to navigate to.
class NextBestWin {
  final String message;
  final String? scriptureId;
  final String? actionType;

  const NextBestWin({
    required this.message,
    this.scriptureId,
    this.actionType,
  });
}

/// Provides the "next best win" for the user — either from AI (quick win) or
/// locally computed from nearly-mastered scriptures.
final nextBestWinProvider = Provider<NextBestWin?>((ref) {
  // First, try the AI quick win
  final quickWin = ref.watch(quickWinProvider);
  if (quickWin != null && quickWin.suggestion.isNotEmpty) {
    return NextBestWin(
      message: quickWin.suggestion,
      scriptureId: quickWin.scriptureId,
      actionType: quickWin.actionType,
    );
  }

  // Fall back to locally computed "nearly mastered" scriptures
  final nearlyMastered = ref.watch(nearlyMasteredScripturesProvider);
  if (nearlyMastered.isNotEmpty) {
    final best = nearlyMastered.first;
    return NextBestWin(
      message:
          '${best.reference} is almost at the next level — one more session could do it!',
      scriptureId: best.id,
      actionType: 'scriptureBuilder',
    );
  }

  return null;
});

/// Scriptures that are close to leveling up (subProgress >= 0.6 and not yet at target).
/// Sorted by closest-to-leveling-up first.
final nearlyMasteredScripturesProvider =
    Provider<List<NearlyMasteredInfo>>((ref) {
  final allScriptures = ref.watch(scripturesProvider);
  final results = <NearlyMasteredInfo>[];

  for (final scripture in allScriptures) {
    final mastery = ref.watch(scriptureMasteryProvider(scripture.id));

    // Only include scriptures that are in-progress (not new, not eternal)
    if (mastery.level == MasteryLevel.newScripture ||
        mastery.level == MasteryLevel.eternal) {
      continue;
    }

    // Consider "nearly leveled" if subProgress >= 0.6
    if (mastery.subProgress >= 0.6) {
      results.add(NearlyMasteredInfo(
        id: scripture.id,
        reference: scripture.reference,
        level: mastery.level,
        subProgress: mastery.subProgress,
        consecutivePerfectMaster: mastery.consecutivePerfectMaster,
      ));
    }
  }

  // Sort by highest subProgress (closest to leveling up)
  results.sort((a, b) => b.subProgress.compareTo(a.subProgress));
  return results;
});

class NearlyMasteredInfo {
  final String id;
  final String reference;
  final MasteryLevel level;
  final double subProgress;
  final int consecutivePerfectMaster;

  const NearlyMasteredInfo({
    required this.id,
    required this.reference,
    required this.level,
    required this.subProgress,
    required this.consecutivePerfectMaster,
  });
}

/// "Got a minute?" quick session prompts for the home screen.
/// Picks the best short action based on the user's state.
class QuickSessionPrompt {
  final String title;
  final String subtitle;
  final String? scriptureId;
  final String actionType; // 'scriptureBuilder', 'review', 'reflect', 'quiz'

  const QuickSessionPrompt({
    required this.title,
    required this.subtitle,
    this.scriptureId,
    required this.actionType,
  });
}

/// Provides 1-3 quick session prompts for "time to kill" moments.
final quickSessionPromptsProvider = Provider<List<QuickSessionPrompt>>((ref) {
  final prompts = <QuickSessionPrompt>[];
  final isPremium = ref.watch(isPremiumProvider);

  // 1. If there's a quick win from the AI, lead with that
  final quickWin = ref.watch(quickWinProvider);
  if (quickWin != null && quickWin.suggestion.isNotEmpty) {
    prompts.add(QuickSessionPrompt(
      title: 'Quick Win',
      subtitle: quickWin.suggestion,
      scriptureId: quickWin.scriptureId,
      actionType: quickWin.actionType ?? 'scriptureBuilder',
    ));
  }

  // 2. Nearly mastered nudge
  final nearlyMastered = ref.watch(nearlyMasteredScripturesProvider);
  if (nearlyMastered.isNotEmpty && prompts.length < 3) {
    final top = nearlyMastered.first;
    final progressPct = (top.subProgress * 100).toInt();
    prompts.add(QuickSessionPrompt(
      title: 'Almost There',
      subtitle:
          '${top.reference} is $progressPct% to ${_nextLevelName(top.level)}',
      scriptureId: top.id,
      actionType: 'scriptureBuilder',
    ));
  }

  // 3. Reflection prompt (premium, ties to journal)
  if (isPremium && prompts.length < 3) {
    final reflections = ref.watch(reflectionPromptsProvider);
    if (reflections.isNotEmpty) {
      prompts.add(QuickSessionPrompt(
        title: 'Reflect',
        subtitle: reflections.first,
        actionType: 'reflect',
      ));
    }
  }

  // 4. Due review if we still have room
  final dueCount = ref.watch(dueCountProvider);
  if (dueCount > 0 && prompts.length < 3) {
    final dueScriptures = ref.watch(dueScripturesProvider);
    if (dueScriptures.isNotEmpty) {
      prompts.add(QuickSessionPrompt(
        title: 'Review',
        subtitle: '${dueScriptures.first.reference} is due for review',
        scriptureId: dueScriptures.first.id,
        actionType: 'review',
      ));
    }
  }

  return prompts;
});

String _nextLevelName(MasteryLevel current) {
  switch (current) {
    case MasteryLevel.newScripture:
      return 'Learning';
    case MasteryLevel.learning:
      return 'Familiar';
    case MasteryLevel.familiar:
      return 'Memorized';
    case MasteryLevel.memorized:
      return 'Mastered';
    case MasteryLevel.mastered:
      return 'Eternal';
    case MasteryLevel.eternal:
      return 'Eternal';
  }
}
