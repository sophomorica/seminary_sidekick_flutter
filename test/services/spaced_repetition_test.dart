import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/services/spaced_repetition.dart';
import 'package:seminary_sidekick/models/enums.dart';

void main() {
  group('SpacedRepetitionData', () {
    test('defaults', () {
      final data = SpacedRepetitionData(nextReviewDate: DateTime(2026, 4, 9));
      expect(data.easeFactor, 2.5);
      expect(data.intervalDays, 0);
      expect(data.repetitions, 0);
      expect(data.lastReviewDate, isNull);
    });

    test('isDue returns true when past due date', () {
      final data = SpacedRepetitionData(
        nextReviewDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(data.isDue, true);
    });

    test('isDue returns true when approximately now (within 1 hour)', () {
      final data = SpacedRepetitionData(
        nextReviewDate: DateTime.now(),
      );
      expect(data.isDue, true);
    });

    test('isDue returns false when far in the future', () {
      final data = SpacedRepetitionData(
        nextReviewDate: DateTime.now().add(const Duration(days: 7)),
      );
      expect(data.isDue, false);
    });

    test('daysOverdue is positive when past due', () {
      final data = SpacedRepetitionData(
        nextReviewDate: DateTime.now().subtract(const Duration(days: 5)),
      );
      expect(data.daysOverdue, greaterThanOrEqualTo(4));
    });

    test('daysOverdue is negative when not yet due', () {
      final data = SpacedRepetitionData(
        nextReviewDate: DateTime.now().add(const Duration(days: 5)),
      );
      expect(data.daysOverdue, lessThan(0));
    });

    test('priority is 0 when not overdue', () {
      final data = SpacedRepetitionData(
        nextReviewDate: DateTime.now().add(const Duration(days: 3)),
      );
      expect(data.priority, 0.0);
    });

    test('priority increases when overdue', () {
      final data = SpacedRepetitionData(
        nextReviewDate: DateTime.now().subtract(const Duration(days: 10)),
        easeFactor: 2.0,
      );
      expect(data.priority, greaterThan(0.0));
    });

    test('priority higher for lower ease (harder cards)', () {
      final easyCard = SpacedRepetitionData(
        nextReviewDate: DateTime.now().subtract(const Duration(days: 5)),
        easeFactor: 2.5,
      );
      final hardCard = SpacedRepetitionData(
        nextReviewDate: DateTime.now().subtract(const Duration(days: 5)),
        easeFactor: 1.3,
      );
      expect(hardCard.priority, greaterThan(easyCard.priority));
    });

    group('JSON serialization', () {
      test('toJson roundtrip', () {
        final original = SpacedRepetitionData(
          easeFactor: 2.3,
          intervalDays: 12,
          repetitions: 4,
          nextReviewDate: DateTime(2026, 5, 1),
          lastReviewDate: DateTime(2026, 4, 19),
        );
        final parsed = SpacedRepetitionData.fromJson(original.toJson());

        expect(parsed.easeFactor, 2.3);
        expect(parsed.intervalDays, 12);
        expect(parsed.repetitions, 4);
        expect(parsed.nextReviewDate, DateTime(2026, 5, 1));
        expect(parsed.lastReviewDate, DateTime(2026, 4, 19));
      });

      test('fromJson with missing fields uses defaults', () {
        final data = SpacedRepetitionData.fromJson({});
        expect(data.easeFactor, 2.5);
        expect(data.intervalDays, 0);
        expect(data.repetitions, 0);
        expect(data.lastReviewDate, isNull);
      });
    });

    test('copyWith', () {
      final original = SpacedRepetitionData(
        easeFactor: 2.0,
        intervalDays: 6,
        repetitions: 2,
        nextReviewDate: DateTime(2026, 4, 15),
      );
      final copy = original.copyWith(easeFactor: 2.3, repetitions: 3);
      expect(copy.easeFactor, 2.3);
      expect(copy.repetitions, 3);
      expect(copy.intervalDays, 6); // unchanged
    });
  });

  group('SpacedRepetition', () {
    group('initial', () {
      test('creates fresh data with default ease', () {
        final data = SpacedRepetition.initial();
        expect(data.easeFactor, 2.5);
        expect(data.intervalDays, 0);
        expect(data.repetitions, 0);
      });
    });

    group('computeQuality', () {
      test('incorrect with low accuracy returns 0', () {
        final q = SpacedRepetition.computeQuality(
          correct: false,
          accuracy: 10.0,
          gameType: GameType.matching,
        );
        expect(q, 0);
      });

      test('incorrect with moderate accuracy returns 1', () {
        final q = SpacedRepetition.computeQuality(
          correct: false,
          accuracy: 40.0,
          gameType: GameType.matching,
        );
        expect(q, 1);
      });

      test('incorrect with high accuracy returns 2', () {
        final q = SpacedRepetition.computeQuality(
          correct: false,
          accuracy: 65.0,
          gameType: GameType.matching,
        );
        expect(q, 2);
      });

      test('correct with low accuracy returns 3', () {
        final q = SpacedRepetition.computeQuality(
          correct: true,
          accuracy: 70.0,
          gameType: GameType.matching,
        );
        expect(q, 3);
      });

      test('correct with good accuracy returns 4', () {
        final q = SpacedRepetition.computeQuality(
          correct: true,
          accuracy: 88.0,
          gameType: GameType.matching,
        );
        expect(q, 4);
      });

      test('correct with excellent accuracy returns 5', () {
        final q = SpacedRepetition.computeQuality(
          correct: true,
          accuracy: 96.0,
          gameType: GameType.matching,
        );
        expect(q, 5);
      });

      test('Word Builder Master with 90%+ accuracy returns 5', () {
        final q = SpacedRepetition.computeQuality(
          correct: true,
          accuracy: 92.0,
          gameType: GameType.wordOrder,
          difficulty: DifficultyLevel.master,
        );
        expect(q, 5);
      });

      test('Word Builder Advanced with 90%+ accuracy returns at least 4', () {
        final q = SpacedRepetition.computeQuality(
          correct: true,
          accuracy: 91.0,
          gameType: GameType.wordOrder,
          difficulty: DifficultyLevel.advanced,
        );
        expect(q, greaterThanOrEqualTo(4));
      });

      test('quality is always clamped 0-5', () {
        // Perfect scenario
        final high = SpacedRepetition.computeQuality(
          correct: true,
          accuracy: 100.0,
          gameType: GameType.wordOrder,
          difficulty: DifficultyLevel.master,
        );
        expect(high, lessThanOrEqualTo(5));

        // Worst scenario
        final low = SpacedRepetition.computeQuality(
          correct: false,
          accuracy: 0.0,
          gameType: GameType.matching,
        );
        expect(low, greaterThanOrEqualTo(0));
      });
    });

    group('review (SM-2 algorithm)', () {
      final baseTime = DateTime(2026, 4, 9, 12, 0, 0);

      test('first successful review sets interval to 1 day', () {
        final initial = SpacedRepetition.initial();
        final result = SpacedRepetition.review(initial, 4, now: baseTime);

        expect(result.repetitions, 1);
        expect(result.intervalDays, 1);
        expect(result.lastReviewDate, baseTime);
        expect(result.nextReviewDate, baseTime.add(const Duration(days: 1)));
      });

      test('second successful review sets interval to 6 days', () {
        final afterFirst = SpacedRepetitionData(
          easeFactor: 2.5,
          intervalDays: 1,
          repetitions: 1,
          nextReviewDate: baseTime,
          lastReviewDate: baseTime.subtract(const Duration(days: 1)),
        );
        final result = SpacedRepetition.review(afterFirst, 4, now: baseTime);

        expect(result.repetitions, 2);
        expect(result.intervalDays, 6);
      });

      test('third+ successful reviews multiply interval by ease factor', () {
        final afterSecond = SpacedRepetitionData(
          easeFactor: 2.5,
          intervalDays: 6,
          repetitions: 2,
          nextReviewDate: baseTime,
        );
        final result = SpacedRepetition.review(afterSecond, 4, now: baseTime);

        expect(result.repetitions, 3);
        // 6 * 2.5 = 15
        expect(result.intervalDays, 15);
      });

      test('failed review (quality < 3) resets repetitions and interval', () {
        final good = SpacedRepetitionData(
          easeFactor: 2.5,
          intervalDays: 30,
          repetitions: 5,
          nextReviewDate: baseTime,
        );
        final result = SpacedRepetition.review(good, 1, now: baseTime);

        expect(result.repetitions, 0);
        expect(result.intervalDays, 1);
      });

      test('ease factor decreases on poor performance', () {
        final initial = SpacedRepetitionData(
          easeFactor: 2.5,
          intervalDays: 1,
          repetitions: 1,
          nextReviewDate: baseTime,
        );
        // Quality 3 (just passing) should lower ease
        final result = SpacedRepetition.review(initial, 3, now: baseTime);
        expect(result.easeFactor, lessThan(2.5));
      });

      test('ease factor increases on excellent performance', () {
        final initial = SpacedRepetitionData(
          easeFactor: 2.0,
          intervalDays: 6,
          repetitions: 2,
          nextReviewDate: baseTime,
        );
        final result = SpacedRepetition.review(initial, 5, now: baseTime);
        expect(result.easeFactor, greaterThan(2.0));
      });

      test('ease factor has a floor of 1.3', () {
        final data = SpacedRepetitionData(
          easeFactor: 1.3,
          intervalDays: 1,
          repetitions: 0,
          nextReviewDate: baseTime,
        );
        final result = SpacedRepetition.review(data, 0, now: baseTime);
        expect(result.easeFactor, greaterThanOrEqualTo(1.3));
      });

      test('interval capped at 180 days', () {
        final data = SpacedRepetitionData(
          easeFactor: 2.5,
          intervalDays: 100,
          repetitions: 10,
          nextReviewDate: baseTime,
        );
        final result = SpacedRepetition.review(data, 5, now: baseTime);
        expect(result.intervalDays, lessThanOrEqualTo(180));
      });

      test('progressive interval growth', () {
        var data = SpacedRepetition.initial();
        var reviewTime = baseTime;
        final intervals = <int>[];

        // Simulate 5 perfect reviews
        for (var i = 0; i < 5; i++) {
          data = SpacedRepetition.review(data, 5, now: reviewTime);
          intervals.add(data.intervalDays);
          reviewTime = data.nextReviewDate;
        }

        // Each interval should be >= the previous one
        for (var i = 1; i < intervals.length; i++) {
          expect(intervals[i], greaterThanOrEqualTo(intervals[i - 1]),
              reason:
                  'Interval $i (${intervals[i]}) should be >= interval ${i - 1} (${intervals[i - 1]})');
        }
      });
    });
  });
}
