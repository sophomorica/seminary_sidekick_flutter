import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/models/group_answer.dart';
import 'package:seminary_sidekick/models/group_play_state.dart';
import 'package:seminary_sidekick/models/group_player.dart';
import 'package:seminary_sidekick/models/group_room.dart';
import 'package:seminary_sidekick/models/group_wb_config.dart';
import 'package:seminary_sidekick/models/group_wb_finish.dart';
import 'package:seminary_sidekick/providers/group_play_provider.dart';
import 'package:seminary_sidekick/providers/subscription_provider.dart';
import 'package:seminary_sidekick/services/group_play_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A hand-rolled fake of [GroupPlayService] that exposes seam-controlled
/// streams + recorded calls so we can drive [GroupPlayNotifier] entirely in
/// memory without touching Supabase.
///
/// The base constructor needs a SupabaseClient — we feed it a bogus one and
/// never call anything that touches it.
class _FakeGroupPlayService extends GroupPlayService {
  _FakeGroupPlayService()
      : super(
          // SupabaseClient construction doesn't make network calls, so this is
          // safe as long as no method on the parent class is exercised.
          client: SupabaseClient(
            'http://localhost:54321',
            'fake-anon-key',
          ),
        );

  GroupRoom? room;
  List<GroupPlayer> players = const [];
  GroupPlayer? selfHost;
  GroupPlayer? selfJoin;
  List<GroupWbFinish> finishes = const [];

  final _roomController = StreamController<GroupRoom?>.broadcast();
  final _playersController = StreamController<List<GroupPlayer>>.broadcast();
  final _answersController =
      StreamController<List<GroupAnswer>>.broadcast();
  final _wbFinishesController =
      StreamController<List<GroupWbFinish>>.broadcast();
  final _eventsController =
      StreamController<({String event, Map<String, dynamic> payload})>
          .broadcast();

  final List<({int scriptureIndex, int elapsedMs, int mistakeCount})>
      submittedWbFinishes = [];
  int advanceCalls = 0;
  int endCalls = 0;

  @override
  String? get currentUserId => selfHost?.userId ?? selfJoin?.userId;

  @override
  Future<({GroupRoom room, GroupPlayer hostPlayer})> createRoom({
    required GroupRoomScope scope,
    required String hostNickname,
    required bool isPremiumHost,
  }) async {
    const hostId = 'host-uid';
    final host = GroupPlayer(
      id: 'p-host',
      roomId: 'room-1',
      userId: hostId,
      nickname: hostNickname,
      isHost: true,
      joinedAt: DateTime.now(),
      lastSeenAt: DateTime.now(),
    );
    final newRoom = GroupRoom(
      id: 'room-1',
      code: 'ABCD',
      hostId: hostId,
      status: GroupRoomStatus.lobby,
      scope: scope,
      playerCap: isPremiumHost ? 30 : 6,
      isPremiumHost: isPremiumHost,
      createdAt: DateTime.now(),
    );
    room = newRoom;
    players = [host];
    selfHost = host;
    return (room: newRoom, hostPlayer: host);
  }

  @override
  Future<GroupRoom> startRoom(GroupRoom room) async {
    final updated = room.copyWith(
      status: GroupRoomStatus.active,
      currentQuestionIndex: 0,
      startedAt: DateTime.now(),
    );
    this.room = updated;
    return updated;
  }

  @override
  Future<GroupRoom> advanceQuestion(GroupRoom room) async {
    advanceCalls++;
    final wb = room.scope.wordBuilderConfig;
    final total = wb?.scriptureIds.length ?? 0;
    final next = room.currentQuestionIndex + 1;
    if (next >= total) {
      return endRoom(room);
    }
    final updated = room.copyWith(currentQuestionIndex: next);
    this.room = updated;
    return updated;
  }

  @override
  Future<GroupRoom> endRoom(GroupRoom room) async {
    endCalls++;
    final updated =
        room.copyWith(status: GroupRoomStatus.ended, endedAt: DateTime.now());
    this.room = updated;
    return updated;
  }

