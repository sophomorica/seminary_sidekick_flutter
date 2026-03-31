import 'enums.dart';
import 'user_progress.dart';

/// A single requirement for reaching a mastery level.
///
/// Used in the UI to show a checklist of what's been met and what's next.
class MasteryRequirement {
  final String description;
  final bool isMet;

  /// 0.0–1.0 for proportional requirements (accuracy, attempt count).
  /// For binary requirements, this is 0.0 or 1.0.
  final double progress;

  const MasteryRequirement({
    required this.description,
    required this.isMet,
    required this.progress,
  });
}

/// Holistic mastery for a single scripture, computed across all game types.
///
/// This is never stored — it's derived from the per-game [UserProgress]
/// records each time the provider recomputes.
class ScriptureMastery {
  final String scriptureId;
  final MasteryLevel level;

  /// 0.0–1.0 progress toward the next level.
  final double subProgress;

  /// True if the scripture hasn't been practiced recently enough.
  /// Always false for Eternal scriptures.
  final bool needsReview;

  /// Most recent practice timestamp across all game types.
  final DateTime? lastPracticedAny;

  /// Highest difficulty completed per game type.
  final Map<GameType, DifficultyLevel> highestDifficultyPerGame;

  /// Accuracy aggregated across all game types for this scripture.
  final double overallAccuracy;

  /// Total attempts summed across all game types.
  final int totalAttemptsAllGames;

  /// The requirements for the NEXT level (for the UI checklist).
  /// Empty if already at Eternal, or at Mastered with no pending requirements.
  final List<MasteryRequirement> nextLevelRequirements;

  /// Number of game types that have at least one attempt.
  final int gameTypesAttempted;

  /// Number of game types with at least one correct attempt.
  final int gameTypesWithCorrect;

  /// When the scripture first reached Mastered level (for Eternal tracking).
  final DateTime? masteredSince;

  const ScriptureMastery({
    required this.scriptureId,
    required this.level,
    required this.subProgress,
    required this.needsReview,
    required this.lastPracticedAny,
    required this.highestDifficultyPerGame,
    required this.overallAccuracy,
    required this.totalAttemptsAllGames,
    required this.nextLevelRequirements,
    required this.gameTypesAttempted,
    required this.gameTypesWithCorrect,
    this.masteredSince,
  });

  /// Days since last practice, or null if never practiced.
  int? get daysSinceLastPractice {
    if (lastPracticedAny == null) return null;
    return DateTime.now().difference(lastPracticedAny!).inDays;
  }

  /// Days of sustained mastery, or null if not yet mastered.
  int? get daysMastered {
    if (masteredSince == null) return null;
    return DateTime.now().difference(masteredSince!).inDays;
  }

