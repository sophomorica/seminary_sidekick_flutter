import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_progress.dart';
import '../models/enums.dart';

/// User statistics model for overall progress
class UserStats {
  final int totalAttempted;
  final int totalMemorized;
  final int totalMastered;
  final int needsReview;
  final int currentStreak;
  final double overallAccuracy;

  UserStats({
    required this.totalAttempted,
    required this.totalMemorized,
    required this.totalMastered,
    required this.needsReview,
    required this.currentStreak,
    required this.overallAccuracy,
  });
}

/// StateNotifier for managing user progress
class ProgressNotifier extends StateNotifier<Map<String, UserProgress>> {
  ProgressNotifier() : super({});

  /// Generate storage key for a scripture/game combination
  String _getStorageKey(String scriptureId, GameType gameType) {
    return '${scriptureId}_${gameType.name}';
  }

  /// Record an attempt at a scripture game
  void recordAttempt({
    required String scriptureId,
    required GameType gameType,
    required bool correct,
    int? time,
    DifficultyLevel? difficultyCompleted,
  }) {
    final key = _getStorageKey(scriptureId, gameType);
    final current = state[key] ??
        UserProgress(
          scriptureId: scriptureId,
          gameType: gameType,
          highestDifficultyCompleted: DifficultyLevel.beginner,
          totalAttempts: 0,
          correctAttempts: 0,
          currentStreak: 0,
          bestStreak: 0,
          bestTime: null,
          lastPracticed: DateTime.now(),
          accuracy: 0.0,
          masteryLevel: MasteryLevel.newScripture,
          needsReview: true,
        );

    final totalAttempts = current.totalAttempts + 1;
    final correctAttempts = current.correctAttempts + (correct ? 1 : 0);
    final accuracy = (correctAttempts / totalAttempts) * 100;
    final newStreak = correct ? current.currentStreak + 1 : 0;
    final bestStreak =
        newStreak > current.bestStreak ? newStreak : current.bestStreak;

    // Update highest difficulty if provided
    DifficultyLevel newHighestDifficulty = current.highestDifficultyCompleted;
    if (difficultyCompleted != null &&
        _difficultyRank(difficultyCompleted) >
            _difficultyRank(newHighestDifficulty)) {
      newHighestDifficulty = difficultyCompleted;
    }

    // Determine new mastery level based on accuracy
    final newMasteryLevel = _getMasteryLevelFromAccuracy(accuracy);

    // Determine if needs review
    final needsReview = accuracy < 80;

    // Update best time if provided
    int? newBestTime = current.bestTime;
    if (time != null) {
      newBestTime = current.bestTime == null
          ? time
          : (time < current.bestTime! ? time : current.bestTime);
    }

    final updated = UserProgress(
      scriptureId: scriptureId,
      gameType: gameType,
      highestDifficultyCompleted: newHighestDifficulty,
      totalAttempts: totalAttempts,
      correctAttempts: correctAttempts,
      currentStreak: newStreak,
      bestStreak: bestStreak,
      bestTime: newBestTime,
      lastPracticed: DateTime.now(),
      accuracy: accuracy,
      masteryLevel: newMasteryLevel,
      needsReview: needsReview,
    );

    state = {...state, key: updated};
  }

  /// Get progress for a scripture/game combination
  UserProgress? getProgress(String scriptureId, GameType gameType) {
    final key = _getStorageKey(scriptureId, gameType);
    return state[key];
  }

  /// Get mastery level for a scripture/game combination
  MasteryLevel getMasteryLevel(String scriptureId, GameType gameType) {
    final progress = getProgress(scriptureId, gameType);
    return progress?.masteryLevel ?? MasteryLevel.newScripture;
  }

  /// Get overall user statistics
  UserStats getOverallStats() {
    int totalAttempted = 0;
    int totalMemorized = 0;
    int totalMastered = 0;
    int needsReview = 0;
    int totalCorrect = 0;
    int totalQuestions = 0;

    for (final progress in state.values) {
      if (progress.totalAttempts > 0) {
        totalAttempted++;
      }
      if (progress.masteryLevel == MasteryLevel.memorized) {
        totalMemorized++;
      }
      if (progress.masteryLevel == MasteryLevel.mastered) {
        totalMastered++;
      }
      if (progress.needsReview) {
        needsReview++;
      }
      totalCorrect += progress.correctAttempts;
      totalQuestions += progress.totalAttempts;
    }

    final overallAccuracy = totalQuestions > 0
        ? (totalCorrect / totalQuestions) * 100
        : 0.0;

    // Find current streak across all games
    int currentStreak = 0;
    for (final progress in state.values) {
      if (progress.currentStreak > currentStreak) {
        currentStreak = progress.currentStreak;
      }
    }

    return UserStats(
      totalAttempted: totalAttempted,
      totalMemorized: totalMemorized,
      totalMastered: totalMastered,
      needsReview: needsReview,
      currentStreak: currentStreak,
      overallAccuracy: overallAccuracy,
    );
  }

  /// Convert accuracy percentage to mastery level
  MasteryLevel _getMasteryLevelFromAccuracy(double accuracy) {
    if (accuracy >= 95) return MasteryLevel.mastered;
    if (accuracy >= 85) return MasteryLevel.memorized;
    if (accuracy >= 70) return MasteryLevel.familiar;
    if (accuracy >= 50) return MasteryLevel.learning;
    return MasteryLevel.newScripture;
  }

  /// Get difficulty ranking for comparison
  int _difficultyRank(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.beginner:
        return 0;
      case DifficultyLevel.intermediate:
        return 1;
      case DifficultyLevel.advanced:
        return 2;
      case DifficultyLevel.master:
        return 3;
    }
  }
}

/// State notifier provider for progress management
final progressProvider =
    StateNotifierProvider<ProgressNotifier, Map<String, UserProgress>>(
  (ref) => ProgressNotifier(),
);

/// Family provider to get progress for a specific scripture/game
final progressByScriptureProvider =
    Provider.family<UserProgress?, (String, GameType)>(
  (ref, params) {
    final (scriptureId, gameType) = params;
    final notifier = ref.read(progressProvider.notifier);
    return notifier.getProgress(scriptureId, gameType);
  },
);

/// Provider to get overall user statistics
final userStatsProvider = Provider<UserStats>(
  (ref) {
    final notifier = ref.read(progressProvider.notifier);
    return notifier.getOverallStats();
  },
);

/// Family provider to get mastery level for a scripture/game
final masteryLevelProvider = Provider.family<MasteryLevel, (String, GameType)>(
  (ref, params) {
    final (scriptureId, gameType) = params;
    final notifier = ref.read(progressProvider.notifier);
    return notifier.getMasteryLevel(scriptureId, gameType);
  },
);