  @override
  Future<GroupWbFinish> submitWbFinish({
    required GroupRoom room,
    required GroupPlayer player,
    required int scriptureIndex,
    required int elapsedMs,
    required int mistakeCount,
  }) async {
    submittedWbFinishes.add((
      scriptureIndex: scriptureIndex,
      elapsedMs: elapsedMs,
      mistakeCount: mistakeCount,
    ));
    final finish = GroupWbFinish(
      id: 'fin-${submittedWbFinishes.length}',
      roomId: room.id,
      playerId: player.id,
      scriptureIndex: scriptureIndex,
      elapsedMs: elapsedMs,
      mistakeCount: mistakeCount,
      completedAt: DateTime.now(),
    );
    finishes = [...finishes, finish];
    _wbFinishesController.add(finishes);
    return finish;
  }

  @override
  Stream<GroupRoom?> watchRoom(String roomId) {
    // Push the current room immediately so the notifier doesn't have to wait.
    Future.microtask(() => _roomController.add(room));
    return _roomController.stream;
  }

  @override
  Stream<List<GroupPlayer>> watchPlayers(String roomId) {
    Future.microtask(() => _playersController.add(players));
    return _playersController.stream;
  }

  @override
  Stream<List<GroupAnswer>> watchAnswers(String roomId) {
    Future.microtask(() => _answersController.add(const []));
    return _answersController.stream;
  }

  @override
  Stream<List<GroupWbFinish>> watchWbFinishes(String roomId) {
    Future.microtask(() => _wbFinishesController.add(finishes));
    return _wbFinishesController.stream;
  }

  @override
  Stream<({String event, Map<String, dynamic> payload})> listenForEvents(
    String roomCode,
  ) {
    return _eventsController.stream;
  }
}

GroupRoomScope _wbScope({GroupWbPlayMode mode = GroupWbPlayMode.roundByRound}) {
  return GroupRoomScope(
    mode: GroupGameMode.wordBuilder,
    difficultyName: 'beginner',
    scriptureIds: ['1', '2', '3'],
    questionCount: 3,
    wordBuilderConfig: GroupWbConfig(
      chunkDifficulty: GroupWbChunkDifficulty.beginner,
      playMode: mode,
      scriptureIds: const ['1', '2', '3'],
    ),
  );
}

