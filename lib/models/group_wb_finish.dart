/// A single Word-Builder-race finish event. Mirrors `group_wb_finishes` row.
///
/// One row is inserted per (player, scriptureIndex) pair when the player
/// completes (or DNFs) that scripture. Finishes are immutable — no UPDATE
/// or DELETE policies on the table.
///
/// Sentinel value: `mistakeCount == -1` signals DNF (timeout). `elapsedMs`
/// still records how long the player held the screen before giving up;
/// callers ranking by speed should treat DNFs as last regardless of time.
class GroupWbFinish {
  static const int dnfMistakeCount = -1;

  final String id;
  final String roomId;
  final String playerId;
  final int scriptureIndex;
  final int elapsedMs;
  final int mistakeCount;
  final DateTime completedAt;

  const GroupWbFinish({
    required this.id,
    required this.roomId,
    required this.playerId,
    required this.scriptureIndex,
    required this.elapsedMs,
    required this.mistakeCount,
    required this.completedAt,
  });

  bool get isDnf => mistakeCount == dnfMistakeCount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'room_id': roomId,
        'player_id': playerId,
        'scripture_index': scriptureIndex,
        'elapsed_ms': elapsedMs,
        'mistake_count': mistakeCount,
        'completed_at': completedAt.toIso8601String(),
      };

  factory GroupWbFinish.fromJson(Map<String, dynamic> json) {
    return GroupWbFinish(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      playerId: json['player_id'] as String,
      scriptureIndex: json['scripture_index'] as int,
      elapsedMs: json['elapsed_ms'] as int,
      mistakeCount: json['mistake_count'] as int,
      completedAt: DateTime.parse(json['completed_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! GroupWbFinish) return false;
    return other.id == id &&
        other.roomId == roomId &&
        other.playerId == playerId &&
        other.scriptureIndex == scriptureIndex &&
        other.elapsedMs == elapsedMs &&
        other.mistakeCount == mistakeCount &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        roomId,
        playerId,
        scriptureIndex,
        elapsedMs,
        mistakeCount,
        completedAt,
      );
}
