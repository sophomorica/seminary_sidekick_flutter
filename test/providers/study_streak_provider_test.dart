import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:seminary_sidekick/providers/study_streak_provider.dart';

void main() {
  late StudyStreakNotifier notifier;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_streak_test_');
    Hive.init(tempDir.path);
    notifier = StudyStreakNotifier();
    await notifier.init();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  // -------------------------------------------------------
  // Default state
  // -------------------------------------------------------
  group('default state', () {
    test('starts with zero streak', () {
      expect(notifier.state.currentStreak, 0);
    });

    test('starts with zero best streak', () {
      expect(notifier.state.bestStreak, 0);
    });

    test('has not studied today', () {
      expect(notifier.state.studiedToday, false);
    });

    test('has no last study date', () {
      expect(notifier.state.lastStudyDate, isNull);
    });
  });

  // -------------------------------------------------------
  // recordStudyActivity — first activity
  // -------------------------------------------------------
  group('recordStudyActivity — first activity', () {
    test('sets streak to 1', () {
      notifier.recordStudyActivity();
      expect(notifier.state.currentStreak, 1);
    });

    test('sets best streak to 1', () {
      notifier.recordStudyActivity();
      expect(notifier.state.bestStreak, 1);
    });

    test('marks studied today', () {
      notifier.recordStudyActivity();
      expect(notifier.state.studiedToday, true);
    });

    test('sets last study date to today', () {
      notifier.recordStudyActivity();
      expect(notifier.state.lastStudyDate, isNotNull);

      final now = DateTime.now();
      final lastStudy = notifier.state.lastStudyDate!;
      expect(lastStudy.year, now.year);
      expect(lastStudy.month, now.month);
      expect(lastStudy.day, now.day);
    });
  });

  // -------------------------------------------------------
  // recordStudyActivity — idempotent within same day
  // -------------------------------------------------------
  group('recordStudyActivity — same day idempotency', () {
    test('calling twice on the same day does not double the streak', () {
      notifier.recordStudyActivity();
      notifier.recordStudyActivity();
      notifier.recordStudyActivity();

      expect(notifier.state.currentStreak, 1);
      expect(notifier.state.studiedToday, true);
    });

    test('best streak stays at 1 after repeated same-day calls', () {
      notifier.recordStudyActivity();
      notifier.recordStudyActivity();

      expect(notifier.state.bestStreak, 1);
    });
  });

  // -------------------------------------------------------
  // Streak persistence
  // -------------------------------------------------------
  group('persistence', () {
    test('streak survives reinit on same day', () async {
      notifier.recordStudyActivity();

      final notifier2 = StudyStreakNotifier();
      await notifier2.init();

      expect(notifier2.state.currentStreak, 1);
      expect(notifier2.state.studiedToday, true);
    });

    test('best streak persists across reinit', () async {
      notifier.recordStudyActivity();

      final notifier2 = StudyStreakNotifier();
      await notifier2.init();

      expect(notifier2.state.bestStreak, 1);
    });
  });

  // -------------------------------------------------------
  // Streak continuation via Hive manipulation
  // (simulate "yesterday" by writing to Hive directly)
  // -------------------------------------------------------
  group('streak continuation across days', () {
    test('streak increments when last study was yesterday', () async {
      // Simulate: studied yesterday with streak of 3
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final box = await Hive.openBox('study_streak');
      await box.put('currentStreak', 3);
      await box.put('bestStreak', 5);
      await box.put('lastStudyDate', yesterday.millisecondsSinceEpoch);
      await box.close();

      // Reinit — should see streak alive but not yet studied today
      final fresh = StudyStreakNotifier();
      await fresh.init();

      expect(fresh.state.currentStreak, 3);
      expect(fresh.state.studiedToday, false);

      // Record today
      fresh.recordStudyActivity();

      expect(fresh.state.currentStreak, 4);
      expect(fresh.state.bestStreak, 5); // best was higher
      expect(fresh.state.studiedToday, true);
    });

    test('streak resets when last study was 2+ days ago', () async {
      // Simulate: studied 3 days ago with streak of 10
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      final box = await Hive.openBox('study_streak');
      await box.put('currentStreak', 10);
      await box.put('bestStreak', 10);
      await box.put('lastStudyDate', threeDaysAgo.millisecondsSinceEpoch);
      await box.close();

      final fresh = StudyStreakNotifier();
      await fresh.init();

      // Streak should be broken
      expect(fresh.state.currentStreak, 0);
      expect(fresh.state.bestStreak, 10); // best preserved
      expect(fresh.state.studiedToday, false);

      // Start fresh streak
      fresh.recordStudyActivity();
      expect(fresh.state.currentStreak, 1);
      expect(fresh.state.bestStreak, 10); // best still preserved
    });

    test('best streak updates when current exceeds it', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final box = await Hive.openBox('study_streak');
      await box.put('currentStreak', 5);
      await box.put('bestStreak', 5);
      await box.put('lastStudyDate', yesterday.millisecondsSinceEpoch);
      await box.close();

      final fresh = StudyStreakNotifier();
      await fresh.init();
      fresh.recordStudyActivity();

      expect(fresh.state.currentStreak, 6);
      expect(fresh.state.bestStreak, 6); // new record
    });
  });

  // -------------------------------------------------------
  // resetStreak
  // -------------------------------------------------------
  group('resetStreak', () {
    test('resets all streak data', () async {
      notifier.recordStudyActivity();
      expect(notifier.state.currentStreak, 1);

      await notifier.resetStreak();

      expect(notifier.state.currentStreak, 0);
      expect(notifier.state.bestStreak, 0);
      expect(notifier.state.lastStudyDate, isNull);
      expect(notifier.state.studiedToday, false);
    });

    test('reset persists across reinit', () async {
      notifier.recordStudyActivity();
      await notifier.resetStreak();

      final notifier2 = StudyStreakNotifier();
      await notifier2.init();

      expect(notifier2.state.currentStreak, 0);
      expect(notifier2.state.bestStreak, 0);
    });
  });

  // -------------------------------------------------------
  // StudyStreakState.copyWith
  // -------------------------------------------------------
  group('StudyStreakState.copyWith', () {
    test('copies with single override', () {
      const original = StudyStreakState(currentStreak: 5, bestStreak: 10);
      final copy = original.copyWith(currentStreak: 6);

      expect(copy.currentStreak, 6);
      expect(copy.bestStreak, 10); // unchanged
    });

    test('copies with no overrides preserves all fields', () {
      final now = DateTime.now();
      final original = StudyStreakState(
        currentStreak: 3,
        bestStreak: 7,
        lastStudyDate: now,
        studiedToday: true,
      );
      final copy = original.copyWith();

      expect(copy.currentStreak, 3);
      expect(copy.bestStreak, 7);
      expect(copy.lastStudyDate, now);
      expect(copy.studiedToday, true);
    });
  });
}
