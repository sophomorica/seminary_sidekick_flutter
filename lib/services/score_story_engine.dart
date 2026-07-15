import 'package:flutter/material.dart';

import '../models/enums.dart';

/// Word grade shown on the solo results meter (replaces stars on that screen).
enum ScoreGrade {
  masterful('Masterful'),
  strong('Strong'),
  gettingThere('Getting there'),
  keepPracticing('Keep practicing');

  const ScoreGrade(this.label);
  final String label;
}

/// One beat in the animated score story sequence.
class ScoreEvent {
  final String label;
  final int points;
  final bool isMiss;
  final IconData icon;

  const ScoreEvent({
    required this.label,
    required this.points,
    required this.isMiss,
    required this.icon,
  });

  String get signedPoints {
    if (points > 0) return '+$points';
    return '$points';
  }
}

/// Ordered events + clamped final score for the results meter.
class ScoreStory {
  final List<ScoreEvent> events;
  final int finalScore;
  final ScoreGrade grade;

  const ScoreStory({
    required this.events,
    required this.finalScore,
    required this.grade,
  });

  bool get isMasterful => grade == ScoreGrade.masterful;
}

/// Display-only scoring for the game-complete "score story".
///
/// Consumes the same fields [GameResultsScreen] already receives. Does not
/// write mastery/progress and does not invent untracked stats (no streak).
class ScoreStoryEngine {
  ScoreStoryEngine._();

  static const int maxScore = 1000;
  static const int maxAccuracyPoints = 600;
  static const int maxSpeedPoints = 250;
  static const int finishBonusPoints = 150;
  static const int flawlessBonusPoints = 50;
  static const int missPenaltyPer = 20;
  static const int maxMissPenalty = 150;

  /// Generous par times (seconds) per game type × difficulty. Tune later.
  static const Map<GameType, Map<DifficultyLevel, int>> parSeconds = {
    GameType.matching: {
      DifficultyLevel.beginner: 90,
      DifficultyLevel.intermediate: 150,
      DifficultyLevel.advanced: 240,
      DifficultyLevel.master: 360,
    },
    GameType.quiz: {
      DifficultyLevel.beginner: 120,
      DifficultyLevel.intermediate: 240,
      DifficultyLevel.advanced: 360,
      DifficultyLevel.master: 480,
    },
    GameType.scriptureBuilder: {
      DifficultyLevel.beginner: 60,
      DifficultyLevel.intermediate: 90,
      DifficultyLevel.advanced: 120,
      DifficultyLevel.master: 180,
    },
  };

  static ScoreStory build({
    required GameType gameType,
    required DifficultyLevel difficulty,
    required int correctMatches,
    required int incorrectAttempts,
    required int totalPairs,
    required Duration completionTime,
  }) {
    final events = <ScoreEvent>[];

    final accuracyPoints = _accuracyPoints(
      correctMatches: correctMatches,
      incorrectAttempts: incorrectAttempts,
    );
    events.add(
      ScoreEvent(
        label: 'Accuracy',
        points: accuracyPoints,
        isMiss: false,
        icon: Icons.gps_fixed,
      ),
    );

    final speedPoints = _speedPoints(
      gameType: gameType,
      difficulty: difficulty,
      completionTime: completionTime,
    );
    events.add(
      ScoreEvent(
        label: 'Speed bonus',
        points: speedPoints,
        isMiss: false,
        icon: Icons.bolt_outlined,
      ),
    );

    if (incorrectAttempts == 0) {
      events.add(
        const ScoreEvent(
          label: 'Flawless',
          points: flawlessBonusPoints,
          isMiss: false,
          icon: Icons.auto_awesome,
        ),
      );
    } else {
      final missPoints = _missPoints(incorrectAttempts);
      events.add(
        ScoreEvent(
          label: 'Misses',
          points: missPoints,
          isMiss: true,
          icon: Icons.close,
        ),
      );
    }

    events.add(
      const ScoreEvent(
        label: 'Finish bonus',
        points: finishBonusPoints,
        isMiss: false,
        icon: Icons.flag_outlined,
      ),
    );

    final rawTotal = events.fold<int>(0, (sum, e) => sum + e.points);
    final finalScore = rawTotal.clamp(0, maxScore);
    final grade = gradeForScore(finalScore);

    return ScoreStory(
      events: List.unmodifiable(events),
      finalScore: finalScore,
      grade: grade,
    );
  }

