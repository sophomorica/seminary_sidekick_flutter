import 'enums.dart';

/// Tracks a user's progress on a single scripture within a single game type.
///
/// Each scripture+game combination has its own progress record.
/// Stores computed values for easy access from the UI.
class UserProgress {
  final String scriptureId;
  final GameType gameType;
  final DifficultyLevel highestDifficultyCompleted;
  final int totalAttempts;
  final int correctAttempts;
  final int currentStreak;
  final int bestStreak;
  final int? bestTime; // in seconds
  final DateTime? lastPracticed;
  final double accuracy; // 0-100 percentage
  final MasteryLevel masteryLevel;
  final bool needsReview;

  /// Consecutive perfect completions at Master difficulty.
  /// Only meaningful for wordOrder (Word Builder) game type.
  /// Resets to 0 on any failure at Master difficulty.
  final int consecutivePerfectMaster;

  /// Difficulty levels the user has explicitly completed (actually played).
  /// Used to detect "shortcut" skips — tiers that are auto-credited because
  /// the user proved mastery at a higher difficulty without playing lower ones.
  final Set<DifficultyLevel> explicitlyCompletedDifficulties;

  const UserProgress({
    required this.scriptureId,
    required this.gameType,
    this.highestDifficultyCompleted = DifficultyLevel.beginner,
    this.totalAttempts = 0,
    this.correctAttempts = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.bestTime,
    this.lastPracticed,
    this.accuracy = 0.0,
    this.masteryLevel = MasteryLevel.newScripture,
    this.needsReview = true,
    this.consecutivePerfectMaster = 0,
    this.explicitlyCompletedDifficulties = const {},
  });

  /// Storage key for Hive.
  String get storageKey => '${scriptureId}_${gameType.name}';

  /// Serialize to a JSON-compatible map for Hive storage.
  Map<String, dynamic> toJson() {
    return {
      'scriptureId': scriptureId,
      'gameType': gameType.name,
      'highestDifficultyCompleted': highestDifficultyCompleted.name,
      'totalAttempts': totalAttempts,
      'correctAttempts': correctAttempts,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'bestTime': bestTime,
      'lastPracticed': lastPracticed?.toIso8601String(),
      'accuracy': accuracy,
      'masteryLevel': masteryLevel.name,
      'needsReview': needsReview,
      'consecutivePerfectMaster': consecutivePerfectMaster,
      'explicitlyCompletedDifficulties':
          explicitlyCompletedDifficulties.map((d) => d.name).toList(),
    };
  }

  /// Deserialize from a JSON-compatible map stored in Hive.
  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      scriptureId: json['scriptureId'] as String,
      gameType: GameType.values.byName(json['gameType'] as String),
      highestDifficultyCompleted: DifficultyLevel.values
          .byName(json['highestDifficultyCompleted'] as String),
      totalAttempts: json['totalAttempts'] as int,
      correctAttempts: json['correctAttempts'] as int,
      currentStreak: json['currentStreak'] as int,
      bestStreak: json['bestStreak'] as int,
      bestTime: json['bestTime'] as int?,
      lastPracticed: json['lastPracticed'] != null
          ? DateTime.parse(json['lastPracticed'] as String)
          : null,
      accuracy: (json['accuracy'] as num).toDouble(),
      masteryLevel: MasteryLevel.values.byName(json['masteryLevel'] as String),
      needsReview: json['needsReview'] as bool,
      consecutivePerfectMaster:
          (json['consecutivePerfectMaster'] as int?) ?? 0,
      explicitlyCompletedDifficulties:
          (json['explicitlyCompletedDifficulties'] as List<dynamic>?)
                  ?.map((name) => DifficultyLevel.values.byName(name as String))
                  .toSet() ??
              const {},
    );
  }
}
