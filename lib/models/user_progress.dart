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
  });

  /// Storage key for Hive.
  String get storageKey => '${scriptureId}_${gameType.name}';
}
