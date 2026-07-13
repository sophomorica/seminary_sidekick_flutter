import 'dart:async';
import 'dart:developer' as developer;

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/group_answer.dart';
import '../models/group_play_state.dart';
import '../models/group_player.dart';
import '../models/group_question.dart';
import '../models/group_room.dart';
import '../models/group_sb_finish.dart';
import '../services/group_play_service.dart';
import 'subscription_provider.dart';

/// Singleton service. Tests can override via the regular Riverpod override
/// pattern.
final groupPlayServiceProvider = Provider<GroupPlayService>((ref) {
  return GroupPlayService();
});

/// State + orchestration for Group Play. Wraps [GroupPlayService] with
/// stream subscriptions and pure state transitions.
///
/// Lifecycle:
///   - `hostCreateRoom` → phase becomes `inLobby`
///   - `hostStartGame`  → phase becomes `inQuiz`
///   - last question or `hostEndGame` → phase becomes `viewingResults`
///   - `leave()` from any phase resets to `idle` and disposes streams
class GroupPlayNotifier extends StateNotifier<GroupPlayState> {
  GroupPlayNotifier(this._service, this._readIsPremium)
      : super(const GroupPlayState());

  final GroupPlayService _service;
  final bool Function() _readIsPremium;

  StreamSubscription<GroupRoom?>? _roomSub;
  StreamSubscription<List<GroupPlayer>>? _playersSub;
  StreamSubscription<List<GroupAnswer>>? _answersSub;
  StreamSubscription<List<GroupSbFinish>>? _sbFinishesSub;
  StreamSubscription<({String event, Map<String, dynamic> payload})>?
      _eventsSub;
  StreamSubscription<bool>? _reconnectSub;

  // ─── Host actions ──────────────────────────────────────────────────────

