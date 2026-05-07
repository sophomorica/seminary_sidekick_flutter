/// A single participant in a group play room. Mirrors the `players` table.
///
/// The host is also a player (with `isHost = true`) so the leaderboard and
/// scoring code don't need a special case for them.
class GroupPlayer {
  final String id;
  final String roomId;

  /// Supabase auth.uid() — anonymous or full session.
  final String userId;

  final String nickname;
  final int score;
  final bool isHost;
  final DateTime joinedAt;
  final DateTime lastSeenAt;

  const GroupPlayer({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.nickname,
    this.score = 0,
    this.isHost = false,
    required this.joinedAt,
    required this.lastSeenAt,
  });

  /// Local equality by user_id within a room — used for "is this me?" checks.
  bool isSelf(String currentUserId) => userId == currentUserId;

  GroupPlayer copyWith({
    int? score,
    DateTime? lastSeenAt,
  }) {
    return GroupPlayer(
      id: id,
      roomId: roomId,
      userId: userId,
      nickname: nickname,
      score: score ?? this.score,
      isHost: isHost,
      joinedAt: joinedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'room_id': roomId,
        'user_id': userId,
        'nickname': nickname,
        'score': score,
        'is_host': isHost,
        'joined_at': joinedAt.toIso8601String(),
        'last_seen_at': lastSeenAt.toIso8601String(),
      };

  factory GroupPlayer.fromJson(Map<String, dynamic> json) {
    return GroupPlayer(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      userId: json['user_id'] as String,
      nickname: json['nickname'] as String,
      score: json['score'] as int? ?? 0,
      isHost: json['is_host'] as bool? ?? false,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      lastSeenAt: DateTime.parse(json['last_seen_at'] as String),
    );
  }
}
