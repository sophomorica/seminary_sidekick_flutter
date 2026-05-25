import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/models/group_sb_finish.dart';

void main() {
  group('GroupSbFinish', () {
    final fixture = GroupSbFinish(
      id: 'fin-1',
      roomId: 'room-1',
      playerId: 'player-1',
      scriptureIndex: 2,
      elapsedMs: 8230,
      mistakeCount: 1,
      completedAt: DateTime.utc(2026, 5, 25, 12, 0, 0),
    );

    test('JSON round-trip preserves all fields', () {
      final restored = GroupSbFinish.fromJson(fixture.toJson());
      expect(restored, equals(fixture));
    });

    test('DNF sentinel detected via isDnf', () {
      final dnf = GroupSbFinish(
        id: 'fin-2',
        roomId: 'room-1',
        playerId: 'player-2',
        scriptureIndex: 0,
        elapsedMs: 30000,
        mistakeCount: GroupSbFinish.dnfMistakeCount,
        completedAt: DateTime.utc(2026, 5, 25, 12, 1, 0),
      );
      expect(dnf.isDnf, isTrue);
      expect(fixture.isDnf, isFalse);
    });

    test('equality is value-based', () {
      final twin = GroupSbFinish(
        id: 'fin-1',
        roomId: 'room-1',
        playerId: 'player-1',
        scriptureIndex: 2,
        elapsedMs: 8230,
        mistakeCount: 1,
        completedAt: DateTime.utc(2026, 5, 25, 12, 0, 0),
      );
      expect(twin, equals(fixture));
      expect(twin.hashCode, equals(fixture.hashCode));
    });

    test('different ids are unequal', () {
      final other = GroupSbFinish(
        id: 'fin-99',
        roomId: 'room-1',
        playerId: 'player-1',
        scriptureIndex: 2,
        elapsedMs: 8230,
        mistakeCount: 1,
        completedAt: DateTime.utc(2026, 5, 25, 12, 0, 0),
      );
      expect(other == fixture, isFalse);
    });

    test('JSON uses snake_case keys', () {
      final j = fixture.toJson();
      expect(j['room_id'], 'room-1');
      expect(j['player_id'], 'player-1');
      expect(j['scripture_index'], 2);
      expect(j['elapsed_ms'], 8230);
      expect(j['mistake_count'], 1);
    });
  });
}
