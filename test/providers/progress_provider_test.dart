import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:seminary_sidekick/providers/progress_provider.dart';
import 'package:seminary_sidekick/providers/spaced_repetition_provider.dart';
import 'package:seminary_sidekick/models/enums.dart';

void main() {
  late ProgressNotifier notifier;
  late ProviderContainer container;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    container = ProviderContainer();
    // Initialize spaced repetition first (progress provider depends on it)
    await container.read(spacedRepetitionProvider.notifier).init();
    notifier = container.read(progressProvider.notifier);
    await notifier.init();
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  // -------------------------------------------------------
  // recordAttempt
  // -------------------------------------------------------
  group('recordAttempt', () {
    test('first correct attempt creates progress with 100% accuracy', () {
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: true,
      );

      final progress = notifier.getProgress('test-1', GameType.matching);
      expect(progress, isNotNull);
      expect(progress!.totalAttempts, 1);
      expect(progress.correctAttempts, 1);
      expect(progress.accuracy, 100.0);
      expect(progress.currentStreak, 1);
      expect(progress.bestStreak, 1);
      expect(progress.lastPracticed, isNotNull);
    });

    test('first incorrect attempt creates progress with 0% accuracy', () {
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: false,
      );

      final progress = notifier.getProgress('test-1', GameType.matching);
      expect(progress, isNotNull);
      expect(progress!.totalAttempts, 1);
      expect(progress.correctAttempts, 0);
      expect(progress.accuracy, 0.0);
      expect(progress.currentStreak, 0);
    });

    test('correct answer increments streak', () {
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: true,
      );
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: true,
      );
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: true,
      );

      final progress = notifier.getProgress('test-1', GameType.matching);
      expect(progress!.currentStreak, 3);
      expect(progress.bestStreak, 3);
    });

    test('incorrect answer resets streak to 0', () {
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: true,
      );
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: true,
      );
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: false,
      );

      final progress = notifier.getProgress('test-1', GameType.matching);
      expect(progress!.currentStreak, 0);
    });

    test('bestStreak updates only when currentStreak exceeds it', () {
      // Build streak to 3
      for (var i = 0; i < 3; i++) {
        notifier.recordAttempt(
          scriptureId: 'test-1',
          gameType: GameType.matching,
          correct: true,
        );
      }
      // Break streak
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: false,
      );
      // Build new streak to 2 (less than best of 3)
      for (var i = 0; i < 2; i++) {
        notifier.recordAttempt(
          scriptureId: 'test-1',
          gameType: GameType.matching,
          correct: true,
        );
      }

      final progress = notifier.getProgress('test-1', GameType.matching);
      expect(progress!.bestStreak, 3);
      expect(progress.currentStreak, 2);
    });

    test('bestTime stores first time', () {
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: true,
        time: 45,
      );

      final progress = notifier.getProgress('test-1', GameType.matching);
      expect(progress!.bestTime, 45);
    });

    test('bestTime updates only when faster', () {
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: true,
        time: 45,
      );
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: true,
        time: 60, // slower — should not replace
      );

      final progress = notifier.getProgress('test-1', GameType.matching);
      expect(progress!.bestTime, 45);
    });

    test('bestTime updates when new time is faster', () {
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: true,
        time: 45,
      );
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: true,
        time: 30, // faster — should replace
      );

      final progress = notifier.getProgress('test-1', GameType.matching);
      expect(progress!.bestTime, 30);
    });

    test('highestDifficultyCompleted updates upward only', () {
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: true,
        difficultyCompleted: DifficultyLevel.intermediate,
      );
      expect(
        notifier.getProgress('test-1', GameType.matching)!
            .highestDifficultyCompleted,
        DifficultyLevel.intermediate,
      );

      // Try to downgrade — should stay at intermediate
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: true,
        difficultyCompleted: DifficultyLevel.beginner,
      );
      expect(
        notifier.getProgress('test-1', GameType.matching)!
            .highestDifficultyCompleted,
        DifficultyLevel.intermediate,
      );

      // Upgrade to advanced — should update
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: true,
        difficultyCompleted: DifficultyLevel.advanced,
      );
      expect(
        notifier.getProgress('test-1', GameType.matching)!
            .highestDifficultyCompleted,
        DifficultyLevel.advanced,
      );
    });

    test('accuracy recalculates correctly over multiple attempts', () {
      // 3 correct, 1 incorrect = 75%
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: true,
      );
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: true,
      );
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: true,
      );
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: false,
      );

      final progress = notifier.getProgress('test-1', GameType.matching);
      expect(progress!.accuracy, 75.0);
      expect(progress.totalAttempts, 4);
      expect(progress.correctAttempts, 3);
    });
  });

  // -------------------------------------------------------
  // Mastery thresholds
  // -------------------------------------------------------
  group('mastery thresholds', () {
    void recordNAttempts(
      ProgressNotifier n,
      int correct,
      int incorrect, {
      String id = 'test-1',
    }) {
      for (var i = 0; i < correct; i++) {
        n.recordAttempt(
          scriptureId: id,
          gameType: GameType.matching,
          correct: true,
        );
      }
      for (var i = 0; i < incorrect; i++) {
        n.recordAttempt(
          scriptureId: id,
          gameType: GameType.matching,
          correct: false,
        );
      }
    }

    test('0-49% accuracy → newScripture', () {
      // 2 correct, 5 incorrect = 28.6%
      recordNAttempts(notifier, 2, 5);
      final progress = notifier.getProgress('test-1', GameType.matching);
      expect(progress!.accuracy, lessThan(50));
      expect(progress.masteryLevel, MasteryLevel.newScripture);
    });

    test('50-69% accuracy → learning', () {
      // 3 correct, 2 incorrect = 60%
      recordNAttempts(notifier, 3, 2);
      final progress = notifier.getProgress('test-1', GameType.matching);
      expect(progress!.accuracy, closeTo(60.0, 0.1));
      expect(progress.masteryLevel, MasteryLevel.learning);
    });

    test('70-84% accuracy → familiar', () {
      // 3 correct, 1 incorrect = 75%
      recordNAttempts(notifier, 3, 1);
      final progress = notifier.getProgress('test-1', GameType.matching);
      expect(progress!.accuracy, 75.0);
      expect(progress.masteryLevel, MasteryLevel.familiar);
    });

    test('85-94% accuracy → memorized', () {
      // 9 correct, 1 incorrect = 90%
      recordNAttempts(notifier, 9, 1);
      final progress = notifier.getProgress('test-1', GameType.matching);
      expect(progress!.accuracy, 90.0);
      expect(progress.masteryLevel, MasteryLevel.memorized);
    });

    test('95%+ accuracy → mastered', () {
      // 19 correct, 1 incorrect = 95%
      recordNAttempts(notifier, 19, 1);
      final progress = notifier.getProgress('test-1', GameType.matching);
      expect(progress!.accuracy, 95.0);
      expect(progress.masteryLevel, MasteryLevel.mastered);
    });

    test('100% accuracy → mastered', () {
      recordNAttempts(notifier, 5, 0);
      final progress = notifier.getProgress('test-1', GameType.matching);
      expect(progress!.accuracy, 100.0);
      expect(progress.masteryLevel, MasteryLevel.mastered);
    });
  });

  // -------------------------------------------------------
  // needsReview
  // -------------------------------------------------------
  group('needsReview', () {
    test('true when accuracy < 80%', () {
      // 3 correct, 1 incorrect = 75%
      for (var i = 0; i < 3; i++) {
        notifier.recordAttempt(
          scriptureId: 'test-1',
          gameType: GameType.matching,
          correct: true,
        );
      }
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: false,
      );

      final progress = notifier.getProgress('test-1', GameType.matching);
      expect(progress!.accuracy, 75.0);
      expect(progress.needsReview, true);
    });

    test('false when accuracy >= 80%', () {
      // 4 correct, 1 incorrect = 80%
      for (var i = 0; i < 4; i++) {
        notifier.recordAttempt(
          scriptureId: 'test-1',
          gameType: GameType.matching,
          correct: true,
        );
      }
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: false,
      );

      final progress = notifier.getProgress('test-1', GameType.matching);
      expect(progress!.accuracy, 80.0);
      expect(progress.needsReview, false);
    });
  });

  // -------------------------------------------------------
  // getProgress
  // -------------------------------------------------------
  group('getProgress', () {
    test('returns null for missing key', () {
      final progress = notifier.getProgress('nonexistent', GameType.matching);
      expect(progress, isNull);
    });

    test('returns correct UserProgress for existing key', () {
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: true,
      );

      final progress = notifier.getProgress('test-1', GameType.matching);
      expect(progress, isNotNull);
      expect(progress!.scriptureId, 'test-1');
      expect(progress.gameType, GameType.matching);
    });
  });

  // -------------------------------------------------------
  // getMasteryLevel
  // -------------------------------------------------------
  group('getMasteryLevel', () {
    test('returns newScripture when no data exists', () {
      final level = notifier.getMasteryLevel('test-1', GameType.matching);
      expect(level, MasteryLevel.newScripture);
    });

    test('returns correct level after recording attempts', () {
      // 5 correct = 100% → mastered
      for (var i = 0; i < 5; i++) {
        notifier.recordAttempt(
          scriptureId: 'test-1',
          gameType: GameType.matching,
          correct: true,
        );
      }
      final level = notifier.getMasteryLevel('test-1', GameType.matching);
      expect(level, MasteryLevel.mastered);
    });
  });

  // -------------------------------------------------------
  // getOverallStats
  // -------------------------------------------------------
  group('getOverallStats', () {
    test('empty state returns all zeros', () {
      final stats = notifier.getOverallStats();
      expect(stats.totalAttempted, 0);
      expect(stats.totalMemorized, 0);
      expect(stats.totalMastered, 0);
      expect(stats.needsReview, 0);
      expect(stats.currentStreak, 0);
      expect(stats.overallAccuracy, 0.0);
    });

    test('counts totalAttempted correctly', () {
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: true,
      );
      notifier.recordAttempt(
        scriptureId: 'test-2',
        gameType: GameType.matching,
        correct: false,
      );

      final stats = notifier.getOverallStats();
      expect(stats.totalAttempted, 2);
    });

    test('counts totalMemorized correctly', () {
      // 9 correct, 1 incorrect = 90% → memorized
      for (var i = 0; i < 9; i++) {
        notifier.recordAttempt(
          scriptureId: 'test-1',
          gameType: GameType.matching,
          correct: true,
        );
      }
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: false,
      );

      final stats = notifier.getOverallStats();
      expect(stats.totalMemorized, 1);
    });

    test('counts totalMastered correctly', () {
      // 20 correct, 1 incorrect = 95.2% → mastered
      for (var i = 0; i < 20; i++) {
        notifier.recordAttempt(
          scriptureId: 'test-1',
          gameType: GameType.matching,
          correct: true,
        );
      }
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: false,
      );

      final stats = notifier.getOverallStats();
      expect(stats.totalMastered, 1);
    });

    test('currentStreak returns highest streak across all entries', () {
      // test-1: streak of 3
      for (var i = 0; i < 3; i++) {
        notifier.recordAttempt(
          scriptureId: 'test-1',
          gameType: GameType.matching,
          correct: true,
        );
      }
      // test-2: streak of 5
      for (var i = 0; i < 5; i++) {
        notifier.recordAttempt(
          scriptureId: 'test-2',
          gameType: GameType.matching,
          correct: true,
        );
      }

      final stats = notifier.getOverallStats();
      expect(stats.currentStreak, 5);
    });

    test('overallAccuracy aggregates across all entries', () {
      // test-1: 2 correct, 0 incorrect
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: true,
      );
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: true,
      );
      // test-2: 1 correct, 1 incorrect
      notifier.recordAttempt(
        scriptureId: 'test-2',
        gameType: GameType.matching,
        correct: true,
      );
      notifier.recordAttempt(
        scriptureId: 'test-2',
        gameType: GameType.matching,
        correct: false,
      );

      // Overall: 3 correct out of 4 = 75%
      final stats = notifier.getOverallStats();
      expect(stats.overallAccuracy, 75.0);
    });

    test('needsReview counts entries with accuracy < 80%', () {
      // test-1: 100% → does not need review
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: true,
      );
      // test-2: 0% → needs review
      notifier.recordAttempt(
        scriptureId: 'test-2',
        gameType: GameType.matching,
        correct: false,
      );

      final stats = notifier.getOverallStats();
      expect(stats.needsReview, 1);
    });
  });

  // -------------------------------------------------------
  // Game type isolation
  // -------------------------------------------------------
  group('game type isolation', () {
    test('different game types have independent progress', () {
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: true,
      );
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.scriptureBuilder,
        correct: false,
      );

      final matching = notifier.getProgress('test-1', GameType.matching);
      final scriptureBuilder = notifier.getProgress('test-1', GameType.scriptureBuilder);

      expect(matching!.accuracy, 100.0);
      expect(matching.currentStreak, 1);
      expect(scriptureBuilder!.accuracy, 0.0);
      expect(scriptureBuilder.currentStreak, 0);
    });

    test('same scripture different games are separate entries', () {
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: true,
      );
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.quiz,
        correct: true,
      );

      final stats = notifier.getOverallStats();
      expect(stats.totalAttempted, 2);
    });
  });

  // -------------------------------------------------------
  // consecutivePerfectMaster tracking
  // -------------------------------------------------------
  group('consecutivePerfectMaster', () {
    test('defaults to 0 on first attempt', () {
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.scriptureBuilder,
        correct: true,
        difficultyCompleted: DifficultyLevel.beginner,
      );

      final progress = notifier.getProgress('test-1', GameType.scriptureBuilder);
      expect(progress!.consecutivePerfectMaster, 0);
    });

    test('increments on correct SB Master attempt', () {
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.scriptureBuilder,
        correct: true,
        difficultyCompleted: DifficultyLevel.master,
      );

      final progress = notifier.getProgress('test-1', GameType.scriptureBuilder);
      expect(progress!.consecutivePerfectMaster, 1);
    });

    test('increments consecutively on multiple correct SB Master attempts', () {
      for (var i = 0; i < 3; i++) {
        notifier.recordAttempt(
          scriptureId: 'test-1',
          gameType: GameType.scriptureBuilder,
          correct: true,
          difficultyCompleted: DifficultyLevel.master,
        );
      }

      final progress = notifier.getProgress('test-1', GameType.scriptureBuilder);
      expect(progress!.consecutivePerfectMaster, 3);
    });

    test('resets to 0 on incorrect SB Master attempt', () {
      // Build up to 2
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.scriptureBuilder,
        correct: true,
        difficultyCompleted: DifficultyLevel.master,
      );
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.scriptureBuilder,
        correct: true,
        difficultyCompleted: DifficultyLevel.master,
      );
      expect(
        notifier.getProgress('test-1', GameType.scriptureBuilder)!
            .consecutivePerfectMaster,
        2,
      );

      // Fail at Master → reset
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.scriptureBuilder,
        correct: false,
        difficultyCompleted: DifficultyLevel.master,
      );

      final progress = notifier.getProgress('test-1', GameType.scriptureBuilder);
      expect(progress!.consecutivePerfectMaster, 0);
    });

    test('unchanged on non-Master SB attempts', () {
      // First get a Master success
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.scriptureBuilder,
        correct: true,
        difficultyCompleted: DifficultyLevel.master,
      );
      expect(
        notifier.getProgress('test-1', GameType.scriptureBuilder)!
            .consecutivePerfectMaster,
        1,
      );

      // Advanced attempt should not change the counter
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.scriptureBuilder,
        correct: true,
        difficultyCompleted: DifficultyLevel.advanced,
      );

      final progress = notifier.getProgress('test-1', GameType.scriptureBuilder);
      expect(progress!.consecutivePerfectMaster, 1);
    });

    test('unchanged on non-SB game types at Master difficulty', () {
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: true,
        difficultyCompleted: DifficultyLevel.master,
      );

      final progress = notifier.getProgress('test-1', GameType.matching);
      expect(progress!.consecutivePerfectMaster, 0);
    });

    test('can rebuild after reset', () {
      // Build to 2, reset, build to 3
      for (var i = 0; i < 2; i++) {
        notifier.recordAttempt(
          scriptureId: 'test-1',
          gameType: GameType.scriptureBuilder,
          correct: true,
          difficultyCompleted: DifficultyLevel.master,
        );
      }
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.scriptureBuilder,
        correct: false,
        difficultyCompleted: DifficultyLevel.master,
      );
      for (var i = 0; i < 3; i++) {
        notifier.recordAttempt(
          scriptureId: 'test-1',
          gameType: GameType.scriptureBuilder,
          correct: true,
          difficultyCompleted: DifficultyLevel.master,
        );
      }

      final progress = notifier.getProgress('test-1', GameType.scriptureBuilder);
      expect(progress!.consecutivePerfectMaster, 3);
    });
  });

  // -------------------------------------------------------
  // Storage key format
  // -------------------------------------------------------
  group('storage key format', () {
    test('getProgress uses {scriptureId}_{gameType.name} format', () {
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: true,
      );

      // Verify via state map directly
      expect(notifier.state.containsKey('test-1_matching'), true);
    });

    test('different game types produce different keys', () {
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        correct: true,
      );
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.scriptureBuilder,
        correct: true,
      );
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.quiz,
        correct: true,
      );

      expect(notifier.state.containsKey('test-1_matching'), true);
      expect(notifier.state.containsKey('test-1_scriptureBuilder'), true);
      expect(notifier.state.containsKey('test-1_quiz'), true);
    });
  });

  // -------------------------------------------------------
  // Mastery shortcut — explicitlyCompletedDifficulties (TASK-031)
  // -------------------------------------------------------
  group('explicitlyCompletedDifficulties tracking', () {
    test('correct completion adds difficulty to explicit set', () {
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.scriptureBuilder,
        correct: true,
        difficultyCompleted: DifficultyLevel.master,
      );

      final progress = notifier.getProgress('test-1', GameType.scriptureBuilder);
      expect(
        progress!.explicitlyCompletedDifficulties,
        contains(DifficultyLevel.master),
      );
    });

    test('incorrect attempt does NOT add difficulty to explicit set', () {
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.scriptureBuilder,
        correct: false,
        difficultyCompleted: DifficultyLevel.master,
      );

      final progress = notifier.getProgress('test-1', GameType.scriptureBuilder);
      expect(progress!.explicitlyCompletedDifficulties, isEmpty);
    });

    test('jumping to Master only adds Master, not lower tiers', () {
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.scriptureBuilder,
        correct: true,
        difficultyCompleted: DifficultyLevel.master,
      );

      final progress = notifier.getProgress('test-1', GameType.scriptureBuilder);
      expect(progress!.explicitlyCompletedDifficulties, {DifficultyLevel.master});
      expect(progress.highestDifficultyCompleted, DifficultyLevel.master);
      // Lower tiers are NOT in the explicit set — they're auto-credited
      expect(
        progress.explicitlyCompletedDifficulties
            .contains(DifficultyLevel.beginner),
        false,
      );
    });

    test('completing ladder adds each tier to explicit set', () {
      for (final difficulty in DifficultyLevel.values) {
        notifier.recordAttempt(
          scriptureId: 'test-1',
          gameType: GameType.scriptureBuilder,
          correct: true,
          difficultyCompleted: difficulty,
        );
      }

      final progress = notifier.getProgress('test-1', GameType.scriptureBuilder);
      expect(
        progress!.explicitlyCompletedDifficulties,
        DifficultyLevel.values.toSet(),
      );
    });

    test('explicit set persists across multiple attempts', () {
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.scriptureBuilder,
        correct: true,
        difficultyCompleted: DifficultyLevel.beginner,
      );
      notifier.recordAttempt(
        scriptureId: 'test-1',
        gameType: GameType.scriptureBuilder,
        correct: true,
        difficultyCompleted: DifficultyLevel.master,
      );

      final progress = notifier.getProgress('test-1', GameType.scriptureBuilder);
      expect(
        progress!.explicitlyCompletedDifficulties,
        {DifficultyLevel.beginner, DifficultyLevel.master},
      );
    });
  });
}
