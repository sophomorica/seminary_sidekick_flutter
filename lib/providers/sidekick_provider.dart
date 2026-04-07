import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/sidekick_response.dart';
import '../models/sidekick_snapshot.dart';
import '../providers/activity_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/scripture_mastery_provider.dart';
import '../providers/spaced_repetition_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/sidekick_service.dart';

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

  /// The snapshot that was last sent (for chat context reuse).
  final SidekickSnapshot? lastSnapshot;

  const SidekickState({
    this.sessionResponse,
    this.chatHistory = const [],
    this.isLoadingSession = false,
    this.isLoadingChat = false,
    this.error,
    this.lastSnapshot,
  });

  SidekickState copyWith({
    SidekickResponse? sessionResponse,
    List<SidekickMessage>? chatHistory,
    bool? isLoadingSession,
    bool? isLoadingChat,
    String? error,
    SidekickSnapshot? lastSnapshot,
    bool clearError = false,
    bool clearResponse = false,
  }) {
    return SidekickState(
      sessionResponse:
          clearResponse ? null : (sessionResponse ?? this.sessionResponse),
      chatHistory: chatHistory ?? this.chatHistory,
      isLoadingSession: isLoadingSession ?? this.isLoadingSession,
      isLoadingChat: isLoadingChat ?? this.isLoadingChat,
      error: clearError ? null : (error ?? this.error),
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

  SidekickNotifier(this._ref) : super(const SidekickState());

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

      final response = await _service.getSessionResponse(snapshot);

      state = state.copyWith(
        sessionResponse: response,
        isLoadingSession: false,
      );

      await _cacheResponse(response);
    } catch (e) {
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

    // Add user message to history
    final userMsg = SidekickMessage(
      role: 'user',
      content: userMessage.trim(),
      timestamp: DateTime.now(),
    );
    final updatedHistory = [...state.chatHistory, userMsg];
    state = state.copyWith(
      chatHistory: updatedHistory,
      isLoadingChat: true,
      clearError: true,
    );

    try {
      // Build a fresh snapshot for context
      final snapshot = state.lastSnapshot ?? _buildSnapshot();

      final reply = await _service.chat(
        snapshot: snapshot,
        history: updatedHistory,
        userMessage: userMessage.trim(),
      );

      final assistantMsg = SidekickMessage(
        role: 'assistant',
        content: reply,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        chatHistory: [...updatedHistory, assistantMsg],
        isLoadingChat: false,
      );

      await _cacheChatHistory();
    } catch (e) {
      state = state.copyWith(
        isLoadingChat: false,
        error: 'Could not send message. Check your connection.',
      );
    }
  }

  /// Clear chat history.
  void clearChat() {
    state = state.copyWith(chatHistory: []);
    _cacheChatHistory();
  }

  /// Clear error state.
  void clearError() {
    state = state.copyWith(clearError: true);
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
    for (final scripture in dueScriptures.take(8)) {
      final mastery = _ref.read(scriptureMasteryProvider(scripture.id));
      final daysSince = mastery.lastPracticedAny != null
          ? DateTime.now().difference(mastery.lastPracticedAny!).inDays
          : 999;

      needsAttention.add(ScriptureProgressSummary(
        scriptureId: scripture.id,
        reference: scripture.reference,
        topic: scripture.name,
        masteryLevel: mastery.level.label,
        accuracy: mastery.overallAccuracy,
        needsReview: mastery.needsReview,
        daysSinceLastPractice: daysSince,
      ));
    }

    // Build recent activity summaries (human-readable strings)
    final recentActivity = activities.take(10).map((a) {
      final meta = a.metadata;
      switch (a.type.name) {
        case 'gameCompleted':
          return '${a.scriptureReference}: ${meta['gameType'] ?? 'game'} '
              '${meta['difficulty'] ?? ''} — score ${meta['score'] ?? '?'}';
        case 'masteryLevelUp':
          return '${a.scriptureReference}: leveled up to ${meta['newLevel'] ?? '?'}';
        case 'perfectRun':
          return '${a.scriptureReference}: perfect run on ${meta['difficulty'] ?? '?'}';
        case 'streakMilestone':
          return 'Streak milestone: ${meta['streakCount'] ?? '?'} in a row';
        case 'firstAttempt':
          return '${a.scriptureReference}: first attempt!';
        default:
          return '${a.scriptureReference}: ${a.type.displayName}';
      }
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
      daysActive: _estimateDaysActive(activities.isNotEmpty
          ? activities.last.timestamp
          : now),
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
        state = state.copyWith(
          sessionResponse: SidekickResponse.fromJson(parsed),
        );
      }

      // Load cached chat history
      final chatJson = box.get(_chatHistoryKey) as String?;
      if (chatJson != null) {
        final chatList = jsonDecode(chatJson) as List<dynamic>;
        final messages = chatList
            .map((m) =>
                SidekickMessage.fromJson(m as Map<String, dynamic>))
            .toList();
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
      final box = Hive.box(_cacheBoxName);
      final jsonList = state.chatHistory.map((m) => m.toJson()).toList();
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

final sidekickProvider =
    StateNotifierProvider<SidekickNotifier, SidekickState>(
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

/// Convenience: chat messages.
final chatHistoryProvider = Provider<List<SidekickMessage>>((ref) {
  return ref.watch(sidekickProvider).chatHistory;
});

/// Convenience: is the chat currently waiting for a reply?
final isChatLoadingProvider = Provider<bool>((ref) {
  return ref.watch(sidekickProvider).isLoadingChat;
});
