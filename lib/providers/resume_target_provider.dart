import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/scripture.dart';
import 'scripture_mastery_provider.dart';
import 'scripture_provider.dart';
import 'spaced_repetition_provider.dart';

/// What the home screen needs to render the "Pick up where you left off" card.
///
/// [isReviewNudge] is true when the scripture surfaced because of overdue
/// spaced-repetition or mastery decay (vs just being the most-recently-touched
/// non-mastered one). The UI uses this to choose between
/// "Pick up where you left off" and "Time for a refresher" framing.
class ResumeTarget {
  final Scripture scripture;
  final DateTime? lastPracticed;
  final bool isReviewNudge;

  const ResumeTarget({
    required this.scripture,
    required this.lastPracticed,
    required this.isReviewNudge,
  });
}

/// The scripture to surface in the home screen's resume card.
///
/// Selection rule (in order):
///   1. Top of the smart review queue (overdue SR / decayed mastery /
///      close to leveling up) — but never a Mastered or Eternal scripture.
///   2. Most-recently-practiced scripture whose holistic mastery is not
///      Mastered or Eternal.
///   3. null — caller renders the "all caught up" empty state.
final resumeTargetProvider = Provider<ResumeTarget?>((ref) {
  final allScriptures = ref.watch(scripturesProvider);

  // 1. Smart review queue — pick the top entry that isn't already mastered.
  final smartQueue = ref.watch(smartReviewQueueProvider);
  for (final scripture in smartQueue) {
    final mastery = ref.watch(scriptureMasteryProvider(scripture.id));
    if (mastery.level == MasteryLevel.mastered ||
        mastery.level == MasteryLevel.eternal) {
      continue;
    }
    return ResumeTarget(
      scripture: scripture,
      lastPracticed: mastery.lastPracticedAny,
      isReviewNudge: true,
    );
  }

  // 2. Most-recently-practiced non-mastered scripture across all game types.
  Scripture? bestScripture;
  DateTime? bestPracticed;
  for (final scripture in allScriptures) {
    final mastery = ref.watch(scriptureMasteryProvider(scripture.id));
    if (mastery.level == MasteryLevel.mastered ||
        mastery.level == MasteryLevel.eternal) {
      continue;
    }
    final lp = mastery.lastPracticedAny;
    if (lp == null) continue;
    if (bestPracticed == null || lp.isAfter(bestPracticed)) {
      bestScripture = scripture;
      bestPracticed = lp;
    }
  }
  if (bestScripture != null) {
    return ResumeTarget(
      scripture: bestScripture,
      lastPracticed: bestPracticed,
      isReviewNudge: false,
    );
  }

  return null;
});
