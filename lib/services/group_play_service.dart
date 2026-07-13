import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/scriptures_data.dart';
import '../models/enums.dart';
import '../models/group_answer.dart';
import '../models/group_player.dart';
import '../models/group_question.dart';
import '../models/group_room.dart';
import '../models/group_sb_finish.dart';
import '../models/scripture.dart';
import 'quiz_question_factory.dart';

/// Owns every Supabase call for Group Play.
///
/// Tables touched:
///   - rooms          (CRUD on the host's room row)
///   - players        (joins, leaves, score updates, kicks)
///   - answers        (insert per submission; read for the leaderboard)
///   - saved_rosters  (premium — touched by TASK-059)
///   - host_usage     (RPC `bump_host_usage` on every createRoom)
///
/// Realtime channels:
///   - Postgres Changes on rooms/players/answers, filtered by room id, for
///     durable state-of-record updates (status transitions, joins, scores)
///   - Broadcast on `room:{code}` for ephemeral events (host advanced, etc.)
///
/// The service is stateless — all in-memory state lives in
/// `GroupPlayNotifier`. Streams returned here are owned/disposed by the
/// notifier. Pass a [SupabaseClient] for testability; defaults to the
/// global `Supabase.instance.client`.
class GroupPlayService {
  GroupPlayService({
    SupabaseClient? client,
    QuizQuestionFactory? factory,
  })  : _client = client ?? Supabase.instance.client,
        _factory = factory ?? QuizQuestionFactory();

  final SupabaseClient _client;
  final QuizQuestionFactory _factory;
  final _random = Random();

  // ─── Connection health ───────────────────────────────────────────────────

  /// Number of realtime channels currently down and retrying.
  int _degradedChannels = 0;

  final _reconnectingController = StreamController<bool>.broadcast();

  /// Emits `true` when any group-play realtime channel drops and enters its
  /// retry loop, `false` once every channel is healthy again. The UI uses
  /// this to show a "reconnecting" banner during live games — classroom
  /// wifi drops are a when, not an if.
  Stream<bool> get reconnecting => _reconnectingController.stream;

  void _noteChannelDown() {
    _degradedChannels++;
    if (_degradedChannels == 1 && !_reconnectingController.isClosed) {
      _reconnectingController.add(true);
    }
  }

  void _noteChannelUp() {
    _degradedChannels = max(0, _degradedChannels - 1);
    if (_degradedChannels == 0 && !_reconnectingController.isClosed) {
      _reconnectingController.add(false);
    }
  }

  /// Exponential backoff: 1s, 2s, 4s, 8s, 8s, …
  static int _backoffSeconds(int attempt) => min(8, 1 << min(attempt, 3));

  /// Subscribe [buildChannel]'s channel and transparently resubscribe with
  /// exponential backoff whenever it errors out, times out, or closes
  /// unexpectedly. Supabase reconnects the underlying socket on its own, but
  /// errored channels do NOT rejoin automatically — without this, a single
  /// wifi blip mid-game silently freezes the leaderboard for that device.
  ///
  /// Calls [onLive] after every successful (re)subscribe so callers can
  /// refetch rows that landed while the pipe was down. Returns a dispose
  /// callback for `StreamController.onCancel`.
  void Function() _subscribeResilient({
    required String description,
    required RealtimeChannel Function() buildChannel,
    Future<void> Function()? onLive,
  }) {
    RealtimeChannel? channel;
    Timer? retryTimer;
    var attempt = 0;
    var generation = 0;
    var disposed = false;
    var degraded = false;

    void markDegraded() {
      if (degraded) return;
      degraded = true;
      _noteChannelDown();
    }

    void markHealthy() {
      if (!degraded) return;
      degraded = false;
      _noteChannelUp();
    }

    void connect() {
      if (disposed) return;
      final myGen = ++generation;
      final ch = buildChannel();
      channel = ch;
      ch.subscribe((status, [error]) {
        // Stale callbacks from a channel we already replaced are ignored —
        // removeChannel fires a final `closed` that must not retrigger retry.
        if (disposed || myGen != generation) return;
        switch (status) {
          case RealtimeSubscribeStatus.subscribed:
            attempt = 0;
            markHealthy();
            onLive?.call();
          case RealtimeSubscribeStatus.channelError:
          case RealtimeSubscribeStatus.timedOut:
          case RealtimeSubscribeStatus.closed:
            markDegraded();
            final delay = _backoffSeconds(attempt);
            developer.log(
              'Realtime channel "$description" dropped ($status); '
              'retrying in ${delay}s',
              name: 'group_play',
              error: error,
            );
            _client.removeChannel(ch);
            retryTimer?.cancel();
            retryTimer = Timer(Duration(seconds: delay), connect);
            attempt++;
        }
      });
    }

    connect();

    return () {
      disposed = true;
      retryTimer?.cancel();
      markHealthy();
      final ch = channel;
      if (ch != null) _client.removeChannel(ch);
    };
  }