  /// Compute holistic mastery from per-game progress records.
  ///
  /// [progressByGame] maps GameType → UserProgress? for a single scripture.
  /// [isEternal] is true if the mastery_dates provider has confirmed permanent
  /// Eternal status (6 months sustained mastery).
  /// [masteredSinceDate] is when the scripture first reached Mastered level.
  factory ScriptureMastery.compute({
    required String scriptureId,
    required Map<GameType, UserProgress?> progressByGame,
    bool isEternal = false,
    DateTime? masteredSinceDate,
  }) {
    // Aggregate raw stats across all game types
    int totalAttempts = 0;
    int totalCorrect = 0;
    DateTime? lastPracticed;
    final highestDifficulty = <GameType, DifficultyLevel>{};
    int gameTypesAttempted = 0;
    int gameTypesWithCorrect = 0;

    for (final entry in progressByGame.entries) {
      final progress = entry.value;
      if (progress == null) continue;

      if (progress.totalAttempts > 0) {
        gameTypesAttempted++;
        totalAttempts += progress.totalAttempts;
        totalCorrect += progress.correctAttempts;
        highestDifficulty[entry.key] = progress.highestDifficultyCompleted;

        if (progress.correctAttempts > 0) {
          gameTypesWithCorrect++;
        }

        if (progress.lastPracticed != null) {
          if (lastPracticed == null ||
              progress.lastPracticed!.isAfter(lastPracticed)) {
            lastPracticed = progress.lastPracticed;
          }
        }
      }
    }

    final overallAccuracy =
        totalAttempts > 0 ? (totalCorrect / totalAttempts) * 100 : 0.0;

    // Days since last practice
    final daysSince = lastPracticed != null
        ? DateTime.now().difference(lastPracticed).inDays
        : null;

    // ── Eternal: permanent, no decay, no review ──
    if (isEternal) {
      return ScriptureMastery(
        scriptureId: scriptureId,
        level: MasteryLevel.eternal,
        subProgress: 1.0,
        needsReview: false,
        lastPracticedAny: lastPracticed,
        highestDifficultyPerGame: highestDifficulty,
        overallAccuracy: overallAccuracy,
        totalAttemptsAllGames: totalAttempts,
        nextLevelRequirements: const [],
        gameTypesAttempted: gameTypesAttempted,
        gameTypesWithCorrect: gameTypesWithCorrect,
        masteredSince: masteredSinceDate,
      );
    }

    // Determine the raw mastery level (before decay)
    final rawLevel = _computeRawLevel(
      gameTypesAttempted: gameTypesAttempted,
      gameTypesWithCorrect: gameTypesWithCorrect,
      overallAccuracy: overallAccuracy,
      totalAttempts: totalAttempts,
      highestDifficulty: highestDifficulty,
      daysSince: daysSince,
    );

    // Apply gentle decay
    final decayedLevel = _applyDecay(rawLevel, daysSince);

    // Needs review: practiced before but >14 days ago (Mastered+ only needs this)
    final needsReview =
        lastPracticed != null && daysSince != null && daysSince > 14;

    // Compute sub-progress toward the next level
    final nextLevel = _nextLevel(decayedLevel);
    final requirements = nextLevel != null
        ? _requirementsFor(
            nextLevel,
            gameTypesAttempted: gameTypesAttempted,
            gameTypesWithCorrect: gameTypesWithCorrect,
            overallAccuracy: overallAccuracy,
            totalAttempts: totalAttempts,
            highestDifficulty: highestDifficulty,
            daysSince: daysSince,
            masteredSinceDate: masteredSinceDate,
          )
        : <MasteryRequirement>[];

    // If we're at mastered and need review, show "maintain mastery" requirements
    final displayRequirements =
        (decayedLevel == MasteryLevel.mastered && needsReview)
            ? _maintenanceRequirements(daysSince)
            : requirements;

    final subProgress = requirements.isEmpty
        ? (decayedLevel == MasteryLevel.mastered ? 1.0 : 0.0)
        : _computeSubProgress(requirements);

    return ScriptureMastery(
      scriptureId: scriptureId,
      level: decayedLevel,
      subProgress: subProgress,
      needsReview: needsReview,
      lastPracticedAny: lastPracticed,
      highestDifficultyPerGame: highestDifficulty,
      overallAccuracy: overallAccuracy,
      totalAttemptsAllGames: totalAttempts,
      nextLevelRequirements: displayRequirements,
      gameTypesAttempted: gameTypesAttempted,
      gameTypesWithCorrect: gameTypesWithCorrect,
      masteredSince: masteredSinceDate,
    );
  }

  // ---------------------------------------------------------------------------
  // Level computation
  // ---------------------------------------------------------------------------

  static MasteryLevel _computeRawLevel({
    required int gameTypesAttempted,
    required int gameTypesWithCorrect,
    required double overallAccuracy,
    required int totalAttempts,
    required Map<GameType, DifficultyLevel> highestDifficulty,
    required int? daysSince,
  }) {
    // Check Mastered (top-down) — Eternal is handled before this is called
    if (_meetsMastered(
      gameTypesWithCorrect: gameTypesWithCorrect,
      overallAccuracy: overallAccuracy,
      totalAttempts: totalAttempts,
      highestDifficulty: highestDifficulty,
      daysSince: daysSince,
    )) {
      return MasteryLevel.mastered;
    }

    if (_meetsMemorized(
      overallAccuracy: overallAccuracy,
      totalAttempts: totalAttempts,
      highestDifficulty: highestDifficulty,
      daysSince: daysSince,
    )) {
      return MasteryLevel.memorized;
    }

    if (_meetsFamiliar(
      gameTypesAttempted: gameTypesAttempted,
      overallAccuracy: overallAccuracy,
      totalAttempts: totalAttempts,
      highestDifficulty: highestDifficulty,
    )) {
      return MasteryLevel.familiar;
    }

    if (gameTypesAttempted >= 1 && gameTypesWithCorrect >= 1) {
      return MasteryLevel.learning;
    }

    return MasteryLevel.newScripture;
  }

