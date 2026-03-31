import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/scripture_mastery.dart';
import '../models/user_progress.dart';
import '../providers/mastery_dates_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/scripture_provider.dart';

/// Computes holistic [ScriptureMastery] for a single scripture by aggregating
/// all per-game [UserProgress] records plus the mastery-dates persistence.
///
/// Also manages the masteredSince date tracking:
/// - When a scripture first reaches Mastered → records the date.
/// - When it drops below Mastered → clears the date.
/// - When 6 months pass at Mastered → promotes to Eternal (permanent).
///
/// Usage: `ref.watch(scriptureMasteryProvider(scriptureId))`
final scriptureMasteryProvider =
    Provider.family<ScriptureMastery, String>((ref, scriptureId) {
  // Watch the progress map so we recompute when any progress changes
  final progressMap = ref.watch(progressProvider);
  final datesNotifier = ref.read(masteryDatesProvider.notifier);

  final progressByGame = <GameType, UserProgress?>{};
  for (final gameType in GameType.values) {
    final key = '${scriptureId}_${gameType.name}';
    progressByGame[gameType] = progressMap[key];
  }

  // Check eternal status and mastered-since date
  final isEternal = datesNotifier.isEternal(scriptureId);
  final masteredSinceDate = datesNotifier.getMasteredSince(scriptureId);

  final mastery = ScriptureMastery.compute(
    scriptureId: scriptureId,
    progressByGame: progressByGame,
    isEternal: isEternal,
    masteredSinceDate: masteredSinceDate,
  );

  // Side-effect: track mastered-since dates.
  // This runs after compute so we can see what level the scripture reached.
  if (!isEternal) {
    if (mastery.level == MasteryLevel.mastered && masteredSinceDate == null) {
      // Just reached Mastered for the first time — record the date
      // Use Future.microtask to avoid modifying state during build
      Future.microtask(() => datesNotifier.markMastered(scriptureId));
    } else if (mastery.level.index < MasteryLevel.mastered.index &&
        masteredSinceDate != null) {
      // Dropped below Mastered — clear the date (clock resets)
      Future.microtask(() => datesNotifier.clearMastered(scriptureId));
    }
  }

  return mastery;
});

/// Convenience provider that returns just the holistic [MasteryLevel].
final holisticMasteryLevelProvider =
    Provider.family<MasteryLevel, String>((ref, scriptureId) {
  return ref.watch(scriptureMasteryProvider(scriptureId)).level;
});

/// Overall holistic stats across all scriptures.
class HolisticStats {
  final int totalScriptures;
  final int attempted;
  final int eternal;
  final int mastered;
  final int memorized;
  final int familiar;
  final int learning;
  final int needsReview;
  final double overallAccuracy;

  const HolisticStats({
    required this.totalScriptures,
    required this.attempted,
    required this.eternal,
    required this.mastered,
    required this.memorized,
    required this.familiar,
    required this.learning,
    required this.needsReview,
    required this.overallAccuracy,
  });
}

/// Computes holistic stats across ALL scriptures.
final holisticStatsProvider = Provider<HolisticStats>((ref) {
  final allScriptures = ref.watch(scripturesProvider);

  int attempted = 0;
  int eternal = 0;
  int mastered = 0;
  int memorized = 0;
  int familiar = 0;
  int learning = 0;
  int needsReview = 0;
  int totalCorrect = 0;
  int totalAttempts = 0;

  for (final scripture in allScriptures) {
    final mastery = ref.watch(scriptureMasteryProvider(scripture.id));

    if (mastery.level != MasteryLevel.newScripture) {
      attempted++;
    }

    switch (mastery.level) {
      case MasteryLevel.eternal:
        eternal++;
      case MasteryLevel.mastered:
        mastered++;
      case MasteryLevel.memorized:
        memorized++;
      case MasteryLevel.familiar:
        familiar++;
      case MasteryLevel.learning:
        learning++;
      case MasteryLevel.newScripture:
        break;
    }

    if (mastery.needsReview) {
      needsReview++;
    }

    // Sum raw attempts for accuracy
    totalAttempts += mastery.totalAttemptsAllGames;
    totalCorrect +=
        (mastery.overallAccuracy / 100 * mastery.totalAttemptsAllGames).round();
  }

  final overallAccuracy =
      totalAttempts > 0 ? (totalCorrect / totalAttempts) * 100 : 0.0;

  return HolisticStats(
    totalScriptures: allScriptures.length,
    attempted: attempted,
    eternal: eternal,
    mastered: mastered,
    memorized: memorized,
    familiar: familiar,
    learning: learning,
    needsReview: needsReview,
    overallAccuracy: overallAccuracy,
  );
});
