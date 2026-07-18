import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:seminary_sidekick/models/enums.dart';
import 'package:seminary_sidekick/providers/mastery_dates_provider.dart';
import 'package:seminary_sidekick/providers/progress_provider.dart';
import 'package:seminary_sidekick/providers/scripture_mastery_provider.dart';
import 'package:seminary_sidekick/providers/spaced_repetition_provider.dart';

/// Regression: Scripture Builder results must stage the avatar from
/// [ScriptureMastery] (difficulty ladder), not [UserProgress.masteryLevel]
/// (accuracy). Completing a messy Beginner round used to show Standard Bearer
/// because every finish was recorded as correct → 100% accuracy → Mastered.
void main() {
  late ProviderContainer container;
  late Directory tempDir;
  late ProgressNotifier progressNotifier;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_sb_badge_');
    Hive.init(tempDir.path);
    container = ProviderContainer();
    await container.read(spacedRepetitionProvider.notifier).init();
    await container.read(masteryDatesProvider.notifier).init();
    progressNotifier = container.read(progressProvider.notifier);
    await progressNotifier.init();
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  /// Mirrors the post-round wiring in ScriptureBuilderScreen._navigateToResults.
  ({AvatarStage avatar, bool newlyMastered, MasteryLevel holistic})
      recordSbRound({
    required String scriptureId,
    required DifficultyLevel difficulty,
    required int incorrectAttempts,
  }) {
    final prevHolistic =
        container.read(scriptureMasteryProvider(scriptureId)).level;
    final sessionPerfect = incorrectAttempts == 0;
    final attemptCorrect =
        difficulty != DifficultyLevel.master || sessionPerfect;

    progressNotifier.recordAttempt(
      scriptureId: scriptureId,
      gameType: GameType.scriptureBuilder,
      correct: attemptCorrect,
      difficultyCompleted: difficulty,
    );

    final newHolistic =
        container.read(scriptureMasteryProvider(scriptureId)).level;
    // Mirror screen: banner only when Master difficulty crosses into Mastered.
    final newlyMastered = difficulty == DifficultyLevel.master &&
        prevHolistic.index < MasteryLevel.mastered.index &&
        newHolistic.index >= MasteryLevel.mastered.index;
    return (
      avatar: AvatarStage.forMasteryLevel(newHolistic),
      newlyMastered: newlyMastered,
      holistic: newHolistic,
    );
  }

  test('messy Beginner finish → Quick to Observe, not Standard Bearer', () {
    final result = recordSbRound(
      scriptureId: 'john-3-16',
      difficulty: DifficultyLevel.beginner,
      incorrectAttempts: 12, // low red-bar score session
    );

    expect(result.holistic, MasteryLevel.learning);
    expect(result.avatar, AvatarStage.quickToObserve);
    expect(result.newlyMastered, isFalse);

    // Accuracy-based field still jumps to Mastered — prove we must not use it.
    final accuracyLevel = progressNotifier
        .getProgress('john-3-16', GameType.scriptureBuilder)!
        .masteryLevel;
    expect(accuracyLevel, MasteryLevel.mastered);
    expect(
      AvatarStage.forMasteryLevel(accuracyLevel),
      AvatarStage.standardBearer,
      reason: 'documents the old bug: accuracy mastery mapped to stage 4',
    );
  });

  test('Intermediate finish stages Stalwart, not Standard Bearer', () {
    final result = recordSbRound(
      scriptureId: '1-nephi-3-7',
      difficulty: DifficultyLevel.intermediate,
      incorrectAttempts: 5,
    );

    expect(result.holistic, MasteryLevel.familiar);
    expect(result.avatar, AvatarStage.stalwart);
    expect(result.newlyMastered, isFalse);
  });

  test('imperfect Master run does not increment consecutivePerfectMaster', () {
    recordSbRound(
      scriptureId: 'alma-32-21',
      difficulty: DifficultyLevel.master,
      incorrectAttempts: 3,
    );

    final progress = progressNotifier.getProgress(
      'alma-32-21',
      GameType.scriptureBuilder,
    )!;
    expect(progress.consecutivePerfectMaster, 0);
    expect(
      container.read(scriptureMasteryProvider('alma-32-21')).level,
      MasteryLevel.memorized,
    );
  });

  test('first two perfect Master runs do not show Mastered banner', () {
    final first = recordSbRound(
      scriptureId: 'moroni-10-5',
      difficulty: DifficultyLevel.master,
      incorrectAttempts: 0,
    );
    expect(first.newlyMastered, isFalse);
    expect(first.holistic, MasteryLevel.memorized);

    final second = recordSbRound(
      scriptureId: 'moroni-10-5',
      difficulty: DifficultyLevel.master,
      incorrectAttempts: 0,
    );
    expect(second.newlyMastered, isFalse);
    expect(second.holistic, MasteryLevel.memorized);
  });

  test('third perfect Master run reaches Mastered → banner + Standard Bearer',
      () {
    for (var i = 0; i < 2; i++) {
      recordSbRound(
        scriptureId: 'moroni-10-5',
        difficulty: DifficultyLevel.master,
        incorrectAttempts: 0,
      );
    }

    final third = recordSbRound(
      scriptureId: 'moroni-10-5',
      difficulty: DifficultyLevel.master,
      incorrectAttempts: 0,
    );

    expect(third.holistic, MasteryLevel.mastered);
    expect(third.avatar, AvatarStage.standardBearer);
    expect(third.newlyMastered, isTrue);
  });

  test('Beginner / Intermediate / Advanced never set newlyMastered banner', () {
    for (final difficulty in [
      DifficultyLevel.beginner,
      DifficultyLevel.intermediate,
      DifficultyLevel.advanced,
    ]) {
      final result = recordSbRound(
        scriptureId: 'banner-$difficulty',
        difficulty: difficulty,
        incorrectAttempts: 0,
      );
      expect(result.newlyMastered, isFalse,
          reason: '$difficulty must not show the Mastered banner');
    }
  });
}
