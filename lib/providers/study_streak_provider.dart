import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Tracks consecutive days of study activity.
///
/// A "study day" is any day where the user interacts with Word Builder,
/// a practice quiz, or the memorize tool. The streak resets if a full
/// calendar day is missed.
class StudyStreakState {
  final int currentStreak;
  final int bestStreak;
  final DateTime? lastStudyDate;
  final bool studiedToday;

  const StudyStreakState({
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastStudyDate,
    this.studiedToday = false,
  });

  StudyStreakState copyWith({
    int? currentStreak,
    int? bestStreak,
    DateTime? lastStudyDate,
    bool? studiedToday,
  }) {
    return StudyStreakState(
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      studiedToday: studiedToday ?? this.studiedToday,
    );
  }
}

class StudyStreakNotifier extends StateNotifier<StudyStreakState> {
  static const _boxName = 'study_streak';
  Box? _box;

  StudyStreakNotifier() : super(const StudyStreakState());

  /// Load persisted streak data from Hive and reconcile with today.
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    final streak = _box?.get('currentStreak', defaultValue: 0) as int;
    final best = _box?.get('bestStreak', defaultValue: 0) as int;
    final lastStudyMs = _box?.get('lastStudyDate') as int?;
    final lastStudy =
        lastStudyMs != null ? DateTime.fromMillisecondsSinceEpoch(lastStudyMs) : null;

    // Reconcile streak on load
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastStudy == null) {
      state = StudyStreakState(
        currentStreak: 0,
        bestStreak: best,
        studiedToday: false,
      );
      return;
    }

    final lastDay = DateTime(lastStudy.year, lastStudy.month, lastStudy.day);
    final daysDiff = today.difference(lastDay).inDays;

    if (daysDiff == 0) {
      // Studied today already
      state = StudyStreakState(
        currentStreak: streak,
        bestStreak: best,
        lastStudyDate: lastStudy,
        studiedToday: true,
      );
    } else if (daysDiff == 1) {
      // Studied yesterday — streak alive but not yet studied today
      state = StudyStreakState(
        currentStreak: streak,
        bestStreak: best,
        lastStudyDate: lastStudy,
        studiedToday: false,
      );
    } else {
      // Missed 2+ days — streak broken
      state = StudyStreakState(
        currentStreak: 0,
        bestStreak: best,
        lastStudyDate: lastStudy,
        studiedToday: false,
      );
      _box?.put('currentStreak', 0);
    }
  }

  /// Call this whenever the user completes a study activity
  /// (Word Builder attempt, quiz, memorize session).
  void recordStudyActivity() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (state.studiedToday) return; // Already counted today

    final lastStudy = state.lastStudyDate;
    int newStreak;

    if (lastStudy == null) {
      newStreak = 1;
    } else {
      final lastDay = DateTime(lastStudy.year, lastStudy.month, lastStudy.day);
      final daysDiff = today.difference(lastDay).inDays;

      if (daysDiff <= 1) {
        // Consecutive day (or same day edge case)
        newStreak = state.currentStreak + 1;
      } else {
        // Streak was broken — start fresh
        newStreak = 1;
      }
    }

    final newBest =
        newStreak > state.bestStreak ? newStreak : state.bestStreak;

    state = StudyStreakState(
      currentStreak: newStreak,
      bestStreak: newBest,
      lastStudyDate: now,
      studiedToday: true,
    );

    _box?.put('currentStreak', newStreak);
    _box?.put('bestStreak', newBest);
    _box?.put('lastStudyDate', now.millisecondsSinceEpoch);
  }

  /// Reset the streak (for testing/settings).
  Future<void> resetStreak() async {
    state = const StudyStreakState();
    _box?.put('currentStreak', 0);
    _box?.put('bestStreak', 0);
    _box?.delete('lastStudyDate');
  }
}

final studyStreakProvider =
    StateNotifierProvider<StudyStreakNotifier, StudyStreakState>(
  (ref) => StudyStreakNotifier(),
);

/// Convenience: just the current streak count.
final currentStreakProvider = Provider<int>((ref) {
  return ref.watch(studyStreakProvider).currentStreak;
});

/// Convenience: whether the user has studied today.
final studiedTodayProvider = Provider<bool>((ref) {
  return ref.watch(studyStreakProvider).studiedToday;
});
