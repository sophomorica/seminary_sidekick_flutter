import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:seminary_sidekick/providers/activity_provider.dart';
import 'package:seminary_sidekick/models/activity.dart';
import 'package:seminary_sidekick/models/enums.dart';

void main() {
  late ActivityNotifier notifier;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_activity_test_');
    Hive.init(tempDir.path);
    notifier = ActivityNotifier();
    await notifier.init();
  });

  tearDown(() async {
    await Future.delayed(const Duration(milliseconds: 50));
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('ActivityNotifier', () {
    test('starts with empty activity list', () {
      expect(notifier.state, isEmpty);
    });

    test('addActivity prepends to list', () {
      final a1 = _makeActivity(id: 'a1');
      final a2 = _makeActivity(id: 'a2');

      notifier.addActivity(a1);
      notifier.addActivity(a2);

      expect(notifier.state, hasLength(2));
      expect(notifier.state.first.id, 'a2'); // newest first
      expect(notifier.state.last.id, 'a1');
    });

    test('addActivity trims to max 200 items', () {
      // Add 205 activities
      for (var i = 0; i < 205; i++) {
        notifier.addActivity(_makeActivity(id: 'a$i'));
      }

      expect(notifier.state.length, 200);
      // Most recent should be the last added
      expect(notifier.state.first.id, 'a204');
    });

    test('logGameCompleted adds activity with correct metadata', () {
      notifier.logGameCompleted(
        scriptureId: '1',
        scriptureReference: '1 Nephi 3:7',
        gameType: GameType.scriptureBuilder,
        difficulty: DifficultyLevel.advanced,
        score: 95,
        timeSeconds: 120,
      );

      expect(notifier.state, hasLength(1));
      final activity = notifier.state.first;
      expect(activity.type, ActivityType.gameCompleted);
      expect(activity.scriptureId, '1');
      expect(activity.scriptureReference, '1 Nephi 3:7');
      expect(activity.metadata['gameType'], GameType.scriptureBuilder.displayName);
      expect(activity.metadata['difficulty'], DifficultyLevel.advanced.label);
      expect(activity.metadata['score'], 95);
      expect(activity.metadata['time'], 120);
    });

    test('logGameCompleted omits null optional metadata', () {
      notifier.logGameCompleted(
        scriptureId: '1',
        scriptureReference: 'Ref',
        gameType: GameType.matching,
        difficulty: DifficultyLevel.beginner,
      );

      final metadata = notifier.state.first.metadata;
      expect(metadata.containsKey('score'), false);
      expect(metadata.containsKey('time'), false);
    });

    test('logMasteryLevelUp adds correct activity', () {
      notifier.logMasteryLevelUp(
        scriptureId: '42',
        scriptureReference: 'Mosiah 3:19',
        previousLevel: MasteryLevel.familiar,
        newLevel: MasteryLevel.memorized,
      );

      final activity = notifier.state.first;
      expect(activity.type, ActivityType.masteryLevelUp);
      expect(activity.metadata['previousLevel'], MasteryLevel.familiar.label);
      expect(activity.metadata['newLevel'], MasteryLevel.memorized.label);
    });

    test('logStreakMilestone adds correct activity', () {
      notifier.logStreakMilestone(
        scriptureId: '1',
        scriptureReference: 'Ref',
        streakCount: 10,
        gameType: GameType.quiz,
      );

      final activity = notifier.state.first;
      expect(activity.type, ActivityType.streakMilestone);
      expect(activity.metadata['streakCount'], 10);
      expect(activity.metadata['gameType'], GameType.quiz.displayName);
    });

    test('logFirstAttempt adds correct activity', () {
      notifier.logFirstAttempt(
        scriptureId: '5',
        scriptureReference: 'Moroni 10:4-5',
        gameType: GameType.matching,
      );

      final activity = notifier.state.first;
      expect(activity.type, ActivityType.firstAttempt);
      expect(activity.metadata['gameType'], GameType.matching.displayName);
    });

    test('logPerfectRun adds correct activity', () {
      notifier.logPerfectRun(
        scriptureId: '1',
        scriptureReference: '1 Nephi 3:7',
        gameType: GameType.scriptureBuilder,
        difficulty: DifficultyLevel.master,
      );

      final activity = notifier.state.first;
      expect(activity.type, ActivityType.perfectRun);
      expect(activity.metadata['difficulty'], DifficultyLevel.master.label);
    });

    test('multiple log calls accumulate correctly', () {
      notifier.logFirstAttempt(
        scriptureId: '1',
        scriptureReference: 'Ref',
        gameType: GameType.matching,
      );
      notifier.logGameCompleted(
        scriptureId: '1',
        scriptureReference: 'Ref',
        gameType: GameType.matching,
        difficulty: DifficultyLevel.beginner,
      );
      notifier.logMasteryLevelUp(
        scriptureId: '1',
        scriptureReference: 'Ref',
        previousLevel: MasteryLevel.newScripture,
        newLevel: MasteryLevel.learning,
      );

      expect(notifier.state, hasLength(3));
      // Newest first
      expect(notifier.state[0].type, ActivityType.masteryLevelUp);
      expect(notifier.state[1].type, ActivityType.gameCompleted);
      expect(notifier.state[2].type, ActivityType.firstAttempt);
    });
  });
}

Activity _makeActivity({String id = 'test'}) {
  return Activity(
    id: id,
    type: ActivityType.gameCompleted,
    timestamp: DateTime.now(),
    scriptureId: '1',
    scriptureReference: '1 Nephi 3:7',
  );
}
