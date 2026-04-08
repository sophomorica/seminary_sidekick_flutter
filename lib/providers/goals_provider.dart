import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/sidekick_response.dart';
import '../providers/scripture_mastery_provider.dart';
import '../providers/sidekick_provider.dart';
import '../providers/subscription_provider.dart';

// ─── Goal Model ─────────────────────────────────────────────────────────────

/// A user goal — either AI-suggested or manually created.
class Goal {
  final String id;
  final String title;
  final String description;

  /// Scripture IDs this goal relates to.
  final List<String> relatedScriptureIds;

  /// Whether this was suggested by the Sidekick AI.
  final bool isSidekickSuggestion;

  /// Whether the user has accepted/pinned this goal.
  final bool isAccepted;

  /// Whether this goal has been completed.
  final bool isCompleted;

  /// When this goal was created.
  final DateTime createdAt;

  /// When this goal was completed, if applicable.
  final DateTime? completedAt;

  const Goal({
    required this.id,
    required this.title,
    required this.description,
    this.relatedScriptureIds = const [],
    this.isSidekickSuggestion = false,
    this.isAccepted = false,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
  });

  Goal copyWith({
    String? title,
    String? description,
    List<String>? relatedScriptureIds,
    bool? isAccepted,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return Goal(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      relatedScriptureIds: relatedScriptureIds ?? this.relatedScriptureIds,
      isSidekickSuggestion: isSidekickSuggestion,
      isAccepted: isAccepted ?? this.isAccepted,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'relatedScriptureIds': relatedScriptureIds,
        'isSidekickSuggestion': isSidekickSuggestion,
        'isAccepted': isAccepted,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      };

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      relatedScriptureIds: (json['relatedScriptureIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isSidekickSuggestion: json['isSidekickSuggestion'] as bool? ?? false,
      isAccepted: json['isAccepted'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  /// Create a Goal from a SidekickGoal (AI suggestion).
  factory Goal.fromSidekickGoal(SidekickGoal sidekickGoal) {
    return Goal(
      id: 'sidekick_${DateTime.now().millisecondsSinceEpoch}',
      title: sidekickGoal.title,
      description: sidekickGoal.description,
      relatedScriptureIds: sidekickGoal.relatedScriptureIds,
      isSidekickSuggestion: true,
      isAccepted: false,
      isCompleted: false,
      createdAt: DateTime.now(),
    );
  }
}

// ─── State ──────────────────────────────────────────────────────────────────

class GoalsState {
  /// All goals (active + completed).
  final List<Goal> goals;

  /// The latest AI-suggested goal that hasn't been accepted or dismissed yet.
  final Goal? pendingSuggestion;

  /// A timeline insight from the Sidekick (e.g., "At your current pace,
  /// you'll master all Book of Mormon passages by June").
  final String? timelineInsight;

  /// A gentle reminder from the Sidekick.
  final String? reminder;

  /// Whether the reminder has been dismissed for this session.
  final bool reminderDismissed;

  const GoalsState({
    this.goals = const [],
    this.pendingSuggestion,
    this.timelineInsight,
    this.reminder,
    this.reminderDismissed = false,
  });

  /// Active (accepted, not completed) goals.
  List<Goal> get activeGoals =>
      goals.where((g) => g.isAccepted && !g.isCompleted).toList();

  /// Completed goals, most recent first.
  List<Goal> get completedGoals {
    final completed = goals.where((g) => g.isCompleted).toList();
    completed.sort((a, b) =>
        (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));
    return completed;
  }

  GoalsState copyWith({
    List<Goal>? goals,
    Goal? pendingSuggestion,
    String? timelineInsight,
    String? reminder,
    bool? reminderDismissed,
    bool clearPendingSuggestion = false,
    bool clearReminder = false,
    bool clearTimeline = false,
  }) {
    return GoalsState(
      goals: goals ?? this.goals,
      pendingSuggestion: clearPendingSuggestion
          ? null
          : (pendingSuggestion ?? this.pendingSuggestion),
      timelineInsight:
          clearTimeline ? null : (timelineInsight ?? this.timelineInsight),
      reminder: clearReminder ? null : (reminder ?? this.reminder),
      reminderDismissed: reminderDismissed ?? this.reminderDismissed,
    );
  }
}

// ─── Notifier ───────────────────────────────────────────────────────────────

class GoalsNotifier extends StateNotifier<GoalsState> {
  final Ref _ref;

  static const String _boxName = 'goals';
  static const String _goalsKey = 'user_goals';
  static const String _lastSuggestionKey = 'last_suggestion_date';

  GoalsNotifier(this._ref) : super(const GoalsState());

  /// Initialize: load persisted goals, then sync with Sidekick if premium.
  Future<void> init() async {
    await _loadFromHive();
    _syncWithSidekick();
  }

  /// Sync goals, timeline, and reminders from the latest Sidekick response.
  void _syncWithSidekick() {
    final isPremium = _ref.read(isPremiumProvider);
    if (!isPremium) return;

    final response = _ref.read(sidekickResponseProvider);
    if (response == null) return;

    // Timeline insight
    final timelineInsight = response.timelineInsight;

    // Reminder
    final reminder = response.reminder;

    // Suggested goal — only if we haven't suggested one today
    Goal? pendingSuggestion;
    if (response.suggestedGoal != null) {
      final lastSuggestionDate = _getLastSuggestionDate();
      final today = DateTime.now();
      final isNewDay = lastSuggestionDate == null ||
          lastSuggestionDate.day != today.day ||
          lastSuggestionDate.month != today.month ||
          lastSuggestionDate.year != today.year;

      if (isNewDay) {
        // Check if we already have an identical pending/active goal
        final existingTitles =
            state.goals.where((g) => !g.isCompleted).map((g) => g.title).toSet();
        if (!existingTitles.contains(response.suggestedGoal!.title)) {
          pendingSuggestion = Goal.fromSidekickGoal(response.suggestedGoal!);
          _recordSuggestionDate();
        }
      }
    }

    state = state.copyWith(
      timelineInsight: timelineInsight,
      reminder: reminder,
      pendingSuggestion: pendingSuggestion,
      reminderDismissed: false,
    );
  }

  /// Refresh from Sidekick (e.g., after a new session response comes in).
  void refreshFromSidekick() {
    _syncWithSidekick();
  }

  // ─── Goal CRUD ──────────────────────────────────────────────────────────

  /// Add a custom user goal.
  void addGoal({
    required String title,
    String description = '',
    List<String> relatedScriptureIds = const [],
  }) {
    final goal = Goal(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      relatedScriptureIds: relatedScriptureIds,
      isSidekickSuggestion: false,
      isAccepted: true,
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(goals: [...state.goals, goal]);
    _persist();
  }

  /// Accept the pending Sidekick suggestion (moves it to active goals).
  void acceptSuggestion() {
    final suggestion = state.pendingSuggestion;
    if (suggestion == null) return;

    final accepted = suggestion.copyWith(isAccepted: true);
    state = state.copyWith(
      goals: [...state.goals, accepted],
      clearPendingSuggestion: true,
    );
    _persist();
  }

  /// Dismiss the pending Sidekick suggestion.
  void dismissSuggestion() {
    state = state.copyWith(clearPendingSuggestion: true);
  }

  /// Mark a goal as completed.
  void completeGoal(String goalId) {
    final updated = state.goals.map((g) {
      if (g.id == goalId) {
        return g.copyWith(isCompleted: true, completedAt: DateTime.now());
      }
      return g;
    }).toList();

    state = state.copyWith(goals: updated);
    _persist();
  }

  /// Remove a goal entirely.
  void removeGoal(String goalId) {
    state = state.copyWith(
      goals: state.goals.where((g) => g.id != goalId).toList(),
    );
    _persist();
  }

  /// Dismiss the reminder for this session.
  void dismissReminder() {
    state = state.copyWith(reminderDismissed: true);
  }

  // ─── Persistence ────────────────────────────────────────────────────────

  Future<void> _loadFromHive() async {
    try {
      final box = await Hive.openBox(_boxName);
      final goalsJson = box.get(_goalsKey) as String?;
      if (goalsJson != null) {
        final list = jsonDecode(goalsJson) as List<dynamic>;
        final goals = list
            .map((g) => Goal.fromJson(g as Map<String, dynamic>))
            .toList();
        state = state.copyWith(goals: goals);
      }
    } catch (_) {
      // Non-fatal
    }
  }

  Future<void> _persist() async {
    try {
      final box = Hive.box(_boxName);
      final jsonList = state.goals.map((g) => g.toJson()).toList();
      await box.put(_goalsKey, jsonEncode(jsonList));
    } catch (_) {
      // Non-fatal
    }
  }

  DateTime? _getLastSuggestionDate() {
    try {
      final box = Hive.box(_boxName);
      final ms = box.get(_lastSuggestionKey) as int?;
      return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
    } catch (_) {
      return null;
    }
  }

  void _recordSuggestionDate() {
    try {
      final box = Hive.box(_boxName);
      box.put(_lastSuggestionKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {
      // Non-fatal
    }
  }
}

// ─── Providers ──────────────────────────────────────────────────────────────

final goalsProvider = StateNotifierProvider<GoalsNotifier, GoalsState>(
  (ref) => GoalsNotifier(ref),
);

/// Active (accepted, not completed) goals.
final activeGoalsProvider = Provider<List<Goal>>((ref) {
  return ref.watch(goalsProvider).activeGoals;
});

/// Completed goals.
final completedGoalsProvider = Provider<List<Goal>>((ref) {
  return ref.watch(goalsProvider).completedGoals;
});

/// The pending AI suggestion, if any.
final pendingSuggestionProvider = Provider<Goal?>((ref) {
  return ref.watch(goalsProvider).pendingSuggestion;
});

/// Timeline insight string from the Sidekick.
final timelineInsightProvider = Provider<String?>((ref) {
  return ref.watch(goalsProvider).timelineInsight;
});

/// Gentle reminder from the Sidekick (null if dismissed).
final activeReminderProvider = Provider<String?>((ref) {
  final goalsState = ref.watch(goalsProvider);
  if (goalsState.reminderDismissed) return null;
  return goalsState.reminder;
});

/// Computed mastery timeline projection based on current pace.
/// Returns a human-readable projection string.
final masteryProjectionProvider = Provider<String?>((ref) {
  final stats = ref.watch(holisticStatsProvider);

  // Need at least a few scriptures attempted to project
  if (stats.attempted < 3) return null;

  final masteredTotal = stats.mastered + stats.eternal;
  final remaining = stats.totalScriptures - masteredTotal;

  if (remaining <= 0) {
    return 'You\'ve mastered all ${stats.totalScriptures} scriptures!';
  }

  // Simple projection: if the AI provides a timeline insight, prefer that.
  // Otherwise compute a rough local estimate.
  final aiInsight = ref.watch(timelineInsightProvider);
  if (aiInsight != null && aiInsight.isNotEmpty) {
    return aiInsight;
  }

  // Rough local estimate: based on how many are memorized+ vs total attempted
  final progressRate = stats.attempted > 0
      ? masteredTotal / stats.attempted
      : 0.0;

  if (progressRate > 0 && masteredTotal > 0) {
    final weeksPerScripture = 2.0 / progressRate; // rough estimate
    final weeksRemaining = (remaining * weeksPerScripture).round();
    if (weeksRemaining <= 4) {
      return '$remaining more to go — you could finish this month!';
    } else if (weeksRemaining <= 12) {
      final months = (weeksRemaining / 4.3).ceil();
      return '$remaining to go — roughly $months month${months == 1 ? '' : 's'} at your pace.';
    } else {
      return '$remaining scriptures remaining. Keep your streak going!';
    }
  }

  return '$remaining scriptures left to master. You\'ve got this!';
});

/// Goal title strings for inclusion in the Sidekick snapshot.
final goalTitlesForSnapshotProvider = Provider<List<String>>((ref) {
  final activeGoals = ref.watch(activeGoalsProvider);
  return activeGoals.map((g) => g.title).toList();
});