  /// Host creates a room and immediately enters the lobby.
  Future<void> hostCreateRoom({
    required GroupRoomScope scope,
    required String hostNickname,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      freeHostWeeklyLimitHit: false,
    );
    try {
      final result = await _service.createRoom(
        scope: scope,
        hostNickname: hostNickname,
        isPremiumHost: _readIsPremium(),
      );
      _enterRoom(room: result.room, self: result.hostPlayer);
    } on FreeTierLimitException catch (e) {
      // Don't flip phase to error — the host stays on the setup view and
      // sees a tasteful upgrade dialog driven by [freeHostWeeklyLimitHit].
      developer.log('Free host weekly limit: ${e.message}', name: 'group_play');
      state = state.copyWith(freeHostWeeklyLimitHit: true);
    } catch (e) {
      _handleError(e);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Acknowledge the free-tier-limit flag once the UI has shown its dialog.
  void clearFreeHostWeeklyLimitHit() {
    if (state.freeHostWeeklyLimitHit) {
      state = state.copyWith(freeHostWeeklyLimitHit: false);
    }
  }

  /// Host starts the game. Generates questions, flips room to active, pushes
  /// the first question via broadcast.
  Future<void> hostStartGame() async {
    final room = state.room;
    if (room == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _service.startRoom(room);
      final questions = (updated.questionSet ?? const [])
          .map(GroupQuestion.fromJson)
          .toList();
      state = state.copyWith(
        phase: GroupPlayPhase.inQuiz,
        room: updated,
        questions: questions,
        currentQuestionAnswered: false,
        clearMySelection: true,
      );
    } catch (e) {
      _handleError(e);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Host advances to the next question. If we're past the last, ends the room.
  Future<void> hostAdvanceQuestion() async {
    final room = state.room;
    if (room == null) return;
    try {
      final updated = await _service.advanceQuestion(room);
      final phase = updated.isEnded
          ? GroupPlayPhase.viewingResults
          : GroupPlayPhase.inQuiz;
      state = state.copyWith(
        phase: phase,
        room: updated,
        currentQuestionAnswered: false,
        clearMySelection: true,
      );
    } catch (e) {
      _handleError(e);
    }
  }

  /// Word-Builder-flavored alias for [hostAdvanceQuestion]. Round-by-Round
  /// hosts call this to advance the room to the next scripture in the set.
  /// Set-of-N never calls this — players advance independently and the host
  /// only ever calls [hostEndGame].
  Future<void> hostAdvanceScripture() => hostAdvanceQuestion();

  /// Player submits a Scripture Builder finish for the current scripture.
  /// Records (elapsedMs, mistakeCount) for the local player; the realtime
  /// stream then fans out to every other client.
  ///
  /// Pass `mistakeCount = GroupSbFinish.dnfMistakeCount` for a timeout DNF.
  Future<void> submitSbFinish({
    required int scriptureIndex,
    required int elapsedMs,
    required int mistakeCount,
  }) async {
    final room = state.room;
    final me = state.me;
    if (room == null || me == null) return;
    // Don't double-submit. Anyone re-tapping a finish button after their
    // row already exists in `sbFinishes` is a no-op.
    final already = state.sbFinishes.any(
      (f) => f.playerId == me.id && f.scriptureIndex == scriptureIndex,
    );
    if (already) return;

    try {
      await _service.submitSbFinish(
        room: room,
        player: me,
        scriptureIndex: scriptureIndex,
        elapsedMs: elapsedMs,
        mistakeCount: mistakeCount,
      );
    } catch (e) {
      _handleError(e);
    }
  }

  /// Host kicks a player.
  ///
  /// If the kick fails (RLS rejection, network), we set [GroupPlayState.error]
  /// for the UI to render WITHOUT flipping the global phase to `error` — the
  /// host should stay in the lobby view and just see a snackbar/banner. Phase
  /// flips would tear them out of the lobby unexpectedly.
  ///
  /// On success we optimistically remove the player from `state.players` so
  /// the roster updates immediately. The realtime stream will (eventually)
  /// reconfirm the same state — see migration `0004_replica_identity_full.sql`
  /// for why DELETE events need extra setup to fan out at all.
  Future<void> hostKickPlayer(String playerId) async {
    final room = state.room;
    if (room == null) return;
    state = state.copyWith(clearError: true);
    try {
      await _service.kickPlayer(roomId: room.id, playerId: playerId);
      state = state.copyWith(
        players:
            state.players.where((p) => p.id != playerId).toList(growable: false),
      );
    } catch (e) {
      final message = e is GroupPlayException ? e.message : e.toString();
      developer.log('GroupPlay kick error: $message', name: 'group_play');
      state = state.copyWith(error: message);
    }
  }

  /// Host ends the room early.
  Future<void> hostEndGame() async {
    final room = state.room;
    if (room == null) return;
    try {
      final updated = await _service.endRoom(room);
      state = state.copyWith(
        phase: GroupPlayPhase.viewingResults,
        room: updated,
      );
    } catch (e) {
      _handleError(e);
    }
  }

  // ─── Player actions ────────────────────────────────────────────────────

  /// Join a room as a non-host player.
  Future<void> joinAsPlayer({
    required String code,
    required String nickname,
  }) async {
    state = state.copyWith(
      phase: GroupPlayPhase.joining,
      isLoading: true,
      clearError: true,
    );
    try {
      final result = await _service.joinRoom(code: code, nickname: nickname);
      _enterRoom(room: result.room, self: result.self);
    } catch (e) {
      _handleError(e);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Submit the current question's answer via server-side `submit_answer` RPC.
  Future<void> submitAnswer({
    required int selectedChoice,
  }) async {
    final room = state.room;
    final me = state.me;
    if (room == null || me == null) return;
    if (state.currentQuestionAnswered) return;

    final qIndex = room.currentQuestionIndex;
    if (qIndex < 0) return;

    state = state.copyWith(
      currentQuestionAnswered: true,
      mySelectedChoice: selectedChoice,
    );

    try {
      await _service.submitAnswer(
        room: room,
        questionIndex: qIndex,
        selectedChoice: selectedChoice,
      );
    } catch (e) {
      _handleError(e);
    }
  }

  /// Leave the room (player) or close it (host).
  Future<void> leave() async {
    final room = state.room;
    final me = state.me;
    try {
      if (me != null && me.isHost && room != null && !room.isEnded) {
        await _service.endRoom(room);
      } else if (room != null) {
        await _service.leaveRoom(room.id);
      }
    } catch (e) {
      developer.log('leave() cleanup failed', error: e);
    }
    await _disposeStreams();
    state = const GroupPlayState();
  }

  /// Reset to idle without leaving (e.g., user navigated away post-results).
  void resetToIdle() {
    _disposeStreams();
    state = const GroupPlayState();
  }

  // ─── Streams ───────────────────────────────────────────────────────────

  void _enterRoom({required GroupRoom room, required GroupPlayer self}) {
    final questions = (room.questionSet ?? const [])
        .map(GroupQuestion.fromJson)
        .toList();

    final sbConfig = room.scope.scriptureBuilderConfig;
    final clearSb = sbConfig == null;
    state = state.copyWith(
      phase: GroupPlayPhase.inLobby,
      room: room,
      me: self,
      players: [self],
      questions: questions,
      answers: const [],
      sbFinishes: const [],
      sbConfig: sbConfig,
      clearSbConfig: clearSb,
      currentQuestionAnswered: false,
      clearMySelection: true,
    );

    _subscribeStreams(room, asHost: self.isHost);
  }

  void _subscribeStreams(GroupRoom room, {required bool asHost}) {
    _roomSub?.cancel();
    _playersSub?.cancel();
    _answersSub?.cancel();
    _sbFinishesSub?.cancel();
    _eventsSub?.cancel();
    _reconnectSub?.cancel();

    // Surface realtime channel health so live screens can show a
    // "reconnecting" banner during classroom wifi blips.
    _reconnectSub = _service.reconnecting.listen((reconnecting) {
      if (!mounted) return;
      state = state.copyWith(isReconnecting: reconnecting);
    });

    _roomSub = _service.watchRoom(room.id, asHost: asHost).listen((updated) {
      if (!mounted) return;
      if (updated == null) {
        // Room was deleted — treat like it ended.
        state = state.copyWith(phase: GroupPlayPhase.viewingResults);
        return;
      }
      final phase = switch (updated.status) {
        GroupRoomStatus.lobby => GroupPlayPhase.inLobby,
        GroupRoomStatus.active => GroupPlayPhase.inQuiz,
        GroupRoomStatus.ended => GroupPlayPhase.viewingResults,
      };
      final newQuestions = (updated.questionSet ?? const [])
          .map(GroupQuestion.fromJson)
          .toList();
      // Reset per-question UI state when the index advances.
      final indexAdvanced =
          updated.currentQuestionIndex != state.room?.currentQuestionIndex;
      state = state.copyWith(
        phase: phase,
        room: updated,
        questions: newQuestions.isNotEmpty ? newQuestions : null,
        currentQuestionAnswered: indexAdvanced ? false : null,
        clearMySelection: indexAdvanced,
      );
    });

    _playersSub = _service.watchPlayers(room.id).listen((players) {
      if (!mounted) return;
      // Refresh "me" with the latest score.
      final myUserId = _service.currentUserId;
      final me = myUserId == null
          ? null
          : players.firstWhereOrNull((p) => p.userId == myUserId);
      // Kick detection: our row disappeared while room is still live.
      if (me == null &&
          state.me != null &&
          !state.me!.isHost &&
          state.room != null &&
          !state.room!.isEnded) {
        _disposeStreams();
        state = state.copyWith(
          phase: GroupPlayPhase.error,
          error: 'You were removed from this room.',
          clearRoom: true,
        );
        return;
      }
      state = state.copyWith(
        players: players,
        me: me ?? state.me,
      );
    });

    _answersSub = _service.watchAnswers(room.id).listen((answers) {
      if (!mounted) return;
      state = state.copyWith(answers: answers);
    });

    // Only subscribe to SB finishes for SB-mode rooms — saves a channel for
    // every quiz room.
    if (room.scope.mode == GroupGameMode.scriptureBuilder) {
      _sbFinishesSub =
          _service.watchSbFinishes(room.id).listen((finishes) {
        if (!mounted) return;
        state = state.copyWith(sbFinishes: finishes);
      });
    }

    _eventsSub = _service.listenForEvents(room.code).listen((event) {
      // Ephemeral broadcast events; the durable state already came through
      // the room/players streams. Use these only for animations / haptics.
      developer.log('Group play event: ${event.event}', name: 'group_play');
    });
  }

  Future<void> _disposeStreams() async {
    await _roomSub?.cancel();
    await _playersSub?.cancel();
    await _answersSub?.cancel();
    await _sbFinishesSub?.cancel();
    await _eventsSub?.cancel();
    await _reconnectSub?.cancel();
    _roomSub = null;
    _playersSub = null;
    _answersSub = null;
    _sbFinishesSub = null;
    _eventsSub = null;
    _reconnectSub = null;
  }

  void _handleError(Object e) {
    final message = e is GroupPlayException ? e.message : e.toString();
    developer.log('GroupPlay error: $message', name: 'group_play');
    state = state.copyWith(
      phase: GroupPlayPhase.error,
      error: message,
    );
  }

  @override
  void dispose() {
    _disposeStreams();
    super.dispose();
  }
}

/// Top-level provider. Reads `isPremiumProvider` so the host's premium status
/// is captured at room-creation time.
final groupPlayProvider =
    StateNotifierProvider<GroupPlayNotifier, GroupPlayState>((ref) {
  final service = ref.watch(groupPlayServiceProvider);
  return GroupPlayNotifier(
    service,
    () => ref.read(isPremiumProvider),
  );
});

// ─── Convenience selectors ──────────────────────────────────────────────────

final groupPlayPhaseProvider = Provider<GroupPlayPhase>((ref) {
  return ref.watch(groupPlayProvider).phase;
});

final currentGroupRoomProvider = Provider<GroupRoom?>((ref) {
  return ref.watch(groupPlayProvider).room;
});

final groupPlayLeaderboardProvider = Provider<List<GroupPlayer>>((ref) {
  return ref.watch(groupPlayProvider).leaderboard;
});

final currentGroupQuestionProvider = Provider<GroupQuestion?>((ref) {
  return ref.watch(groupPlayProvider).currentQuestion;
});

final isGroupHostProvider = Provider<bool>((ref) {
  return ref.watch(groupPlayProvider).isHost;
});