  /// Player cap for free-tier hosts (joinable count includes the host).
  static const int freeHostCap = 6;

  /// Player cap for premium hosts.
  static const int premiumHostCap = 30;

  /// Free hosts can start this many rooms per ISO week before being asked
  /// to upgrade.
  static const int freeHostWeeklyLimit = 1;

  /// Length and alphabet for the human-typed join code.
  static const _codeLength = 4;
  // Excludes I, O, 0, 1 (visual ambiguity) and B, S (l33t-speak fakes).
  static const _codeAlphabet = 'ACDEFGHJKLMNPQRTUVWXYZ23456789';

  // ─── Auth helpers ──────────────────────────────────────────────────────

  /// Current Supabase user id, or null if not signed in.
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Throws if not signed in. Anonymous sign-in happens in `main.dart`,
  /// so this should only fire if Supabase wasn't configured.
  String _requireUserId() {
    final id = currentUserId;
    if (id == null) {
      throw const GroupPlayException(
        'Not signed in. Group play requires Supabase to be configured.',
      );
    }
    return id;
  }

  // ─── Host: create / start / advance / end ──────────────────────────────

  /// Create a new room with the host as the first player.
  ///
  /// Returns the freshly inserted [GroupRoom]. Throws [FreeTierLimitException]
  /// if the host has exceeded their weekly room quota.
  Future<({GroupRoom room, GroupPlayer hostPlayer})> createRoom({
    required GroupRoomScope scope,
    required String hostNickname,
    required bool isPremiumHost,
  }) async {
    final hostId = _requireUserId();

    // Bump weekly usage first — short-circuits before DB writes.
    final usage = await _bumpHostUsage(hostId);
    if (!isPremiumHost && usage > freeHostWeeklyLimit) {
      throw const FreeTierLimitException(
        'Free hosts can start one game per week. Upgrade for unlimited hosting.',
      );
    }

    final cap = isPremiumHost ? premiumHostCap : freeHostCap;

    // Rooms SELECT is host-only under RLS (0007), so a pre-insert code
    // lookup can't see other hosts' rooms. Instead, rely on the unique
    // constraint on rooms.code: insert and retry with a fresh code on a
    // Postgres 23505 (unique violation) collision.
    Map<String, dynamic>? roomRow;
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _generateCode();
      try {
        roomRow = await _client
            .from('rooms')
            .insert({
              'code': code,
              'host_id': hostId,
              'status': GroupRoomStatus.lobby.name,
              'scope': scope.toJson(),
              'player_cap': cap,
              'is_premium_host': isPremiumHost,
            })
            .select()
            .single();
        break;
      } on PostgrestException catch (e) {
        final isCodeCollision = e.code == '23505' ||
            e.message.contains('duplicate key');
        if (!isCodeCollision) rethrow;
        // Collision — loop and try a new code.
      }
    }
    if (roomRow == null) {
      throw const GroupPlayException(
        'Could not generate a unique room code after 5 attempts. Try again.',
      );
    }

    final room = GroupRoom.fromJson(roomRow);

    // Insert the host as a player so leaderboard / kick logic doesn't
    // need a special case.
    final hostRow = await _client
        .from('players')
        .insert({
          'room_id': room.id,
          'user_id': hostId,
          'nickname': hostNickname,
          'is_host': true,
        })
        .select()
        .single();

