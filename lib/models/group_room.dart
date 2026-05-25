import 'group_wb_config.dart';

/// Game type for a group play room. Defaults to `quiz` so any room JSON
/// written before this enum existed continues to deserialize correctly.
enum GroupGameMode {
  quiz,
  wordBuilder;

  static GroupGameMode fromName(String name) =>
      GroupGameMode.values.firstWhere(
        (v) => v.name == name,
        orElse: () => GroupGameMode.quiz,
      );
}

/// Status of a group play room.
enum GroupRoomStatus {
  /// Host has created the room; players can join. Game has not started.
  lobby,

  /// Host has started the game; questions are being pushed.
  active,

  /// The game ended (last question answered, host ended early, or host left).
  ended;

  static GroupRoomStatus fromName(String name) =>
      GroupRoomStatus.values.firstWhere(
        (v) => v.name == name,
        orElse: () => GroupRoomStatus.lobby,
      );
}

/// Frozen scope of a group play session: which game mode, difficulty, which
/// books, which scriptures, how many questions, how long per question.
///
/// Lives in `rooms.scope` as JSONB and is set once at room creation.
///
/// `mode` defaults to [GroupGameMode.quiz] so scope JSON written before the
/// mode field existed (any room shipped before TASK-062) still parses with
/// no migration. `wordBuilderConfig` is only meaningful when
/// `mode == GroupGameMode.wordBuilder`.
class GroupRoomScope {
  final GroupGameMode mode;
  final String difficultyName; // matches DifficultyLevel.name
  final List<String> bookNames; // matches ScriptureBook.name
  final List<String> scriptureIds; // optional explicit list (e.g. saved roster)
  final int questionCount;
  final int questionTimeoutSeconds;
  final GroupWbConfig? wordBuilderConfig;

  const GroupRoomScope({
    this.mode = GroupGameMode.quiz,
    required this.difficultyName,
    this.bookNames = const [],
    this.scriptureIds = const [],
    required this.questionCount,
    this.questionTimeoutSeconds = 20,
    this.wordBuilderConfig,
  });

  Map<String, dynamic> toJson() => {
        // Omit `mode` when it's the default — keeps the JSON identical to what
        // was written before the field existed, so any deep-equality tests on
        // older quiz fixtures keep passing.
        if (mode != GroupGameMode.quiz) 'mode': mode.name,
        'difficulty': difficultyName,
        'bookNames': bookNames,
        'scriptureIds': scriptureIds,
        'questionCount': questionCount,
        'questionTimeoutSeconds': questionTimeoutSeconds,
        if (wordBuilderConfig != null)
          'wordBuilderConfig': wordBuilderConfig!.toJson(),
      };

  factory GroupRoomScope.fromJson(Map<String, dynamic> json) {
    final wbJson = json['wordBuilderConfig'];
    return GroupRoomScope(
      mode: GroupGameMode.fromName(json['mode'] as String? ?? 'quiz'),
      difficultyName: json['difficulty'] as String? ?? 'beginner',
      bookNames: (json['bookNames'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      scriptureIds: (json['scriptureIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      questionCount: json['questionCount'] as int? ?? 10,
      questionTimeoutSeconds: json['questionTimeoutSeconds'] as int? ?? 20,
      wordBuilderConfig: wbJson is Map
          ? GroupWbConfig.fromJson(wbJson.cast<String, dynamic>())
          : null,
    );
  }
}

/// A single group play room. Mirrors the `rooms` table.
///
/// `questionSet` holds the frozen list of questions for this room (generated
/// once at start). It's nullable because the lobby state has no questions yet.
class GroupRoom {
  final String id;
  final String code;
  final String hostId;
  final GroupRoomStatus status;
  final GroupRoomScope scope;
  final List<Map<String, dynamic>>? questionSet;
  final int currentQuestionIndex;
  final int playerCap;
  final bool isPremiumHost;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;

  const GroupRoom({
    required this.id,
    required this.code,
    required this.hostId,
    required this.status,
    required this.scope,
    this.questionSet,
    this.currentQuestionIndex = -1,
    this.playerCap = 6,
    this.isPremiumHost = false,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
  });

  bool get isLobby => status == GroupRoomStatus.lobby;
  bool get isActive => status == GroupRoomStatus.active;
  bool get isEnded => status == GroupRoomStatus.ended;

  GroupRoom copyWith({
    GroupRoomStatus? status,
    List<Map<String, dynamic>>? questionSet,
    int? currentQuestionIndex,
    int? playerCap,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return GroupRoom(
      id: id,
      code: code,
      hostId: hostId,
      status: status ?? this.status,
      scope: scope,
      questionSet: questionSet ?? this.questionSet,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      playerCap: playerCap ?? this.playerCap,
      isPremiumHost: isPremiumHost,
      createdAt: createdAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'host_id': hostId,
        'status': status.name,
        'scope': scope.toJson(),
        if (questionSet != null) 'question_set': questionSet,
        'current_question_index': currentQuestionIndex,
        'player_cap': playerCap,
        'is_premium_host': isPremiumHost,
        'created_at': createdAt.toIso8601String(),
        if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
        if (endedAt != null) 'ended_at': endedAt!.toIso8601String(),
      };

  factory GroupRoom.fromJson(Map<String, dynamic> json) {
    return GroupRoom(
      id: json['id'] as String,
      code: json['code'] as String,
      hostId: json['host_id'] as String,
      status: GroupRoomStatus.fromName(json['status'] as String? ?? 'lobby'),
      scope: GroupRoomScope.fromJson(
        (json['scope'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      questionSet: (json['question_set'] as List<dynamic>?)
          ?.map((e) => (e as Map).cast<String, dynamic>())
          .toList(),
      currentQuestionIndex: json['current_question_index'] as int? ?? -1,
      playerCap: json['player_cap'] as int? ?? 6,
      isPremiumHost: json['is_premium_host'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
    );
  }
}
