import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/models/scripture_mastery.dart';
import 'package:seminary_sidekick/models/user_progress.dart';
import 'package:seminary_sidekick/models/enums.dart';

void main() {
  // -------------------------------------------------------
  // Helper: build a progressByGame map for ScriptureMastery.compute()
  // -------------------------------------------------------
  Map<GameType, UserProgress?> makeProgress({
    DifficultyLevel? sbDifficulty,
    int sbAttempts = 0,
    int sbCorrect = 0,
    int consecutivePerfectMaster = 0,
    Set<DifficultyLevel>? sbExplicitDifficulties,
    DifficultyLevel? matchDifficulty,
    int matchAttempts = 0,
    int matchCorrect = 0,
    DifficultyLevel? quizDifficulty,
    int quizAttempts = 0,
    int quizCorrect = 0,
    DateTime? lastPracticed,
  }) {
    final lp = lastPracticed ?? DateTime.now();
    return {
      GameType.scriptureBuilder: sbAttempts > 0
          ? UserProgress(
              scriptureId: 'test-1',
              gameType: GameType.scriptureBuilder,
              highestDifficultyCompleted:
                  sbDifficulty ?? DifficultyLevel.beginner,
              totalAttempts: sbAttempts,
              correctAttempts: sbCorrect,
              lastPracticed: lp,
              accuracy: sbAttempts > 0 ? (sbCorrect / sbAttempts) * 100 : 0.0,
              consecutivePerfectMaster: consecutivePerfectMaster,
              explicitlyCompletedDifficulties: sbExplicitDifficulties ?? const {},
            )
          : null,
      GameType.matching: matchAttempts > 0
          ? UserProgress(
              scriptureId: 'test-1',
              gameType: GameType.matching,
              highestDifficultyCompleted:
                  matchDifficulty ?? DifficultyLevel.beginner,
              totalAttempts: matchAttempts,
              correctAttempts: matchCorrect,
              lastPracticed: lp,
              accuracy: matchAttempts > 0
                  ? (matchCorrect / matchAttempts) * 100
                  : 0.0,
            )
          : null,
      GameType.quiz: quizAttempts > 0
          ? UserProgress(
              scriptureId: 'test-1',
              gameType: GameType.quiz,
              highestDifficultyCompleted:
                  quizDifficulty ?? DifficultyLevel.beginner,
              totalAttempts: quizAttempts,
              correctAttempts: quizCorrect,
              lastPracticed: lp,
              accuracy:
                  quizAttempts > 0 ? (quizCorrect / quizAttempts) * 100 : 0.0,
            )
          : null,
    };
  }

  // -------------------------------------------------------
  // Linear path: New → Learning → Familiar → Memorized → Mastered → Eternal
  // -------------------------------------------------------
  group('Linear mastery path — Scripture Builder driven', () {
    test('no progress → New', () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(),
      );
      expect(mastery.level, MasteryLevel.newScripture);
    });

    test('SB Beginner completed → Learning', () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.beginner,
          sbAttempts: 5,
          sbCorrect: 4,
        ),
      );
      expect(mastery.level, MasteryLevel.learning);
    });

    test('SB Intermediate completed → Familiar', () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.intermediate,
          sbAttempts: 10,
          sbCorrect: 8,
        ),
      );
      expect(mastery.level, MasteryLevel.familiar);
    });

    test('SB Advanced completed → Memorized', () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.advanced,
          sbAttempts: 15,
          sbCorrect: 12,
        ),
      );
      expect(mastery.level, MasteryLevel.memorized);
    });

    test('SB Master completed but < 3 consecutive perfect → still Memorized',
        () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.master,
          sbAttempts: 20,
          sbCorrect: 18,
          consecutivePerfectMaster: 2,
        ),
      );
      expect(mastery.level, MasteryLevel.memorized);
    });

    test('SB Master + 3 consecutive perfect → Mastered', () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.master,
          sbAttempts: 20,
          sbCorrect: 20,
          consecutivePerfectMaster: 3,
        ),
      );
      expect(mastery.level, MasteryLevel.mastered);
    });

    test(
        'SB Master + 5 consecutive perfect → still Mastered (3 is the threshold)',
        () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.master,
          sbAttempts: 20,
          sbCorrect: 20,
          consecutivePerfectMaster: 5,
        ),
      );
      expect(mastery.level, MasteryLevel.mastered);
    });

    test('Matching/Quiz progress alone does NOT advance mastery', () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          matchDifficulty: DifficultyLevel.master,
          matchAttempts: 50,
          matchCorrect: 50,
          quizDifficulty: DifficultyLevel.master,
          quizAttempts: 50,
          quizCorrect: 50,
        ),
      );
      // No SB progress → still New
      expect(mastery.level, MasteryLevel.newScripture);
    });
  });

  // -------------------------------------------------------
  // Eternal tier
  // -------------------------------------------------------
  group('Eternal tier', () {
    test('isEternal flag → Eternal level, no decay, no review', () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.master,
          sbAttempts: 20,
          sbCorrect: 20,
          consecutivePerfectMaster: 3,
          lastPracticed: DateTime.now().subtract(const Duration(days: 365)),
        ),
        isEternal: true,
        masteredSinceDate: DateTime.now().subtract(const Duration(days: 200)),
      );
      expect(mastery.level, MasteryLevel.eternal);
      expect(mastery.needsReview, false);
      expect(mastery.subProgress, 1.0);
      expect(mastery.nextLevelRequirements, isEmpty);
    });

    test('Mastered + masteredSince shows Eternal requirements with progress',
        () {
      final masteredDate = DateTime.now().subtract(const Duration(days: 90));
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.master,
          sbAttempts: 20,
          sbCorrect: 20,
          consecutivePerfectMaster: 3,
        ),
        masteredSinceDate: masteredDate,
      );
      expect(mastery.level, MasteryLevel.mastered);
      // Next level requirements should show Eternal progress
      expect(mastery.nextLevelRequirements, isNotEmpty);
      final eternalReq = mastery.nextLevelRequirements.first;
      expect(eternalReq.isMet, false);
      // ~90 days / 183 ≈ 49%
      expect(eternalReq.progress, closeTo(90 / 183, 0.02));
    });
  });

  // -------------------------------------------------------
  // Gentle decay
  // -------------------------------------------------------
  group('Gentle decay', () {
    test('no decay within 30 days', () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.master,
          sbAttempts: 20,
          sbCorrect: 20,
          consecutivePerfectMaster: 3,
          lastPracticed: DateTime.now().subtract(const Duration(days: 20)),
        ),
      );
      expect(mastery.level, MasteryLevel.mastered);
    });

    test('Mastered decays to Memorized after 30+ days', () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.master,
          sbAttempts: 20,
          sbCorrect: 20,
          consecutivePerfectMaster: 3,
          lastPracticed: DateTime.now().subtract(const Duration(days: 35)),
        ),
      );
      expect(mastery.level, MasteryLevel.memorized);
    });

    test('Memorized decays to Familiar after 30+ days', () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.advanced,
          sbAttempts: 15,
          sbCorrect: 12,
          lastPracticed: DateTime.now().subtract(const Duration(days: 35)),
        ),
      );
      expect(mastery.level, MasteryLevel.familiar);
    });

    test('Familiar does NOT decay below Familiar (floor rule)', () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.intermediate,
          sbAttempts: 10,
          sbCorrect: 8,
          lastPracticed: DateTime.now().subtract(const Duration(days: 100)),
        ),
      );
      expect(mastery.level, MasteryLevel.familiar);
    });

    test('Learning does NOT decay (below Familiar floor)', () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.beginner,
          sbAttempts: 5,
          sbCorrect: 4,
          lastPracticed: DateTime.now().subtract(const Duration(days: 100)),
        ),
      );
      expect(mastery.level, MasteryLevel.learning);
    });

    test('Eternal never decays even after very long inactivity', () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.master,
          sbAttempts: 20,
          sbCorrect: 20,
          consecutivePerfectMaster: 3,
          lastPracticed: DateTime.now().subtract(const Duration(days: 500)),
        ),
        isEternal: true,
      );
      expect(mastery.level, MasteryLevel.eternal);
    });
  });

  // -------------------------------------------------------
  // Needs review flag
  // -------------------------------------------------------
  group('Needs review', () {
    test('not set when practiced recently (< 14 days)', () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.master,
          sbAttempts: 20,
          sbCorrect: 20,
          consecutivePerfectMaster: 3,
          lastPracticed: DateTime.now().subtract(const Duration(days: 5)),
        ),
      );
      expect(mastery.needsReview, false);
    });

    test('set when > 14 days since last practice', () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.master,
          sbAttempts: 20,
          sbCorrect: 20,
          consecutivePerfectMaster: 3,
          lastPracticed: DateTime.now().subtract(const Duration(days: 20)),
        ),
      );
      expect(mastery.needsReview, true);
    });

    test('never set for Eternal', () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.master,
          sbAttempts: 20,
          sbCorrect: 20,
          consecutivePerfectMaster: 3,
          lastPracticed: DateTime.now().subtract(const Duration(days: 200)),
        ),
        isEternal: true,
      );
      expect(mastery.needsReview, false);
    });

    test('not set when never practiced (no lastPracticed)', () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(),
      );
      expect(mastery.needsReview, false);
    });
  });

  // -------------------------------------------------------
  // Sub-progress toward next level
  // -------------------------------------------------------
  group('Sub-progress', () {
    test('New → Learning: 0 progress when no SB attempts', () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(),
      );
      expect(mastery.subProgress, 0.0);
    });

    test('Memorized → Mastered: partial progress (1/3 perfect runs)', () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.master,
          sbAttempts: 20,
          sbCorrect: 18,
          consecutivePerfectMaster: 1,
        ),
      );
      // Still Memorized (< 3 perfect), with partial progress toward Mastered
      expect(mastery.level, MasteryLevel.memorized);
      // Requirements: reach Master (met) + 3 perfect runs (1/3)
      // Average: (1.0 + 1/3) / 2 ≈ 0.667
      expect(mastery.subProgress, closeTo(0.667, 0.01));
    });

    test('Mastered: 1.0 sub-progress (at top before Eternal)', () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.master,
          sbAttempts: 20,
          sbCorrect: 20,
          consecutivePerfectMaster: 3,
        ),
      );
      expect(mastery.level, MasteryLevel.mastered);
      // Without masteredSinceDate, Eternal req shows 0/183 days
      // So sub-progress should be 0.0 for the Eternal requirement
      expect(mastery.subProgress, closeTo(0.0, 0.01));
    });
  });

  // -------------------------------------------------------
  // Next level requirements
  // -------------------------------------------------------
  group('Next level requirements', () {
    test('New → shows Learning requirements', () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(),
      );
      expect(mastery.nextLevelRequirements, isNotEmpty);
      expect(
        mastery.nextLevelRequirements.first.description,
        contains('Beginner'),
      );
    });

    test('Learning → shows Familiar requirements', () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.beginner,
          sbAttempts: 5,
          sbCorrect: 4,
        ),
      );
      expect(mastery.level, MasteryLevel.learning);
      expect(
        mastery.nextLevelRequirements.first.description,
        contains('Intermediate'),
      );
    });

    test('Familiar → shows Memorized requirements', () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.intermediate,
          sbAttempts: 10,
          sbCorrect: 8,
        ),
      );
      expect(mastery.level, MasteryLevel.familiar);
      expect(
        mastery.nextLevelRequirements.first.description,
        contains('Advanced'),
      );
    });

    test('Memorized → shows Mastered requirements with perfect run count', () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.advanced,
          sbAttempts: 15,
          sbCorrect: 12,
        ),
      );
      expect(mastery.level, MasteryLevel.memorized);
      expect(mastery.nextLevelRequirements.length, 2);
      expect(
        mastery.nextLevelRequirements
            .any((r) => r.description.contains('Master')),
        true,
      );
      expect(
        mastery.nextLevelRequirements
            .any((r) => r.description.contains('3 consecutive')),
        true,
      );
    });

    test('Eternal has empty requirements', () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.master,
          sbAttempts: 20,
          sbCorrect: 20,
          consecutivePerfectMaster: 3,
        ),
        isEternal: true,
      );
      expect(mastery.nextLevelRequirements, isEmpty);
    });
  });

  // -------------------------------------------------------
  // Aggregate stats are computed correctly
  // -------------------------------------------------------
  group('Aggregate statistics', () {
    test('overall accuracy aggregates across game types', () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.beginner,
          sbAttempts: 10,
          sbCorrect: 8,
          matchAttempts: 10,
          matchCorrect: 6,
        ),
      );
      // 14 correct / 20 total = 70%
      expect(mastery.overallAccuracy, closeTo(70.0, 0.1));
    });

    test('total attempts sums across game types', () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.beginner,
          sbAttempts: 5,
          sbCorrect: 3,
          matchAttempts: 10,
          matchCorrect: 7,
          quizAttempts: 3,
          quizCorrect: 2,
        ),
      );
      expect(mastery.totalAttemptsAllGames, 18);
      expect(mastery.gameTypesAttempted, 3);
    });

    test('consecutivePerfectMaster is passed through', () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.master,
          sbAttempts: 10,
          sbCorrect: 10,
          consecutivePerfectMaster: 2,
        ),
      );
      expect(mastery.consecutivePerfectMaster, 2);
    });
  });

  // -------------------------------------------------------
  // Edge cases
  // -------------------------------------------------------
  group('Edge cases', () {
    test('all game progress null → New with zeroed stats', () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: {
          GameType.scriptureBuilder: null,
          GameType.matching: null,
          GameType.quiz: null,
        },
      );
      expect(mastery.level, MasteryLevel.newScripture);
      expect(mastery.overallAccuracy, 0.0);
      expect(mastery.totalAttemptsAllGames, 0);
      expect(mastery.gameTypesAttempted, 0);
    });

    test('SB Master reached but 0 consecutive perfect → Memorized not Mastered',
        () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.master,
          sbAttempts: 20,
          sbCorrect: 15,
          consecutivePerfectMaster: 0,
        ),
      );
      // highestDifficulty is Master but perfect count is 0
      // Raw level check: sbRank >= 3 but perfectCount < 3 → falls through to memorized check
      // sbRank >= 2 → Memorized
      expect(mastery.level, MasteryLevel.memorized);
    });

    test('daysSinceLastPractice getter works', () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.beginner,
          sbAttempts: 5,
          sbCorrect: 4,
          lastPracticed: DateTime.now().subtract(const Duration(days: 10)),
        ),
      );
      expect(mastery.daysSinceLastPractice, closeTo(10, 1));
    });

    test('daysMastered getter works', () {
      final masteredDate = DateTime.now().subtract(const Duration(days: 45));
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.master,
          sbAttempts: 20,
          sbCorrect: 20,
          consecutivePerfectMaster: 3,
        ),
        masteredSinceDate: masteredDate,
      );
      expect(mastery.daysMastered, closeTo(45, 1));
    });
  });

  // -------------------------------------------------------
  // Mastery shortcut — skip tiers by proving Master (TASK-031)
  // -------------------------------------------------------
  group('Mastery shortcut — skip tiers', () {
    test('jumping straight to Master with 3 perfect runs → Mastered', () {
      // User has never done Beginner/Intermediate/Advanced but completed
      // Master 3 times perfectly
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.master,
          sbAttempts: 3,
          sbCorrect: 3,
          consecutivePerfectMaster: 3,
          sbExplicitDifficulties: {DifficultyLevel.master},
        ),
      );
      expect(mastery.level, MasteryLevel.mastered);
    });

    test('jumping to Master with 1 perfect run → Memorized (still needs 3)',
        () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.master,
          sbAttempts: 1,
          sbCorrect: 1,
          consecutivePerfectMaster: 1,
          sbExplicitDifficulties: {DifficultyLevel.master},
        ),
      );
      // Reached Master rank (>=3) but <3 perfect runs → falls to Memorized
      expect(mastery.level, MasteryLevel.memorized);
    });

    test('wasDifficultySkipped detects auto-credited tiers', () {
      // User only played Master, so Beginner/Intermediate/Advanced are skipped
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.master,
          sbAttempts: 3,
          sbCorrect: 3,
          consecutivePerfectMaster: 3,
          sbExplicitDifficulties: {DifficultyLevel.master},
        ),
      );
      expect(mastery.wasDifficultySkipped(DifficultyLevel.beginner), true);
      expect(mastery.wasDifficultySkipped(DifficultyLevel.intermediate), true);
      expect(mastery.wasDifficultySkipped(DifficultyLevel.advanced), true);
      expect(mastery.wasDifficultySkipped(DifficultyLevel.master), false);
    });

    test('wasDifficultySkipped returns false for explicitly completed tiers',
        () {
      // User did the whole ladder: Beginner → Intermediate → Advanced → Master
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.master,
          sbAttempts: 20,
          sbCorrect: 20,
          consecutivePerfectMaster: 3,
          sbExplicitDifficulties: {
            DifficultyLevel.beginner,
            DifficultyLevel.intermediate,
            DifficultyLevel.advanced,
            DifficultyLevel.master,
          },
        ),
      );
      expect(mastery.wasDifficultySkipped(DifficultyLevel.beginner), false);
      expect(mastery.wasDifficultySkipped(DifficultyLevel.intermediate), false);
      expect(mastery.wasDifficultySkipped(DifficultyLevel.advanced), false);
      expect(mastery.wasDifficultySkipped(DifficultyLevel.master), false);
    });

    test('wasDifficultySkipped returns false for uncredited tiers', () {
      // User only completed Beginner — Intermediate/Advanced/Master are not
      // credited, so they can't be "skipped" either.
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.beginner,
          sbAttempts: 5,
          sbCorrect: 4,
          sbExplicitDifficulties: {DifficultyLevel.beginner},
        ),
      );
      expect(mastery.wasDifficultySkipped(DifficultyLevel.beginner), false);
      expect(mastery.wasDifficultySkipped(DifficultyLevel.intermediate), false);
      expect(mastery.wasDifficultySkipped(DifficultyLevel.advanced), false);
      expect(mastery.wasDifficultySkipped(DifficultyLevel.master), false);
    });

    test('partial shortcut: user skips to Advanced, Beginner/Intermediate auto-credited',
        () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.advanced,
          sbAttempts: 5,
          sbCorrect: 4,
          sbExplicitDifficulties: {DifficultyLevel.advanced},
        ),
      );
      expect(mastery.level, MasteryLevel.memorized);
      expect(mastery.wasDifficultySkipped(DifficultyLevel.beginner), true);
      expect(mastery.wasDifficultySkipped(DifficultyLevel.intermediate), true);
      expect(mastery.wasDifficultySkipped(DifficultyLevel.advanced), false);
    });

    test('explicitlyCompletedSbDifficulties is passed through to ScriptureMastery',
        () {
      final mastery = ScriptureMastery.compute(
        scriptureId: 'test-1',
        progressByGame: makeProgress(
          sbDifficulty: DifficultyLevel.master,
          sbAttempts: 3,
          sbCorrect: 3,
          consecutivePerfectMaster: 3,
          sbExplicitDifficulties: {DifficultyLevel.master},
        ),
      );
      expect(mastery.explicitlyCompletedSbDifficulties, {DifficultyLevel.master});
    });
  });
}