    return (room: room, hostPlayer: GroupPlayer.fromJson(hostRow));
  }

  /// Start the room: generate the question set (for quiz mode), push it onto
  /// the row, and flip status to 'active'. Only callable by the host (RLS
  /// enforces this).
  ///
  /// Scripture Builder rooms don't have a question set — the scripture list lives
  /// in `scope.scriptureBuilderConfig.scriptureIds`. The `current_question_index`
  /// column is reused as the "current scripture index" in Round-by-Round mode;
  /// in Set-of-N it stays at 0 and isn't read by anyone.
  Future<GroupRoom> startRoom(GroupRoom room) async {
    if (!room.isLobby) {
      throw const GroupPlayException('Room is not in lobby state');
    }

    final update = <String, dynamic>{
      'status': GroupRoomStatus.active.name,
      'current_question_index': 0,
      'started_at': DateTime.now().toIso8601String(),
    };

    if (room.scope.mode == GroupGameMode.quiz) {
      final questions = _generateQuestions(room.scope);
      update['question_set'] = questions.map((q) => q.toJson()).toList();
    }

    await _client.from('rooms').update(update).eq('id', room.id);

    // Stamp question_started_at with DB now() via advance_question RPC.
    final stamped = await _rpcAdvanceQuestion(roomId: room.id, newIndex: 0);

    await _broadcast(
      room.code,
      event: 'question_advanced',
      payload: {'index': 0},
    );

    return stamped;
  }

  /// Total advanceable units in a room — questions for quiz mode, scriptures
  /// for Scripture Builder Round-by-Round. Set-of-N never advances via the host,
  /// so this returns 1 (the index is irrelevant after start).
  int _advanceableTotal(GroupRoom room) {
    if (room.scope.mode == GroupGameMode.quiz) {
      return room.questionSet?.length ?? 0;
    }
    final wb = room.scope.scriptureBuilderConfig;
    return wb?.scriptureIds.length ?? 0;
  }

  /// Advance to the next question via `advance_question` RPC (server clock).
  /// If we're past the last question, calls [endRoom] instead.
  Future<GroupRoom> advanceQuestion(GroupRoom room) async {
    final nextIndex = room.currentQuestionIndex + 1;
    final total = _advanceableTotal(room);

    if (nextIndex >= total) {
      return endRoom(room);
    }

    final updated = await _rpcAdvanceQuestion(
      roomId: room.id,
      newIndex: nextIndex,
    );

    await _broadcast(
      room.code,
      event: 'question_advanced',
      payload: {'index': nextIndex},
    );

    return updated;
  }

  Future<GroupRoom> _rpcAdvanceQuestion({
    required String roomId,
    required int newIndex,
  }) async {
    try {
      final raw = await _client.rpc(
        'advance_question',
        params: {
          'p_room_id': roomId,
          'p_new_index': newIndex,
        },
      );
      return GroupRoom.fromJson(Map<String, dynamic>.from(raw as Map));
    } catch (e) {
      throw _mapRpcError(e);
    }
  }

  /// Word-Builder-flavored alias of [advanceQuestion]. The on-the-wire column
  /// is shared (`current_question_index`); this method exists so call sites in
  /// the SB screen read clearly.
  Future<GroupRoom> hostAdvanceScripture(GroupRoom room) =>
      advanceQuestion(room);

  /// End the room. All clients see the status flip via Postgres Changes
  /// and via the broadcast event.
  Future<GroupRoom> endRoom(GroupRoom room) async {
    final updated = await _client
        .from('rooms')
        .update({
          'status': GroupRoomStatus.ended.name,
          'ended_at': DateTime.now().toIso8601String(),
        })
        .eq('id', room.id)
        .select()
        .single();

    await _broadcast(
      room.code,
      event: 'room_ended',
      payload: {},
    );

    return GroupRoom.fromJson(updated);
  }

  // ─── Player: join / leave / submit ─────────────────────────────────────

  /// Join a room as a non-host player via `join_room` RPC (atomic cap + ban).
  Future<({GroupRoom room, GroupPlayer self})> joinRoom({
    required String code,
    required String nickname,
  }) async {
    _requireUserId();
    try {
      final raw = await _client.rpc(
        'join_room',
        params: {
          'p_code': code,
          'p_nickname': nickname,
        },
      );
      final map = Map<String, dynamic>.from(raw as Map);
      final room = GroupRoom.fromJson(
        Map<String, dynamic>.from(map['room'] as Map),
      );
      final self = GroupPlayer.fromJson(
        Map<String, dynamic>.from(map['player'] as Map),
      );
      return (room: room, self: self);
    } catch (e) {
      throw _mapRpcError(e);
    }
  }

  /// Leave a room (self-deletion). Players can rejoin if the room is still
  /// in lobby (unless banned via [kickPlayer]).
  Future<void> leaveRoom(String roomId) async {
    final userId = _requireUserId();
    await _client
        .from('players')
        .delete()
        .eq('room_id', roomId)
        .eq('user_id', userId);
  }

  /// Host kicks a player via `kick_player` RPC (writes `room_bans` + DELETE).
  Future<void> kickPlayer({
    required String roomId,
    required String playerId,
  }) async {
    try {
      await _client.rpc(
        'kick_player',
        params: {
          'p_room_id': roomId,
          'p_player_id': playerId,
        },
      );
    } catch (e) {
      final mapped = _mapRpcError(e);
      if (mapped is KickFailedException) rethrow;
      throw KickFailedException(mapped.message);
    }
  }

  /// Submit an answer via `submit_answer` RPC. Server validates, scores, and
  /// updates `players.score`. Client never sends points or response time.
  Future<GroupAnswer> submitAnswer({
    required GroupRoom room,
    required int questionIndex,
    required int selectedChoice,
  }) async {
    try {
      final raw = await _client.rpc(
        'submit_answer',
        params: {
          'p_room_id': room.id,
          'p_question_index': questionIndex,
          'p_choice_index': selectedChoice,
        },
      );
      final map = Map<String, dynamic>.from(raw as Map);
      return GroupAnswer.fromJson(
        Map<String, dynamic>.from(map['answer'] as Map),
      );
    } catch (e) {
      throw _mapRpcError(e);
    }
  }

  // ─── Scripture Builder race: submit + watch finishes ────────────────────────

  /// Insert a finish event for the local player. Mirrors [submitAnswer]'s
  /// error-handling shape. Pass `mistakeCount = GroupSbFinish.dnfMistakeCount`
  /// to record a timeout DNF.
  ///
  /// Intentionally does NOT update `players.score` — Scripture Builder race scoring
  /// is computed in the UI from the full finish stream. Group SB also never
  /// touches the personal mastery / progress pipeline.
  Future<GroupSbFinish> submitSbFinish({
    required GroupRoom room,
    required GroupPlayer player,
    required int scriptureIndex,
    required int elapsedMs,
    required int mistakeCount,
  }) async {
    final row = await _client
        .from('group_sb_finishes')
        .insert({
          'room_id': room.id,
          'player_id': player.id,
          'scripture_index': scriptureIndex,
          'elapsed_ms': elapsedMs,
          'mistake_count': mistakeCount,
        })
        .select()
        .single();
    return GroupSbFinish.fromJson(row);
  }

  /// Watch the finish stream for a room. Yields the full list ordered by
  /// `completed_at` ascending (so per-scripture leaderboard ranking is just
  /// "first row first"). Mirrors [watchAnswers].
  Stream<List<GroupSbFinish>> watchSbFinishes(String roomId) {
    final controller = StreamController<List<GroupSbFinish>>();

    Future<void> refetch() async {
      try {
        final rows = await _client
            .from('group_sb_finishes')
            .select()
            .eq('room_id', roomId)
            .order('completed_at');
        controller.add(rows.map(GroupSbFinish.fromJson).toList());
      } catch (e) {
        developer.log('watchSbFinishes refetch failed', error: e);
      }
    }

    final dispose = _subscribeResilient(
      description: 'group_sb_finishes:$roomId',
      buildChannel: () => _client
          .channel('public:group_sb_finishes:room_id=$roomId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'group_sb_finishes',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'room_id',
              value: roomId,
            ),
            callback: (_) => refetch(),
          ),
      onLive: refetch,
    );

    controller.onCancel = dispose;

    refetch();
    return controller.stream;
  }

  // ─── Realtime streams ──────────────────────────────────────────────────

  /// Watch a single room row for status / question_index transitions.
  ///
  /// [asHost] true → base `rooms` table (includes `correctIndex`).
  /// [asHost] false → `rooms_player_view` (sanitized). Players also rely on
  /// broadcast `question_advanced` / `room_ended` to trigger [onLive] refetch
  /// because Realtime on `rooms` is RLS-filtered to the host.
  Stream<GroupRoom?> watchRoom(String roomId, {bool asHost = false}) {
    final controller = StreamController<GroupRoom?>();
    final table = asHost ? 'rooms' : 'rooms_player_view';

    Future<void> refetch() async {
      try {
        final row = await _client
            .from(table)
            .select()
            .eq('id', roomId)
            .maybeSingle();
        if (controller.isClosed) return;
        controller.add(row == null ? null : GroupRoom.fromJson(row));
      } catch (e) {
        developer.log('watchRoom refetch failed', error: e);
      }
    }

    final dispose = _subscribeResilient(
      description: '$table:$roomId',
      buildChannel: () {
        final channel = _client.channel('public:$table:id=$roomId');
        // Hosts get Postgres Changes on rooms. Players: also subscribe to
        // rooms changes (may be empty under RLS) and always refetch on live.
        return channel.onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'rooms',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: roomId,
          ),
          callback: (payload) {
            if (controller.isClosed) return;
            if (payload.eventType == PostgresChangeEvent.delete) {
              controller.add(null);
              return;
            }
            if (asHost) {
              controller.add(GroupRoom.fromJson(payload.newRecord));
            } else {
              // Strip answer key — refetch sanitized view.
              refetch();
            }
          },
        );
      },
      onLive: refetch,
    );

    controller.onCancel = dispose;
    refetch();
    return controller.stream;
  }

  /// Watch the player roster for a room.
  Stream<List<GroupPlayer>> watchPlayers(String roomId) {
    final controller = StreamController<List<GroupPlayer>>();

    Future<void> refetch() async {
      try {
        controller.add(await _fetchPlayers(roomId));
      } catch (e) {
        developer.log('watchPlayers refetch failed', error: e);
      }
    }

    final dispose = _subscribeResilient(
      description: 'players:$roomId',
      buildChannel: () => _client
          .channel('public:players:room_id=$roomId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'players',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'room_id',
              value: roomId,
            ),
            callback: (_) => refetch(),
          ),
      onLive: refetch,
    );

    controller.onCancel = dispose;

    refetch();
    return controller.stream;
  }

  /// Watch the answer stream for a room (used by the live leaderboard and
  /// the post-game per-question breakdown).
  Stream<List<GroupAnswer>> watchAnswers(String roomId) {
    final controller = StreamController<List<GroupAnswer>>();

    Future<void> refetch() async {
      try {
        final rows = await _client
            .from('answers')
            .select()
            .eq('room_id', roomId)
            .order('submitted_at');
        controller.add(rows.map(GroupAnswer.fromJson).toList());
      } catch (e) {
        developer.log('watchAnswers refetch failed', error: e);
      }
    }

    final dispose = _subscribeResilient(
      description: 'answers:$roomId',
      buildChannel: () => _client
          .channel('public:answers:room_id=$roomId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'answers',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'room_id',
              value: roomId,
            ),
            callback: (_) => refetch(),
          ),
      onLive: refetch,
    );

    controller.onCancel = dispose;

    refetch();
    return controller.stream;
  }

  /// Listen to ephemeral host events on a room's broadcast channel
  /// (`room:{code}`). Yields `(event, payload)` tuples.
  Stream<({String event, Map<String, dynamic> payload})> listenForEvents(
    String roomCode,
  ) {
    final controller =
        StreamController<({String event, Map<String, dynamic> payload})>();

    final dispose = _subscribeResilient(
      description: 'broadcast:$roomCode',
      buildChannel: () {
        final channel = _client.channel('room:$roomCode');
        channel.onBroadcast(
          event: 'question_advanced',
          callback: (payload) {
            if (controller.isClosed) return;
            controller.add((event: 'question_advanced', payload: payload));
          },
        );
        channel.onBroadcast(
          event: 'room_ended',
          callback: (payload) {
            if (controller.isClosed) return;
            controller.add((event: 'room_ended', payload: payload));
          },
        );
        return channel;
      },
    );

    controller.onCancel = dispose;

    return controller.stream;
  }

  // ─── Internals ─────────────────────────────────────────────────────────

  Future<int> _bumpHostUsage(String hostId) async {
    final result =
        await _client.rpc('bump_host_usage', params: {'p_host_id': hostId});
    return (result as num).toInt();
  }

  Future<List<GroupPlayer>> _fetchPlayers(String roomId) async {
    final rows = await _client
        .from('players')
        .select()
        .eq('room_id', roomId)
        .order('joined_at');
    return rows.map(GroupPlayer.fromJson).toList();
  }

  /// Generate a random 4-letter code. Uniqueness is enforced by the DB's
  /// unique constraint on rooms.code — createRoom retries on collision
  /// (essentially never with 30^4 = 810k codes and concurrent rooms in the
  /// low thousands).
  String _generateCode() => String.fromCharCodes(
        List.generate(
          _codeLength,
          (_) => _codeAlphabet.codeUnitAt(
            _random.nextInt(_codeAlphabet.length),
          ),
        ),
      );

  Future<void> _broadcast(
    String roomCode, {
    required String event,
    required Map<String, dynamic> payload,
  }) async {
    final channel = _client.channel('room:$roomCode');
    await channel.sendBroadcastMessage(event: event, payload: payload);
  }

  /// Generate questions for a room from its scope, using the shared factory.
  List<GroupQuestion> _generateQuestions(GroupRoomScope scope) {
    final difficulty = DifficultyLevel.values.firstWhere(
      (d) => d.name == scope.difficultyName,
      orElse: () => DifficultyLevel.beginner,
    );

    final bookFilters = scope.bookNames
        .map((n) => ScriptureBook.values.firstWhere(
              (b) => b.name == n,
              orElse: () => ScriptureBook.values.first,
            ))
        .toList();

    List<Scripture>? explicit;
    if (scope.scriptureIds.isNotEmpty) {
      explicit = scope.scriptureIds
          .map((id) =>
              allScriptures.firstWhere((s) => s.id == id, orElse: () => allScriptures.first))
          .toList();
    }

    final count =
        scope.questionCount > 0 ? scope.questionCount : difficulty.quizQuestionCount;
    final generated = _factory.buildQuestions(
      count: count,
      bookFilters: bookFilters,
      scriptures: explicit,
    );

    return [
      for (var i = 0; i < generated.length; i++)
        GroupQuestion(
          index: i,
          scriptureId: generated[i].scripture.id,
          scriptureReference: generated[i].scripture.reference,
          typeName: generated[i].type.name,
          prompt: generated[i].prompt,
          options: generated[i].options,
          correctIndex: generated[i].correctIndex,
        ),
    ];
  }
}

