import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/models/group_room.dart';
import 'package:seminary_sidekick/models/group_wb_config.dart';

void main() {
  group('GroupWbChunkDifficulty', () {
    test('chunkSize is 3 for beginner, 2 for intermediate', () {
      expect(GroupWbChunkDifficulty.beginner.chunkSize, 3);
      expect(GroupWbChunkDifficulty.intermediate.chunkSize, 2);
    });

    test('only intermediate has distractors', () {
      expect(GroupWbChunkDifficulty.beginner.hasDistractors, isFalse);
      expect(GroupWbChunkDifficulty.intermediate.hasDistractors, isTrue);
    });

    test('fromName falls back to beginner for unknown names', () {
      expect(GroupWbChunkDifficulty.fromName('alien'),
          GroupWbChunkDifficulty.beginner);
      expect(GroupWbChunkDifficulty.fromName('beginner'),
          GroupWbChunkDifficulty.beginner);
      expect(GroupWbChunkDifficulty.fromName('intermediate'),
          GroupWbChunkDifficulty.intermediate);
    });
  });

  group('GroupWbPlayMode', () {
    test('fromName falls back to roundByRound for unknown names', () {
      expect(GroupWbPlayMode.fromName('alien'), GroupWbPlayMode.roundByRound);
      expect(GroupWbPlayMode.fromName('setOfN'), GroupWbPlayMode.setOfN);
    });
  });

  group('GroupWbConfig JSON round-trip', () {
    test('basic round-trip preserves all fields', () {
      const cfg = GroupWbConfig(
        chunkDifficulty: GroupWbChunkDifficulty.intermediate,
        playMode: GroupWbPlayMode.setOfN,
        scriptureIds: ['12', '7', '54'],
        perScriptureTimeoutSeconds: 45,
      );
      final restored = GroupWbConfig.fromJson(cfg.toJson());
      expect(restored, equals(cfg));
    });

    test('null timeout survives round-trip', () {
      const cfg = GroupWbConfig(
        chunkDifficulty: GroupWbChunkDifficulty.beginner,
        playMode: GroupWbPlayMode.roundByRound,
        scriptureIds: ['1', '2'],
      );
      final restored = GroupWbConfig.fromJson(cfg.toJson());
      expect(restored.perScriptureTimeoutSeconds, isNull);
      expect(restored, equals(cfg));
    });

    test('scriptureIds preserve order', () {
      const cfg = GroupWbConfig(
        chunkDifficulty: GroupWbChunkDifficulty.beginner,
        playMode: GroupWbPlayMode.setOfN,
        scriptureIds: ['c', 'a', 'b'],
      );
      final restored = GroupWbConfig.fromJson(cfg.toJson());
      expect(restored.scriptureIds, ['c', 'a', 'b']);
    });

    test('toJson omits perScriptureTimeoutSeconds when null', () {
      const cfg = GroupWbConfig(
        chunkDifficulty: GroupWbChunkDifficulty.beginner,
        playMode: GroupWbPlayMode.roundByRound,
        scriptureIds: ['1'],
      );
      expect(cfg.toJson().containsKey('perScriptureTimeoutSeconds'), isFalse);
    });

    test('copyWith.clearTimeout drops the timeout', () {
      const cfg = GroupWbConfig(
        chunkDifficulty: GroupWbChunkDifficulty.beginner,
        playMode: GroupWbPlayMode.roundByRound,
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
      expect(restored.wordBuilderConfig, isNull);
    });

    test('quiz scope toJson does NOT include mode', () {
      const scope = GroupRoomScope(
        difficultyName: 'beginner',
        questionCount: 10,
      );
      final json = scope.toJson();
      expect(json.containsKey('mode'), isFalse);
      expect(json.containsKey('wordBuilderConfig'), isFalse);
    });

    test('word builder scope round-trip', () {
      const scope = GroupRoomScope(
        mode: GroupGameMode.wordBuilder,
        difficultyName: 'beginner',
        scriptureIds: ['1', '2', '3'],
        questionCount: 3,
        wordBuilderConfig: GroupWbConfig(
          chunkDifficulty: GroupWbChunkDifficulty.intermediate,
          playMode: GroupWbPlayMode.setOfN,
          scriptureIds: ['1', '2', '3'],
        ),
      );
      final restored = GroupRoomScope.fromJson(scope.toJson());
      expect(restored.mode, GroupGameMode.wordBuilder);
      expect(restored.wordBuilderConfig, isNotNull);
      expect(restored.wordBuilderConfig!.chunkDifficulty,
          GroupWbChunkDifficulty.intermediate);
      expect(restored.wordBuilderConfig!.playMode, GroupWbPlayMode.setOfN);
      expect(restored.wordBuilderConfig!.scriptureIds, ['1', '2', '3']);
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
      expect(GroupGameMode.fromName('wordBuilder'), GroupGameMode.wordBuilder);
    });
  });
}
