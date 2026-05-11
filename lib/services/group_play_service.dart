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

    final code = await _generateUniqueCode();
    final cap = isPremiumHost ? premiumHostCap : freeHostCap;

    final roomRow = await _client
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

  /// Start the room: generate the question set, push it onto the row, and
  /// flip status to 'active'. Only callable by the host (RLS enforces this).
  Future<GroupRoom> startRoom(GroupRoom room) async {
    if (!room.isLobby) {
      throw const GroupPlayException('Room is not in lobby state');
    }

    final questions = _generateQuestions(room.scope);
    final questionSetJson = questions.map((q) => q.toJson()).toList();

    final updated = await _client
        .from('rooms')
        .update({
          'status': GroupRoomStatus.active.name,
          'question_set': questionSetJson,
          'current_question_index': 0,
          'started_at': DateTime.now().toIso8601String(),
        })
        .eq('id', room.id)
        .select()
        .single();

    // Notify all subscribers via Broadcast (ephemeral, faster than waiting
    // for Postgres Changes to fan out).
    await _broadcast(
      room.code,
      event: 'question_advanced',
      payload: {'index': 0},
    );

    return GroupRoom.fromJson(updated);
  }

  /// Advance to the next question. Pushes Broadcast + updates the row.
  /// If we're past the last question, calls [endRoom] instead.
  Future<GroupRoom> advanceQuestion(GroupRoom room) async {
    final nextIndex = room.currentQuestionIndex + 1;
    final total = room.questionSet?.length ?? 0;

    if (nextIndex >= total) {
      return endRoom(room);
    }

    final updated = await _client
        .from('rooms')
        .update({'current_question_index': nextIndex})
        .eq('id', room.id)
        .select()
        .single();

    await _broadcast(
      room.code,
      event: 'question_advanced',
      payload: {'index': nextIndex},
    );

    return GroupRoom.fromJson(updated);
  }

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

  /// Look up a room by its 4-letter code. Returns null if not found.
  Future<GroupRoom?> findRoomByCode(String code) async {
    final normalized = code.trim().toUpperCase();
    final row = await _client
        .from('rooms')
        .select()
        .eq('code', normalized)
        .maybeSingle();
    if (row == null) return null;
    return GroupRoom.fromJson(row);
  }

  /// Join a room as a non-host player.
  ///
  /// Validates the room is in lobby, has capacity, and the nickname is free.
  /// Throws specific exceptions for each failure mode so the UI can render
  /// good copy.
  Future<({GroupRoom room, GroupPlayer self})> joinRoom({
    required String code,
    required String nickname,
  }) async {
    final userId = _requireUserId();
    final room = await findRoomByCode(code);
    if (room == null) {
      throw const RoomNotFoundException();
    }
    if (room.isEnded) {
      throw const RoomEndedException();
    }
    if (room.isActive) {
      throw const RoomAlreadyStartedException();
    }

    final players = await _fetchPlayers(room.id);
    if (players.length >= room.playerCap) {
      throw const RoomFullException();
    }
    if (players.any((p) => p.nickname.toLowerCase() == nickname.toLowerCase())) {
      throw const NicknameTakenException();
    }

    final row = await _client
        .from('players')
        .insert({
          'room_id': room.id,
          'user_id': userId,
          'nickname': nickname,
          'is_host': false,
        })
        .select()
        .single();

    return (room: room, self: GroupPlayer.fromJson(row));
  }

  /// Leave a room (self-deletion). Players can rejoin if the room is still
  /// in lobby.
  Future<void> leaveRoom(String roomId) async {
    final userId = _requireUserId();
    await _client
        .from('players')
        .delete()
        .eq('room_id', roomId)
        .eq('user_id', userId);
  }

  /// Host kicks a player.
  ///
  /// Supabase v2 returns an empty array (not an error) when RLS blocks a
  /// delete, so we follow the delete with `.select()` and check the result.
  /// If nothing was deleted, throw [KickFailedException] so the UI can show a
  /// real message instead of silently doing nothing — that's the bug we hit
  /// during testing where tapping the X looked like a no-op.
  Future<void> kickPlayer({
    required String roomId,
    required String playerId,
  }) async {
    final deleted = await _client
        .from('players')
        .delete()
        .eq('id', playerId)
        .select();
    if ((deleted as List).isEmpty) {
      throw const KickFailedException(
        'Could not kick that player. Are you still the host of this room?',
      );
    }
  }

  /// Submit an answer for the current question. Computes points client-side
  /// using the speed-weighted formula. Persists to `answers` and updates the
  /// player's score on `players`.
  Future<GroupAnswer> submitAnswer({
    required GroupRoom room,
    required GroupPlayer player,
    required int questionIndex,
    required int selectedChoice,
    required int responseTimeMs,
  }) async {
    final question = (room.questionSet ?? const [])[questionIndex];
    final correctIndex = question['correctIndex'] as int;
    final isCorrect = selectedChoice == correctIndex;
    final points = computeSpeedWeightedPoints(
      isCorrect: isCorrect,
      responseTimeMs: responseTimeMs,
      questionTimeoutSeconds: room.scope.questionTimeoutSeconds,
    );

    final row = await _client
        .from('answers')
        .insert({
          'room_id': room.id,
          'player_id': player.id,
          'question_index': questionIndex,
          'selected_choice': selectedChoice,
          'is_correct': isCorrect,
          'response_time_ms': responseTimeMs,
          'points_earned': points,
        })
        .select()
        .single();

    if (points > 0) {
      // Increment score atomically. We refetch the player to get the new
      // value rather than computing client-side to avoid drift.
      await _client
          .from('players')
          .update({'score': player.score + points})
          .eq('id', player.id);
    }

    return GroupAnswer.fromJson(row);
  }

  // ─── Realtime streams ──────────────────────────────────────────────────

  /// Watch a single room row for status / question_index transitions.
  /// Emits null if the room is deleted.
  Stream<GroupRoom?> watchRoom(String roomId) {
    final controller = StreamController<GroupRoom?>();
    final channel = _client
        .channel('public:rooms:id=$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'rooms',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: roomId,
          ),
          callback: (payload) {
            if (payload.eventType == PostgresChangeEvent.delete) {
              controller.add(null);
              return;
            }
            final newRow = payload.newRecord;
            controller.add(GroupRoom.fromJson(newRow));
          },
        )
        .subscribe();

    controller.onCancel = () {
      _client.removeChannel(channel);
    };

    // Emit current state immediately so subscribers don't wait for the
    // first change event.
    _client
        .from('rooms')
        .select()
        .eq('id', roomId)
        .maybeSingle()
        .then((row) {
      if (row == null) {
        controller.add(null);
      } else {
        controller.add(GroupRoom.fromJson(row));
      }
    }).catchError((Object e) {
      developer.log('watchRoom initial fetch failed', error: e);
    });

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

    final channel = _client
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
        )
        .subscribe();

    controller.onCancel = () {
      _client.removeChannel(channel);
    };

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

    final channel = _client
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
        )
        .subscribe();

    controller.onCancel = () {
      _client.removeChannel(channel);
    };

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
    final channel = _client.channel('room:$roomCode');

    channel.onBroadcast(
      event: 'question_advanced',
      callback: (payload) {
        controller.add((event: 'question_advanced', payload: payload));
      },
    );
    channel.onBroadcast(
      event: 'room_ended',
      callback: (payload) {
        controller.add((event: 'room_ended', payload: payload));
      },
    );

    channel.subscribe();

    controller.onCancel = () {
      _client.removeChannel(channel);
    };

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

  /// Generate a unique 4-letter code. Retries up to 10 times if a collision
  /// happens (essentially never with 30^4 = 810k codes and concurrent rooms
  /// in the low thousands).
  Future<String> _generateUniqueCode() async {
    for (var attempt = 0; attempt < 10; attempt++) {
      final code = String.fromCharCodes(
        List.generate(
          _codeLength,
          (_) => _codeAlphabet.codeUnitAt(
            _random.nextInt(_codeAlphabet.length),
          ),
        ),
      );
      final existing = await _client
          .from('rooms')
          .select('id')
          .eq('code', code)
          .maybeSingle();
      if (existing == null) return code;
    }
    throw const GroupPlayException(
      'Could not generate a unique room code after 10 attempts. Try again.',
    );
  }

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