void main() {
  late ProviderContainer container;
  late _FakeGroupPlayService fake;

  setUp(() {
    fake = _FakeGroupPlayService();
    container = ProviderContainer(overrides: [
      groupPlayServiceProvider.overrideWithValue(fake),
      // Notifier reads `isPremiumProvider` when deciding cap. Pin it to false
      // so we don't accidentally exercise the freemium gating path.
      isPremiumProvider.overrideWith((ref) => false),
    ]);
  });

  tearDown(() => container.dispose());

  group('GroupPlayState wbFinishes / wbConfig defaults', () {
    test('initial state has empty wbFinishes + null wbConfig', () {
      final s = container.read(groupPlayProvider);
      expect(s.wbFinishes, isEmpty);
      expect(s.wbConfig, isNull);
    });
  });

  group('hostCreateRoom resolves wbConfig and primes wbFinishes', () {
    test('quiz mode leaves wbConfig null', () async {
      await container.read(groupPlayProvider.notifier).hostCreateRoom(
            scope: const GroupRoomScope(
              difficultyName: 'beginner',
              questionCount: 5,
            ),
            hostNickname: 'Coach',
          );
      final s = container.read(groupPlayProvider);
      expect(s.wbConfig, isNull);
      expect(s.wbFinishes, isEmpty);
    });

    test('wordBuilder mode populates wbConfig from scope', () async {
      await container.read(groupPlayProvider.notifier).hostCreateRoom(
            scope: _wbScope(),
            hostNickname: 'Coach',
          );
      final s = container.read(groupPlayProvider);
      expect(s.wbConfig, isNotNull);
      expect(s.wbConfig!.scriptureIds, ['1', '2', '3']);
      expect(s.wbConfig!.playMode, GroupWbPlayMode.roundByRound);
    });
  });

  group('submitWbFinish', () {
    test('forwards arguments to service', () async {
      // Bootstrap a WB room + simulate the host as the local player.
      final notifier = container.read(groupPlayProvider.notifier);
      await notifier.hostCreateRoom(
        scope: _wbScope(),
        hostNickname: 'Coach',
      );
      await notifier.submitWbFinish(
        scriptureIndex: 0,
        elapsedMs: 6200,
        mistakeCount: 1,
      );
      expect(fake.submittedWbFinishes, hasLength(1));
      expect(fake.submittedWbFinishes.first.scriptureIndex, 0);
      expect(fake.submittedWbFinishes.first.elapsedMs, 6200);
      expect(fake.submittedWbFinishes.first.mistakeCount, 1);
    });

    test('dedup: same (player, scriptureIndex) does not re-submit', () async {
      final notifier = container.read(groupPlayProvider.notifier);
      await notifier.hostCreateRoom(
        scope: _wbScope(),
        hostNickname: 'Coach',
      );
      await notifier.submitWbFinish(
        scriptureIndex: 0,
        elapsedMs: 6200,
        mistakeCount: 0,
      );
      // Drain microtasks so the watchWbFinishes stream delivers the row.
      await Future<void>.delayed(Duration.zero);
      await notifier.submitWbFinish(
        scriptureIndex: 0,
        elapsedMs: 7100,
        mistakeCount: 2,
      );
      expect(fake.submittedWbFinishes, hasLength(1));
    });

    test('different scripture indices both submit', () async {
      final notifier = container.read(groupPlayProvider.notifier);
      await notifier.hostCreateRoom(
        scope: _wbScope(),
        hostNickname: 'Coach',
      );
      await notifier.submitWbFinish(
        scriptureIndex: 0,
        elapsedMs: 6200,
        mistakeCount: 0,
      );
      await Future<void>.delayed(Duration.zero);
      await notifier.submitWbFinish(
        scriptureIndex: 1,
        elapsedMs: 8100,
        mistakeCount: 1,
      );
      expect(fake.submittedWbFinishes, hasLength(2));
    });
  });

  group('hostAdvanceScripture', () {
    test('aliases hostAdvanceQuestion — increments index', () async {
      final notifier = container.read(groupPlayProvider.notifier);
      await notifier.hostCreateRoom(
        scope: _wbScope(),
        hostNickname: 'Coach',
      );
      // Start so the room enters active with index 0.
      await notifier.hostStartGame();
      expect(container.read(groupPlayProvider).room?.currentQuestionIndex, 0);

      await notifier.hostAdvanceScripture();
      expect(fake.advanceCalls, 1);
      expect(container.read(groupPlayProvider).room?.currentQuestionIndex, 1);
    });

    test('past the last scripture transitions to viewingResults', () async {
      final notifier = container.read(groupPlayProvider.notifier);
      await notifier.hostCreateRoom(
        scope: _wbScope(),
        hostNickname: 'Coach',
      );
      await notifier.hostStartGame();

      await notifier.hostAdvanceScripture(); // 0 → 1
      await notifier.hostAdvanceScripture(); // 1 → 2
      await notifier.hostAdvanceScripture(); // 2 → past last → endRoom
      expect(fake.endCalls, 1);
      expect(container.read(groupPlayProvider).phase,
          GroupPlayPhase.viewingResults);
    });
  });

  group('wbFinishes stream propagates to state', () {
    test('watchWbFinishes updates state.wbFinishes', () async {
      final notifier = container.read(groupPlayProvider.notifier);
      await notifier.hostCreateRoom(
        scope: _wbScope(),
        hostNickname: 'Coach',
      );
      // Submit one finish via the fake (mimics another player finishing).
      final dummy = GroupWbFinish(
        id: 'fin-x',
        roomId: 'room-1',
        playerId: 'other-player',
        scriptureIndex: 0,
        elapsedMs: 5000,
        mistakeCount: 0,
        completedAt: DateTime.now(),
      );
      fake.finishes = [dummy];
      fake._wbFinishesController.add(fake.finishes);
      // Let the stream listener run.
      await Future<void>.delayed(Duration.zero);
      expect(container.read(groupPlayProvider).wbFinishes, hasLength(1));
      expect(container.read(groupPlayProvider).wbFinishes.first.id, 'fin-x');
    });
  });
}
