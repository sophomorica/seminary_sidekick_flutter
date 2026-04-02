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

/// Holistic mastery for a single scripture, driven by Word Builder progression.
///
/// The mastery path is linear and tied to Word Builder difficulty tiers:
///   New → Learning → Familiar → Memorized → Mastered → Eternal
///
/// - **New**: Haven't started Word Builder
/// - **Learning**: Completed Word Builder Beginner (tap 3-word chunks)
/// - **Familiar**: Completed Word Builder Intermediate (tap 2-word chunks + distractors)
/// - **Memorized**: Completed Word Builder Advanced (typed with first-letter hints)
/// - **Mastered**: 3 consecutive perfect completions at Word Builder Master (blind typing)
/// - **Eternal**: Maintained Mastered for 6 continuous months (permanent, no decay)
///
/// Scripture Match and Quiz are helpful recognition tools but do NOT gate mastery.
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
  /// Empty if already at Eternal.
  final List<MasteryRequirement> nextLevelRequirements;

  /// Number of game types that have at least one attempt.
  final int gameTypesAttempted;

  /// Number of game types with at least one correct attempt.
  final int gameTypesWithCorrect;

  /// When the scripture first reached Mastered level (for Eternal tracking).
  final DateTime? masteredSince;

  /// Consecutive perfect completions at Word Builder Master difficulty.
  final int consecutivePerfectMaster;

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
    this.consecutivePerfectMaster = 0,
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
  /// The mastery level is driven entirely by Word Builder progression:
  ///   - Learning: completed WB Beginner
  ///   - Familiar: completed WB Intermediate
  ///   - Memorized: completed WB Advanced
  ///   - Mastered: 3 consecutive perfect completions at WB Master
  ///   - Eternal: 6 months sustained at Mastered (permanent)
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

    // Extract Word Builder progress (the primary mastery driver)
    final wbProgress = progressByGame[GameType.wordOrder];
    final wbDifficultyRank =
        _difficultyRank(highestDifficulty[GameType.wordOrder]);
    final perfectMasterCount = wbProgress?.consecutivePerfectMaster ?? 0;

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
        consecutivePerfectMaster: perfectMasterCount,
      );
    }

    // Determine raw mastery level from Word Builder progression
    final rawLevel = _computeRawLevel(
      wbDifficultyRank: wbDifficultyRank,
      perfectMasterCount: perfectMasterCount,
    );

    // Apply gentle decay
    final decayedLevel = _applyDecay(rawLevel, daysSince);

    // Needs review: practiced before but >14 days ago
    final needsReview =
        lastPracticed != null && daysSince != null && daysSince > 14;

    // Compute sub-progress and requirements toward the next level
    final nextLevel = _nextLevel(decayedLevel);
    final requirements = nextLevel != null
        ? _requirementsFor(
            nextLevel,
            wbDifficultyRank: wbDifficultyRank,
            perfectMasterCount: perfectMasterCount,
            masteredSinceDate: masteredSinceDate,
          )
        : <MasteryRequirement>[];

    // If we're at mastered and need review, show maintenance requirements
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
      consecutivePerfectMaster: perfectMasterCount,
    );
  }

  // ---------------------------------------------------------------------------
  // Level computation — Word Builder-centric linear path
  // ---------------------------------------------------------------------------

  /// Determine mastery level purely from Word Builder progression.
  ///
  /// - Mastered: completed WB Master + 3 consecutive perfect runs at Master
  /// - Memorized: completed WB Advanced (rank >= 2)
  /// - Familiar: completed WB Intermediate (rank >= 1)
  /// - Learning: completed WB Beginner (rank >= 0, i.e. has any WB progress)
  /// - New: no Word Builder progress at all
  static MasteryLevel _computeRawLevel({
    required int wbDifficultyRank,
    required int perfectMasterCount,
  }) {
    // Mastered: reached WB Master difficulty AND 3 consecutive perfect runs
    if (wbDifficultyRank >= 3 && perfectMasterCount >= 3) {
      return MasteryLevel.mastered;
    }

    // Memorized: completed WB Advanced
    if (wbDifficultyRank >= 2) {
      return MasteryLevel.memorized;
    }

    // Familiar: completed WB Intermediate
    if (wbDifficultyRank >= 1) {
      return MasteryLevel.familiar;
    }

    // Learning: completed WB Beginner (any WB attempt that reached beginner)
    if (wbDifficultyRank >= 0) {
      return MasteryLevel.learning;
    }

    return MasteryLevel.newScripture;
  }

  // ---------------------------------------------------------------------------
  // Decay
  // ---------------------------------------------------------------------------

  /// Gentle decay: after 30 days without practice, drop one tier.
  /// Floor at Familiar — time alone never drops below Familiar.
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
    required int wbDifficultyRank,
    required int perfectMasterCount,
    DateTime? masteredSinceDate,
  }) {
    switch (targetLevel) {
      case MasteryLevel.learning:
        return [
          MasteryRequirement(
            description: 'Complete Word Builder on Beginner',
            isMet: wbDifficultyRank >= 0,
            progress: wbDifficultyRank >= 0 ? 1.0 : 0.0,
          ),
        ];

      case MasteryLevel.familiar:
        return [
          MasteryRequirement(
            description: 'Complete Word Builder on Intermediate',
            isMet: wbDifficultyRank >= 1,
            progress: wbDifficultyRank >= 1
                ? 1.0
                : (wbDifficultyRank >= 0 ? 0.5 : 0.0),
          ),
        ];

      case MasteryLevel.memorized:
        return [
          MasteryRequirement(
            description: 'Complete Word Builder on Advanced',
            isMet: wbDifficultyRank >= 2,
            progress: wbDifficultyRank >= 2
                ? 1.0
                : (wbDifficultyRank + 1).clamp(0, 2) / 2,
          ),
        ];

      case MasteryLevel.mastered:
        final reachedMaster = wbDifficultyRank >= 3;
        return [
          MasteryRequirement(
            description: 'Reach Word Builder Master difficulty',
            isMet: reachedMaster,
            progress: reachedMaster
                ? 1.0
                : (wbDifficultyRank + 1).clamp(0, 3) / 3,
          ),
          MasteryRequirement(
            description:
                '3 consecutive perfect runs at Master ($perfectMasterCount/3)',
            isMet: perfectMasterCount >= 3,
            progress: (perfectMasterCount / 3).clamp(0.0, 1.0),
          ),
        ];

      case MasteryLevel.eternal:
        // Show Eternal requirements when at Mastered level
        final daysMastered = masteredSinceDate != null
            ? DateTime.now().difference(masteredSinceDate).inDays
            : 0;
        return [
          MasteryRequirement(
            description: 'Maintain Mastered for 6 months ($daysMastered/183 days)',
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
