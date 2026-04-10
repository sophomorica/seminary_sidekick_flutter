import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/models/activity.dart';

void main() {
  group('ActivityType', () {
    test('all enum values have display names', () {
      for (final type in ActivityType.values) {
        expect(type.displayName, isNotEmpty);
      }
    });

    test('display names are human-readable', () {
      expect(ActivityType.gameCompleted.displayName, 'Game Completed');
      expect(ActivityType.masteryLevelUp.displayName, 'Mastery Level Up');
      expect(ActivityType.streakMilestone.displayName, 'Streak Milestone');
      expect(ActivityType.firstAttempt.displayName, 'First Attempt');
      expect(ActivityType.perfectRun.displayName, 'Perfect Run');
    });
  });

  group('Activity', () {
    final ts = DateTime(2026, 4, 9, 12, 0, 0);

    Activity makeActivity({
      String id = 'act-1',
      ActivityType type = ActivityType.gameCompleted,
      Map<String, dynamic> metadata = const {},
    }) {
      return Activity(
        id: id,
        type: type,
        timestamp: ts,
        scriptureId: '1',
        scriptureReference: '1 Nephi 3:7',
        metadata: metadata,
      );
    }

    group('construction', () {
      test('creates with required fields', () {
        final activity = makeActivity();
        expect(activity.id, 'act-1');
        expect(activity.type, ActivityType.gameCompleted);
        expect(activity.timestamp, ts);
        expect(activity.scriptureId, '1');
        expect(activity.scriptureReference, '1 Nephi 3:7');
        expect(activity.metadata, isEmpty);
      });

      test('creates with metadata', () {
        final activity = makeActivity(metadata: {'key': 'value'});
        expect(activity.metadata['key'], 'value');
      });
    });

    group('JSON serialization', () {
      test('toJson includes all fields', () {
        final json = makeActivity(
          metadata: {'gameType': 'Word Builder', 'difficulty': 'Beginner'},
        ).toJson();

        expect(json['id'], 'act-1');
        expect(json['type'], 'gameCompleted');
        expect(json['timestamp'], ts.toIso8601String());
        expect(json['scriptureId'], '1');
        expect(json['scriptureReference'], '1 Nephi 3:7');
        expect(json['metadata']['gameType'], 'Word Builder');
      });

      test('fromJson parses all fields', () {
        final json = {
          'id': 'x',
          'type': 'masteryLevelUp',
          'timestamp': '2026-04-09T12:00:00.000',
          'scriptureId': '42',
          'scriptureReference': 'Mosiah 3:19',
          'metadata': {'previousLevel': 'Learning', 'newLevel': 'Familiar'},
        };
        final activity = Activity.fromJson(json);

        expect(activity.id, 'x');
        expect(activity.type, ActivityType.masteryLevelUp);
        expect(activity.scriptureId, '42');
        expect(activity.metadata['newLevel'], 'Familiar');
      });

      test('fromJson handles missing metadata', () {
        final json = {
          'id': 'x',
          'type': 'firstAttempt',
          'timestamp': '2026-04-09T12:00:00.000',
          'scriptureId': '1',
          'scriptureReference': 'Ref',
        };
        final activity = Activity.fromJson(json);
        expect(activity.metadata, isEmpty);
      });

      test('roundtrip preserves data', () {
        final original = makeActivity(
          type: ActivityType.perfectRun,
          metadata: {'gameType': 'Quiz', 'difficulty': 'Master'},
        );
        final parsed = Activity.fromJson(original.toJson());

        expect(parsed.id, original.id);
        expect(parsed.type, original.type);
        expect(parsed.scriptureId, original.scriptureId);
        expect(parsed.scriptureReference, original.scriptureReference);
        expect(parsed.metadata['gameType'], 'Quiz');
      });
    });

    group('description', () {
      test('gameCompleted description', () {
        final activity = makeActivity(
          type: ActivityType.gameCompleted,
          metadata: {'gameType': 'Word Builder', 'difficulty': 'Advanced'},
        );
        expect(activity.description,
            'Completed Word Builder at Advanced difficulty');
      });

      test('masteryLevelUp description', () {
        final activity = makeActivity(
          type: ActivityType.masteryLevelUp,
          metadata: {'newLevel': 'Memorized'},
        );
        expect(activity.description, 'Reached Memorized mastery');
      });

      test('streakMilestone description', () {
        final activity = makeActivity(
          type: ActivityType.streakMilestone,
          metadata: {'streakCount': 10},
        );
        expect(activity.description, 'Hit a 10-streak!');
      });

      test('firstAttempt description', () {
        final activity = makeActivity(
          type: ActivityType.firstAttempt,
          metadata: {'gameType': 'Matching'},
        );
        expect(activity.description, 'First attempt at Matching');
      });

      test('perfectRun description', () {
        final activity = makeActivity(
          type: ActivityType.perfectRun,
          metadata: {'difficulty': 'Master'},
        );
        expect(activity.description, 'Perfect run at Master difficulty!');
      });

      test('descriptions handle missing metadata gracefully', () {
        // Each type should still produce a string, even with empty metadata
        for (final type in ActivityType.values) {
          final activity = makeActivity(type: type);
          expect(activity.description, isNotEmpty);
        }
      });
    });
  });
}
