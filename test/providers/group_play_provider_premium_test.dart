import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/models/group_answer.dart';
import 'package:seminary_sidekick/models/group_play_state.dart';
import 'package:seminary_sidekick/models/group_player.dart';
import 'package:seminary_sidekick/models/group_room.dart';
import 'package:seminary_sidekick/models/group_sb_finish.dart';
import 'package:seminary_sidekick/providers/group_play_provider.dart';
import 'package:seminary_sidekick/providers/subscription_provider.dart';
import 'package:seminary_sidekick/services/group_play_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tiny fake that lets us script `createRoom` to either succeed or throw,
/// covering the premium-gating branch in `hostCreateRoom`.
class _GatingFakeService extends GroupPlayService {
  _GatingFakeService()
      : super(
          client: SupabaseClient(
            'http://localhost:54321',
            'fake-anon-key',
          ),
        );

  Object? createRoomError;

  @override
  Future<({GroupRoom room, GroupPlayer hostPlayer})> createRoom({
    required GroupRoomScope scope,
    required String hostNickname,
    required bool isPremiumHost,
  }) async {
    if (createRoomError != null) throw createRoomError!;
    final host = GroupPlayer(
      id: 'p-host',
      roomId: 'room-1',
      userId: 'host-uid',
      nickname: hostNickname,
      isHost: true,
      joinedAt: DateTime.now(),
      lastSeenAt: DateTime.now(),
    );
    final room = GroupRoom(
      id: 'room-1',
      code: 'ABCD',
      hostId: 'host-uid',
      status: GroupRoomStatus.lobby,
      scope: scope,
      playerCap: isPremiumHost ? 30 : 6,
      isPremiumHost: isPremiumHost,
      createdAt: DateTime.now(),
    );
    return (room: room, hostPlayer: host);
  }

  // Subscriptions called by _enterRoom — return empty streams so the notifier
  // doesn't hang or hit the real Supabase client.
  @override
  String? get currentUserId => 'host-uid';
  @override
  Stream<GroupRoom?> watchRoom(String roomId, {bool asHost = false}) =>
      const Stream.empty();
  @override
  Stream<List<GroupPlayer>> watchPlayers(String roomId) => const Stream.empty();
  @override
  Stream<List<GroupAnswer>> watchAnswers(String roomId) =>
      const Stream<List<GroupAnswer>>.empty();
  @override
  Stream<List<GroupSbFinish>> watchSbFinishes(String roomId) =>
      const Stream<List<GroupSbFinish>>.empty();
  @override
  Stream<({String event, Map<String, dynamic> payload})> listenForEvents(
    String roomCode,
  ) =>
      const Stream.empty();
}

void main() {
  late ProviderContainer container;
  late _GatingFakeService fake;

  setUp(() {
    fake = _GatingFakeService();
    container = ProviderContainer(overrides: [
      groupPlayServiceProvider.overrideWithValue(fake),
      isPremiumProvider.overrideWith((ref) => false),
    ]);
  });

  tearDown(() => container.dispose());

  group('hostCreateRoom premium gating', () {
    test(
        'FreeTierLimitException sets freeHostWeeklyLimitHit and does NOT flip phase to error',
        () async {
      fake.createRoomError = const FreeTierLimitException(
        'Free hosts can start one game per week.',
      );

      await container.read(groupPlayProvider.notifier).hostCreateRoom(
            scope: const GroupRoomScope(
              difficultyName: 'beginner',
              questionCount: 5,
            ),
            hostNickname: 'Coach',
          );

      final s = container.read(groupPlayProvider);
      expect(s.freeHostWeeklyLimitHit, isTrue);
      expect(s.phase, isNot(GroupPlayPhase.error));
      expect(s.error, isNull);
      expect(s.isLoading, isFalse);
    });

    test('non-FreeTier exceptions still flip phase to error (existing path)',
        () async {
      fake.createRoomError = const GroupPlayException('boom');

      await container.read(groupPlayProvider.notifier).hostCreateRoom(
            scope: const GroupRoomScope(
              difficultyName: 'beginner',
              questionCount: 5,
            ),
            hostNickname: 'Coach',
          );

      final s = container.read(groupPlayProvider);
      expect(s.phase, GroupPlayPhase.error);
      expect(s.error, 'boom');
      expect(s.freeHostWeeklyLimitHit, isFalse);
    });

    test('clearFreeHostWeeklyLimitHit resets the flag', () async {
      fake.createRoomError = const FreeTierLimitException('limit');
      await container.read(groupPlayProvider.notifier).hostCreateRoom(
            scope: const GroupRoomScope(
              difficultyName: 'beginner',
              questionCount: 5,
            ),
            hostNickname: 'Coach',
          );
      expect(
        container.read(groupPlayProvider).freeHostWeeklyLimitHit,
        isTrue,
      );

      container.read(groupPlayProvider.notifier).clearFreeHostWeeklyLimitHit();

      expect(
        container.read(groupPlayProvider).freeHostWeeklyLimitHit,
        isFalse,
      );
    });

    test('a successful createRoom clears any stale free-tier flag', () async {
      // First attempt: free-tier limit fires.
      fake.createRoomError = const FreeTierLimitException('limit');
      await container.read(groupPlayProvider.notifier).hostCreateRoom(
            scope: const GroupRoomScope(
              difficultyName: 'beginner',
              questionCount: 5,
            ),
            hostNickname: 'Coach',
          );
      expect(
        container.read(groupPlayProvider).freeHostWeeklyLimitHit,
        isTrue,
      );

      // Second attempt succeeds (e.g. user upgraded mid-session).
      fake.createRoomError = null;
      await container.read(groupPlayProvider.notifier).hostCreateRoom(
            scope: const GroupRoomScope(
              difficultyName: 'beginner',
              questionCount: 5,
            ),
            hostNickname: 'Coach',
          );

      final s = container.read(groupPlayProvider);
      expect(s.freeHostWeeklyLimitHit, isFalse);
      expect(s.phase, GroupPlayPhase.inLobby);
    });
  });
}