// ─── Exception types ─────────────────────────────────────────────────────

/// Base exception for group play errors. UI layers can catch this to render
/// a generic error and switch on subclasses for specific copy.
class GroupPlayException implements Exception {
  final String message;
  const GroupPlayException(this.message);
  @override
  String toString() => 'GroupPlayException: $message';
}

class RoomNotFoundException extends GroupPlayException {
  const RoomNotFoundException()
      : super('Room not found. Double-check the code.');
}

class RoomFullException extends GroupPlayException {
  const RoomFullException() : super('This room is full.');
}

class NicknameTakenException extends GroupPlayException {
  const NicknameTakenException()
      : super('That nickname is already taken in this room.');
}

class RoomAlreadyStartedException extends GroupPlayException {
  const RoomAlreadyStartedException()
      : super('This room already started without you.');
}

class RoomEndedException extends GroupPlayException {
  const RoomEndedException() : super('This room has ended.');
}

class FreeTierLimitException extends GroupPlayException {
  const FreeTierLimitException(super.message);
}

class KickFailedException extends GroupPlayException {
  const KickFailedException(super.message);
}

class BannedFromRoomException extends GroupPlayException {
  const BannedFromRoomException()
      : super('You were removed from this room and cannot rejoin.');
}

class AnswerRejectedException extends GroupPlayException {
  const AnswerRejectedException(super.message);
}

