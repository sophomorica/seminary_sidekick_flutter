/// JSON snapshot of the user's current state, sent to the Seminary Sidekick
/// (Grok) on premium app launch.
///
/// The snapshot gives the AI enough context to generate personalized prompts,
/// goals, and encouragement without requiring a database or user account.
/// Keep it lean — only what the Sidekick needs to be helpful.
class SidekickSnapshot {
  /// Mastery counts by level.
  final MasteryStats masteryStats;

  /// Top scriptures needing attention (due for SR review or decaying).
  final List<ScriptureProgressSummary> needsAttention;

  /// Recent activity log (last ~10 entries, human-readable).
  final List<String> recentActivity;

  /// Current seminary curriculum week (1–36, estimated from date).
  final int curriculumWeek;

  /// User's active goals (free-text, managed by TASK-036 later).
  final List<String> goals;

  /// Total days the user has been active (first activity → today).
  final int daysActive;

  /// Current daily streak (consecutive days with at least one attempt).
  final int currentStreak;

  /// ISO timestamp of when this snapshot was created.
  final String generatedAt;

  const SidekickSnapshot({
    required this.masteryStats,
    required this.needsAttention,
    required this.recentActivity,
    required this.curriculumWeek,
    this.goals = const [],
    required this.daysActive,
    required this.currentStreak,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
        'masteryStats': masteryStats.toJson(),
        'needsAttention': needsAttention.map((s) => s.toJson()).toList(),
        'recentActivity': recentActivity,
        'curriculumWeek': curriculumWeek,
        'goals': goals,
        'daysActive': daysActive,
        'currentStreak': currentStreak,
        'generatedAt': generatedAt,
      };
}

/// Aggregate mastery counts across all 100 scriptures.
class MasteryStats {
  final int total;
  final int eternal;
  final int mastered;
  final int memorized;
  final int familiar;
  final int learning;
  final int notStarted;
  final int needsReview;
  final double overallAccuracy;

  const MasteryStats({
    required this.total,
    required this.eternal,
    required this.mastered,
    required this.memorized,
    required this.familiar,
    required this.learning,
    required this.notStarted,
    required this.needsReview,
    required this.overallAccuracy,
  });

  Map<String, dynamic> toJson() => {
        'total': total,
        'eternal': eternal,
        'mastered': mastered,
        'memorized': memorized,
        'familiar': familiar,
        'learning': learning,
        'notStarted': notStarted,
        'needsReview': needsReview,
        'overallAccuracy': overallAccuracy,
      };
}

/// Lightweight summary of a single scripture's mastery state,
/// included in the snapshot for scriptures that need attention.
class ScriptureProgressSummary {
  final String scriptureId;
  final String reference;
  final String topic;
  final String masteryLevel;
  final double accuracy;
  final bool needsReview;
  final int daysSinceLastPractice;

  const ScriptureProgressSummary({
    required this.scriptureId,
    required this.reference,
    required this.topic,
    required this.masteryLevel,
    required this.accuracy,
    required this.needsReview,
    required this.daysSinceLastPractice,
  });

  Map<String, dynamic> toJson() => {
        'scriptureId': scriptureId,
        'reference': reference,
        'topic': topic,
        'masteryLevel': masteryLevel,
        'accuracy': accuracy,
        'needsReview': needsReview,
        'daysSinceLastPractice': daysSinceLastPractice,
      };
}