  /// Compressed 2–3 event story for Group Play quiz (accuracy / speed / misses).
  ///
  /// [rawScore] is the local player's already speed-weighted quiz total;
  /// [maxPossible] normalizes it toward a 0–1000 meter (typically
  /// `questionCount * 1000`).
  static ScoreStory buildGroupQuiz({
    required int rawScore,
    required int maxPossible,
    required int correctCount,
    required int incorrectCount,
    required int questionCount,
  }) {
    final safeMax = maxPossible <= 0 ? maxScore : maxPossible;
    final normalized =
        ((rawScore / safeMax) * maxScore).round().clamp(0, maxScore);

    final accuracyShare = questionCount <= 0
        ? 0.0
        : (correctCount / questionCount).clamp(0.0, 1.0);
    // Aim ~65% of the meter at accuracy, remainder at speed; misses knock
    // mid-sequence then we land on [normalized] as the final score.
    final provisionalAccuracy =
        (normalized * 0.65 * (0.5 + 0.5 * accuracyShare)).round();
    final provisionalSpeed =
        (normalized - provisionalAccuracy).clamp(0, maxScore);

    final events = <ScoreEvent>[
      ScoreEvent(
        label: 'Accuracy',
        points: provisionalAccuracy,
        isMiss: false,
        icon: Icons.gps_fixed,
      ),
      ScoreEvent(
        label: 'Speed',
        points: provisionalSpeed,
        isMiss: false,
        icon: Icons.bolt_outlined,
      ),
    ];

    if (incorrectCount > 0) {
      events.add(
        ScoreEvent(
          label: 'Misses',
          points: _missPoints(incorrectCount),
          isMiss: true,
          icon: Icons.close,
        ),
      );
    }

    final playable = events.where((e) => e.points != 0 || e.isMiss).toList();
    final adjusted = _adjustEventsToFinal(
      playable.isEmpty
          ? [
              ScoreEvent(
                label: 'Score',
                points: normalized,
                isMiss: false,
                icon: Icons.star_outline,
              ),
            ]
          : playable,
      normalized,
    );

    return ScoreStory(
      events: List.unmodifiable(adjusted),
      finalScore: normalized,
      grade: gradeForScore(normalized),
    );
  }

  static List<ScoreEvent> _adjustEventsToFinal(
    List<ScoreEvent> events,
    int targetFinal,
  ) {
    final mutable = List<ScoreEvent>.from(events);
    final missTotal = mutable
        .where((e) => e.isMiss)
        .fold<int>(0, (sum, e) => sum + e.points);
    final gainBudget = (targetFinal - missTotal).clamp(0, maxScore);

    var gainSum = mutable
        .where((e) => !e.isMiss)
        .fold<int>(0, (sum, e) => sum + e.points);
    if (gainSum == 0) {
      return [
        ScoreEvent(
          label: 'Score',
          points: targetFinal,
          isMiss: false,
          icon: Icons.star_outline,
        ),
        ...mutable.where((e) => e.isMiss),
      ];
    }

    // Scale gains so gains + misses ≈ target; keep miss events intact.
    final scale = gainBudget / gainSum;
    var allocated = 0;
    final gainIndexes = <int>[];
    for (var i = 0; i < mutable.length; i++) {
      if (!mutable[i].isMiss) gainIndexes.add(i);
    }
    for (var g = 0; g < gainIndexes.length; g++) {
      final i = gainIndexes[g];
      final isLast = g == gainIndexes.length - 1;
      final points = isLast
          ? (gainBudget - allocated).clamp(0, maxScore)
          : (mutable[i].points * scale).round().clamp(0, maxScore);
      allocated += points;
      mutable[i] = ScoreEvent(
        label: mutable[i].label,
        points: points,
        isMiss: false,
        icon: mutable[i].icon,
      );
    }
    return mutable;
  }

  static int _accuracyPoints({
    required int correctMatches,
    required int incorrectAttempts,
  }) {
    final denom = correctMatches + incorrectAttempts;
    if (denom <= 0) return 0;
    return (maxAccuracyPoints * correctMatches / denom).round();
  }

  static int _speedPoints({
    required GameType gameType,
    required DifficultyLevel difficulty,
    required Duration completionTime,
  }) {
    final par = parSeconds[gameType]?[difficulty] ?? 120;
    final seconds = completionTime.inMilliseconds / 1000.0;
    if (seconds <= par) return maxSpeedPoints;
    // Linear falloff to 0 at 2.5× par (generous).
    final window = par * 1.5;
    final ratio = (1.0 - ((seconds - par) / window)).clamp(0.0, 1.0);
    return (maxSpeedPoints * ratio).round();
  }

  static int _missPoints(int incorrectAttempts) {
    final raw = -missPenaltyPer * incorrectAttempts;
    return raw < -maxMissPenalty ? -maxMissPenalty : raw;
  }

  static ScoreGrade gradeForScore(int score) {
    if (score >= 900) return ScoreGrade.masterful;
    if (score >= 750) return ScoreGrade.strong;
    if (score >= 500) return ScoreGrade.gettingThere;
    return ScoreGrade.keepPracticing;
  }
}