/// Map Postgrest / RPC error messages to typed [GroupPlayException]s.
GroupPlayException _mapRpcError(Object e) {
  final text = e.toString();
  if (text.contains('ROOM_NOT_FOUND')) return const RoomNotFoundException();
  if (text.contains('ROOM_FULL')) return const RoomFullException();
  if (text.contains('NICKNAME_TAKEN')) return const NicknameTakenException();
  if (text.contains('ROOM_ALREADY_STARTED')) {
    return const RoomAlreadyStartedException();
  }
  if (text.contains('ROOM_ENDED')) return const RoomEndedException();
  if (text.contains('BANNED_FROM_ROOM')) return const BannedFromRoomException();
  if (text.contains('NOT_HOST') || text.contains('PLAYER_NOT_FOUND')) {
    return const KickFailedException(
      'Could not kick that player. Are you still the host of this room?',
    );
  }
  if (text.contains('DUPLICATE_ANSWER') ||
      text.contains('ANSWER_TOO_LATE') ||
      text.contains('WRONG_QUESTION') ||
      text.contains('QUESTION_NOT_STARTED') ||
      text.contains('INVALID_QUESTION')) {
    return AnswerRejectedException(text);
  }
  if (e is GroupPlayException) return e;
  return GroupPlayException(text);
}
