/// Spaced Repetition Service — SM-2 algorithm adapted for scripture memorization.
///
/// The SM-2 algorithm computes optimal review intervals based on how well
/// the user performed. Good performance → longer intervals. Poor → shorter.
///
/// Key concepts:
/// - **easeFactor**: 1.3–2.5+, starts at 2.5. Represents how "easy" a card is.
///   Higher = easier = longer intervals. Drops on poor performance.
/// - **interval**: Days until next review. Grows exponentially with good reviews.
/// - **quality**: 0–5 rating of user performance per attempt.
///   - 5: Perfect, no hesitation
///   - 4: Correct with slight hesitation
///   - 3: Correct with difficulty
///   - 2: Incorrect but close (recalled after seeing answer)
///   - 1: Incorrect, vague memory
///   - 0: Complete blank
///
/// Adaptation for this app:
/// - Quality is derived from accuracy, time, and difficulty level.
/// - Word Builder performance carries more weight (it's the mastery tool).
/// - Each scripture has ONE spaced repetition schedule (not per-game).
library;

import '../models/enums.dart';

/// Immutable snapshot of a scripture's spaced repetition state.
class SpacedRepetitionData {
  /// SM-2 ease factor (1.3 minimum, starts at 2.5).
  final double easeFactor;

  /// Current interval in days until next review.
  final int intervalDays;

  /// Number of consecutive successful reviews (quality >= 3).
  final int repetitions;

  /// When this scripture should next be reviewed.
  final DateTime nextReviewDate;

  /// When this scripture was last reviewed.
  final DateTime? lastReviewDate;

  const SpacedRepetitionData({
    this.easeFactor = 2.5,
    this.intervalDays = 0,
    this.repetitions = 0,
    required this.nextReviewDate,
    this.lastReviewDate,
  });

  /// True if this scripture is due for review (now or overdue).
  bool get isDue => DateTime.now().isAfter(nextReviewDate) ||
      DateTime.now().difference(nextReviewDate).inHours.abs() < 1;

  /// How many days overdue (negative if not yet due).
  int get daysOverdue =>
      DateTime.now().difference(nextReviewDate).inDays;

  /// Priority score for sorting review queue. Higher = more urgent.
  /// Overdue items get higher priority; newer items with low ease also rank up.
  double get priority {
    final overdue = daysOverdue;
    if (overdue <= 0) return 0.0;
    // Overdue days weighted by inverse ease (harder cards more urgent)
    return overdue * (3.0 - easeFactor.clamp(1.3, 2.5));
  }

  Map<String, dynamic> toJson() => {
        'easeFactor': easeFactor,
        'intervalDays': intervalDays,
        'repetitions': repetitions,
        'nextReviewDate': nextReviewDate.toIso8601String(),
        'lastReviewDate': lastReviewDate?.toIso8601String(),
      };

  factory SpacedRepetitionData.fromJson(Map<String, dynamic> json) {
    return SpacedRepetitionData(
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      intervalDays: (json['intervalDays'] as int?) ?? 0,
      repetitions: (json['repetitions'] as int?) ?? 0,
      nextReviewDate: json['nextReviewDate'] != null
          ? DateTime.parse(json['nextReviewDate'] as String)
          : DateTime.now(),
      lastReviewDate: json['lastReviewDate'] != null
          ? DateTime.parse(json['lastReviewDate'] as String)
          : null,
    );
  }

  SpacedRepetitionData copyWith({
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    DateTime? nextReviewDate,
    DateTime? lastReviewDate,
  }) {
    return SpacedRepetitionData(
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      lastReviewDate: lastReviewDate ?? this.lastReviewDate,
    );
  }
}

/// Pure functions implementing the SM-2 algorithm.
class SpacedRepetition {
  SpacedRepetition._();

  /// Create initial SR data for a scripture that's never been reviewed.
  static SpacedRepetitionData initial() {
    return SpacedRepetitionData(
      nextReviewDate: DateTime.now(),
    );
  }

  /// Convert game performance into an SM-2 quality score (0–5).
  ///
  /// Factors:
  /// - [correct]: Did they get it right?
  /// - [accuracy]: Overall accuracy percentage (0–100)
  /// - [gameType]: Word Builder weighs more heavily
  /// - [difficulty]: Higher difficulty = more credit for correct answers
  /// - [timeSeconds]: How long it took (optional, for bonus credit)
  static int computeQuality({
    required bool correct,
    required double accuracy,
    required GameType gameType,
    DifficultyLevel? difficulty,
    int? timeSeconds,
  }) {
    if (!correct) {
      // Incorrect — low quality
      if (accuracy >= 60) return 2; // Close, some memory
      if (accuracy >= 30) return 1; // Vague memory
      return 0; // Complete blank
    }

    // Correct — base quality on accuracy and difficulty
    int quality = 3; // Baseline for correct

    // Accuracy bonus
    if (accuracy >= 95) {
      quality = 5;
    } else if (accuracy >= 85) {
      quality = 4;
    }

    // Word Builder at higher difficulties deserves more credit
    if (gameType == GameType.wordOrder) {
      if (difficulty == DifficultyLevel.master && accuracy >= 90) {
        quality = 5;
      } else if (difficulty == DifficultyLevel.advanced && accuracy >= 90) {
        quality = quality < 4 ? 4 : quality;
      }
    }

    return quality.clamp(0, 5);
  }

  /// Run one step of the SM-2 algorithm and return updated data.
  ///
  /// [current]: The scripture's current SR state.
  /// [quality]: 0–5 performance rating from [computeQuality].
  /// [now]: Override for testability; defaults to DateTime.now().
  static SpacedRepetitionData review(
    SpacedRepetitionData current,
    int quality, {
    DateTime? now,
  }) {
    final reviewTime = now ?? DateTime.now();

    // SM-2 ease factor update:
    // EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
    double newEase = current.easeFactor +
        (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    // Floor at 1.3
    if (newEase < 1.3) newEase = 1.3;

    int newRepetitions;
    int newInterval;

    if (quality < 3) {
      // Failed review — reset to beginning
      newRepetitions = 0;
      newInterval = 1; // Review again tomorrow
    } else {
      // Successful review — extend interval
      newRepetitions = current.repetitions + 1;

      if (newRepetitions == 1) {
        newInterval = 1; // First successful review: 1 day
      } else if (newRepetitions == 2) {
        newInterval = 6; // Second: 6 days
      } else {
        // Subsequent: previous interval × ease factor
        newInterval = (current.intervalDays * newEase).round();
      }
    }

    // Cap at 180 days (6 months) — beyond that, Eternal takes over
    if (newInterval > 180) newInterval = 180;

    final nextReview = reviewTime.add(Duration(days: newInterval));

    return SpacedRepetitionData(
      easeFactor: newEase,
      intervalDays: newInterval,
      repetitions: newRepetitions,
      nextReviewDate: nextReview,
      lastReviewDate: reviewTime,
    );
  }
}