  static bool _meetsMastered({
    required int gameTypesWithCorrect,
    required double overallAccuracy,
    required int totalAttempts,
    required Map<GameType, DifficultyLevel> highestDifficulty,
    required int? daysSince,
  }) {
    final wordBuilderMaster =
        _difficultyRank(highestDifficulty[GameType.wordOrder]) >= 3;
    final matchingAdvanced =
        _difficultyRank(highestDifficulty[GameType.matching]) >= 2;
    final quizOk = !highestDifficulty.containsKey(GameType.quiz) ||
        _difficultyRank(highestDifficulty[GameType.quiz]) >= 1;
    final accuracyOk = overallAccuracy >= 90;
    final volumeOk = totalAttempts >= 25;
    final recentOk = daysSince != null && daysSince <= 14;

    return wordBuilderMaster &&
        matchingAdvanced &&
        quizOk &&
        accuracyOk &&
        volumeOk &&
        recentOk;
  }

  static bool _meetsMemorized({
    required double overallAccuracy,
    required int totalAttempts,
    required Map<GameType, DifficultyLevel> highestDifficulty,
    required int? daysSince,
  }) {
    final wordBuilderAdvanced =
        _difficultyRank(highestDifficulty[GameType.wordOrder]) >= 2;
    final matchingIntermediate =
        _difficultyRank(highestDifficulty[GameType.matching]) >= 1;
    final accuracyOk = overallAccuracy >= 80;
    final volumeOk = totalAttempts >= 15;
    final recentOk = daysSince != null && daysSince <= 21;

    return wordBuilderAdvanced &&
        matchingIntermediate &&
        accuracyOk &&
        volumeOk &&
        recentOk;
  }

  static bool _meetsFamiliar({
    required int gameTypesAttempted,
    required double overallAccuracy,
    required int totalAttempts,
    required Map<GameType, DifficultyLevel> highestDifficulty,
  }) {
    final matchingBeginner =
        _difficultyRank(highestDifficulty[GameType.matching]) >= 0 &&
            highestDifficulty.containsKey(GameType.matching);
    final varietyOk = gameTypesAttempted >= 2;
    final accuracyOk = overallAccuracy >= 60;
    final volumeOk = totalAttempts >= 5;

    return matchingBeginner && varietyOk && accuracyOk && volumeOk;
  }

  // ---------------------------------------------------------------------------
  // Decay
  // ---------------------------------------------------------------------------

  static MasteryLevel _applyDecay(MasteryLevel rawLevel, int? daysSince) {
    if (daysSince == null) return rawLevel;
    // Eternal never decays (handled before this is called, but guard anyway)
    if (rawLevel == MasteryLevel.eternal) return rawLevel;

    if (daysSince > 30) {
      if (rawLevel == MasteryLevel.mastered) return MasteryLevel.memorized;
      if (rawLevel == MasteryLevel.memorized) return MasteryLevel.familiar;
    }

    // Floor: never drop below Familiar from time alone
    return rawLevel;
  }

  // ---------------------------------------------------------------------------
  // Requirements for next level (used for sub-progress + UI checklist)
  // ---------------------------------------------------------------------------

