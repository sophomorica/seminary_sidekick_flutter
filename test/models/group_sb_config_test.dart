import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/models/enums.dart';
import 'package:seminary_sidekick/models/group_room.dart';
import 'package:seminary_sidekick/models/group_sb_config.dart';
import 'package:seminary_sidekick/models/group_sb_finish.dart';

void main() {
  group('GroupSbChunkDifficulty', () {
    test('chunkSize is 3 for beginner, 2 for intermediate', () {
      expect(GroupSbChunkDifficulty.beginner.chunkSize, 3);
      expect(GroupSbChunkDifficulty.intermediate.chunkSize, 2);
    });

    test('only intermediate has distractors', () {
      expect(GroupSbChunkDifficulty.beginner.hasDistractors, isFalse);
      expect(GroupSbChunkDifficulty.intermediate.hasDistractors, isTrue);
    });

    test('extraDistractors tracks the solo DifficultyLevel enum', () {
      expect(GroupSbChunkDifficulty.beginner.extraDistractors,
          DifficultyLevel.beginner.extraDistractors);
      expect(GroupSbChunkDifficulty.intermediate.extraDistractors,
          DifficultyLevel.intermediate.extraDistractors);
    });

    test('fromName falls back to beginner for unknown names', () {
      expect(GroupSbChunkDifficulty.fromName('alien'),
          GroupSbChunkDifficulty.beginner);
      expect(GroupSbChunkDifficulty.fromName('beginner'),
          GroupSbChunkDifficulty.beginner);
      expect(GroupSbChunkDifficulty.fromName('intermediate'),
          GroupSbChunkDifficulty.intermediate);
    });
  });

  group('GroupSbFinish scoring parity with solo', () {
    test('starRatingFor matches solo thresholds', () {
      expect(GroupSbFinish.starRatingFor(0), 3);
      expect(GroupSbFinish.starRatingFor(1), 2);
      expect(GroupSbFinish.starRatingFor(3), 2);
      expect(GroupSbFinish.starRatingFor(4), 1);
      expect(GroupSbFinish.starRatingFor(GroupSbFinish.dnfMistakeCount), 0);
    });

    test('accuracyFor matches solo formula and handles DNF', () {
      final finish = GroupSbFinish(
        id: 'f1',
        roomId: 'r1',
        playerId: 'p1',
        scriptureIndex: 0,
        elapsedMs: 8200,
        mistakeCount: 2,
        completedAt: DateTime.utc(2026, 7, 12),
      );
      expect(finish.accuracyFor(8), 8 / 10);
      expect(finish.starRating, 2);

      final dnf = GroupSbFinish(
        id: 'f2',
        roomId: 'r1',
        playerId: 'p1',
        scriptureIndex: 0,
        elapsedMs: 60000,
        mistakeCount: GroupSbFinish.dnfMistakeCount,
        completedAt: DateTime.utc(2026, 7, 12),
      );
      expect(dnf.accuracyFor(8), 0.0);
      expect(dnf.starRating, 0);
    });
  });

  group('GroupSbPlayMode', () {
    test('fromName falls back to roundByRound for unknown names', () {
      expect(GroupSbPlayMode.fromName('alien'), GroupSbPlayMode.roundByRound);
      expect(GroupSbPlayMode.fromName('setOfN'), GroupSbPlayMode.setOfN);
    });
  });

  group('GroupSbConfig JSON round-trip', () {
    test('basic round-trip preserves all fields', () {
      const cfg = GroupSbConfig(
        chunkDifficulty: GroupSbChunkDifficulty.intermediate,
        playMode: GroupSbPlayMode.setOfN,
        scriptureIds: ['12', '7', '54'],
        perScriptureTimeoutSeconds: 45,
      );
      final restored = GroupSbConfig.fromJson(cfg.toJson());
      expect(restored, equals(cfg));
    });

    test('null timeout survives round-trip', () {
      const cfg = GroupSbConfig(
        chunkDifficulty: GroupSbChunkDifficulty.beginner,
        playMode: GroupSbPlayMode.roundByRound,
        scriptureIds: ['1', '2'],
      );
      final restored = GroupSbConfig.fromJson(cfg.toJson());
      expect(restored.perScriptureTimeoutSeconds, isNull);
      expect(restored, equals(cfg));
    });

    test('scriptureIds preserve order', () {
      const cfg = GroupSbConfig(
        chunkDifficulty: GroupSbChunkDifficulty.beginner,
        playMode: GroupSbPlayMode.setOfN,
        scriptureIds: ['c', 'a', 'b'],
      );
      final restored = GroupSbConfig.fromJson(cfg.toJson());
      expect(restored.scriptureIds, ['c', 'a', 'b']);
    });

    test('toJson omits perScriptureTimeoutSeconds when null', () {
      const cfg = GroupSbConfig(
        chunkDifficulty: GroupSbChunkDifficulty.beginner,
        playMode: GroupSbPlayMode.roundByRound,
        scriptureIds: ['1'],
      );
      expect(cfg.toJson().containsKey('perScriptureTimeoutSeconds'), isFalse);
    });

    test('copyWith.clearTimeout drops the timeout', () {
      const cfg = GroupSbConfig(
        chunkDifficulty: GroupSbChunkDifficulty.beginner,
        playMode: GroupSbPlayMode.roundByRound,
        scriptureIds: ['1'],
        perScriptureTimeoutSeconds: 30,
      );
      final next = cfg.copyWith(clearTimeout: true);
      expect(next.perScriptureTimeoutSeconds, isNull);
    });
  });

  group('GroupRoomScope backward compatibility with `mode`', () {
    test('scope JSON without `mode` parses as quiz mode', () {
      final json = {
        'difficulty': 'beginner',
        'bookNames': <String>[],
        'scriptureIds': <String>[],
        'questionCount': 10,
        'questionTimeoutSeconds': 20,
      };
      final restored = GroupRoomScope.fromJson(json);
      expect(restored.mode, GroupGameMode.quiz);
      expect(restored.scriptureBuilderConfig, isNull);
    });

    test('quiz scope toJson does NOT include mode', () {
      const scope = GroupRoomScope(
        difficultyName: 'beginner',
        questionCount: 10,
      );
      final json = scope.toJson();
      expect(json.containsKey('mode'), isFalse);
      expect(json.containsKey('scriptureBuilderConfig'), isFalse);
    });

    test('word builder scope round-trip', () {
      const scope = GroupRoomScope(
        mode: GroupGameMode.scriptureBuilder,
        difficultyName: 'beginner',
        scriptureIds: ['1', '2', '3'],
        questionCount: 3,
        scriptureBuilderConfig: GroupSbConfig(
          chunkDifficulty: GroupSbChunkDifficulty.intermediate,
          playMode: GroupSbPlayMode.setOfN,
          scriptureIds: ['1', '2', '3'],
        ),
      );
      final restored = GroupRoomScope.fromJson(scope.toJson());
      expect(restored.mode, GroupGameMode.scriptureBuilder);
      expect(restored.scriptureBuilderConfig, isNotNull);
      expect(restored.scriptureBuilderConfig!.chunkDifficulty,
          GroupSbChunkDifficulty.intermediate);
      expect(restored.scriptureBuilderConfig!.playMode, GroupSbPlayMode.setOfN);
      expect(restored.scriptureBuilderConfig!.scriptureIds, ['1', '2', '3']);
    });

    test('quiz scope JSON with explicit mode=quiz still parses', () {
      final json = {
        'mode': 'quiz',
        'difficulty': 'intermediate',
        'bookNames': <String>[],
        'scriptureIds': <String>[],
        'questionCount': 20,
        'questionTimeoutSeconds': 15,
      };
      final restored = GroupRoomScope.fromJson(json);
      expect(restored.mode, GroupGameMode.quiz);
      expect(restored.difficultyName, 'intermediate');
    });

    test('GroupGameMode.fromName falls back to quiz for unknown', () {
      expect(GroupGameMode.fromName('alien'), GroupGameMode.quiz);
      expect(GroupGameMode.fromName('scriptureBuilder'), GroupGameMode.scriptureBuilder);
    });
  });
}