  static List<MasteryRequirement> _requirementsFor(
    MasteryLevel targetLevel, {
    required int gameTypesAttempted,
    required int gameTypesWithCorrect,
    required double overallAccuracy,
    required int totalAttempts,
    required Map<GameType, DifficultyLevel> highestDifficulty,
    required int? daysSince,
    DateTime? masteredSinceDate,
  }) {
    switch (targetLevel) {
      case MasteryLevel.learning:
        return [
          MasteryRequirement(
            description: 'Try any game mode',
            isMet: gameTypesAttempted >= 1,
            progress: gameTypesAttempted >= 1 ? 1.0 : 0.0,
          ),
          MasteryRequirement(
            description: 'Get at least 1 correct answer',
            isMet: gameTypesWithCorrect >= 1,
            progress: gameTypesWithCorrect >= 1 ? 1.0 : 0.0,
          ),
        ];

      case MasteryLevel.familiar:
        return [
          MasteryRequirement(
            description: 'Complete Scripture Match',
            isMet: highestDifficulty.containsKey(GameType.matching),
            progress: highestDifficulty.containsKey(GameType.matching)
                ? 1.0
                : 0.0,
          ),
          MasteryRequirement(
            description: 'Try at least 2 game modes',
            isMet: gameTypesAttempted >= 2,
            progress: (gameTypesAttempted / 2).clamp(0.0, 1.0),
          ),
          MasteryRequirement(
            description: '60%+ overall accuracy',
            isMet: overallAccuracy >= 60,
            progress: (overallAccuracy / 60).clamp(0.0, 1.0),
          ),
          MasteryRequirement(
            description: '5+ total attempts',
            isMet: totalAttempts >= 5,
            progress: (totalAttempts / 5).clamp(0.0, 1.0),
          ),
        ];

      case MasteryLevel.memorized:
        return [
          MasteryRequirement(
            description: 'Word Builder at Advanced difficulty',
            isMet: _difficultyRank(highestDifficulty[GameType.wordOrder]) >= 2,
            progress:
                (_difficultyRank(highestDifficulty[GameType.wordOrder]) / 2)
                    .clamp(0.0, 1.0),
          ),
          MasteryRequirement(
            description: 'Scripture Match at Intermediate+',
            isMet: _difficultyRank(highestDifficulty[GameType.matching]) >= 1,
            progress:
                highestDifficulty.containsKey(GameType.matching) ? 1.0 : 0.0,
          ),
          MasteryRequirement(
            description: '80%+ overall accuracy',
            isMet: overallAccuracy >= 80,
            progress: (overallAccuracy / 80).clamp(0.0, 1.0),
          ),
          MasteryRequirement(
            description: '15+ total attempts',
            isMet: totalAttempts >= 15,
            progress: (totalAttempts / 15).clamp(0.0, 1.0),
          ),
          MasteryRequirement(
            description: 'Practiced in the last 21 days',
            isMet: daysSince != null && daysSince <= 21,
            progress: daysSince != null && daysSince <= 21 ? 1.0 : 0.0,
          ),
        ];

      case MasteryLevel.mastered:
        return [
          MasteryRequirement(
            description: 'Word Builder at Master difficulty',
            isMet: _difficultyRank(highestDifficulty[GameType.wordOrder]) >= 3,
            progress:
                (_difficultyRank(highestDifficulty[GameType.wordOrder]) / 3)
                    .clamp(0.0, 1.0),
          ),
          MasteryRequirement(
            description: 'Scripture Match at Advanced+',
            isMet: _difficultyRank(highestDifficulty[GameType.matching]) >= 2,
            progress:
                (_difficultyRank(highestDifficulty[GameType.matching]) / 2)
                    .clamp(0.0, 1.0),
          ),
          MasteryRequirement(
            description: '90%+ overall accuracy',
            isMet: overallAccuracy >= 90,
            progress: (overallAccuracy / 90).clamp(0.0, 1.0),
          ),
          MasteryRequirement(
            description: '25+ total attempts',
            isMet: totalAttempts >= 25,
            progress: (totalAttempts / 25).clamp(0.0, 1.0),
          ),
          MasteryRequirement(
            description: 'Practiced in the last 14 days',
            isMet: daysSince != null && daysSince <= 14,
            progress: daysSince != null && daysSince <= 14 ? 1.0 : 0.0,
          ),
        ];

      case MasteryLevel.eternal:
        // Show Eternal requirements when at Mastered level
        final daysMastered = masteredSinceDate != null
            ? DateTime.now().difference(masteredSinceDate).inDays
            : 0;
        return [
          MasteryRequirement(
            description: 'Maintain Mastered for 6 months',
            isMet: daysMastered >= 183,
            progress: (daysMastered / 183).clamp(0.0, 1.0),
          ),
        ];

      case MasteryLevel.newScripture:
        return [];
    }
  }

  static List<MasteryRequirement> _maintenanceRequirements(int? daysSince) {
    return [
      MasteryRequirement(
        description: 'Practice to maintain mastery',
        isMet: daysSince != null && daysSince <= 14,
        progress: daysSince != null && daysSince <= 14 ? 1.0 : 0.0,
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static MasteryLevel? _nextLevel(MasteryLevel current) {
    switch (current) {
      case MasteryLevel.newScripture:
        return MasteryLevel.learning;
      case MasteryLevel.learning:
        return MasteryLevel.familiar;
      case MasteryLevel.familiar:
        return MasteryLevel.memorized;
      case MasteryLevel.memorized:
        return MasteryLevel.mastered;
      case MasteryLevel.mastered:
        return MasteryLevel.eternal;
      case MasteryLevel.eternal:
        return null;
    }
  }

  static double _computeSubProgress(List<MasteryRequirement> requirements) {
    if (requirements.isEmpty) return 0.0;
    final total =
        requirements.fold<double>(0.0, (sum, r) => sum + r.progress);
    return (total / requirements.length).clamp(0.0, 1.0);
  }

  /// Returns -1 if null (game type never played).
  static int _difficultyRank(DifficultyLevel? level) {
    if (level == null) return -1;
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
