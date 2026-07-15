/// A single Word-Builder-race finish event. Mirrors `group_sb_finishes` row.
///
/// One row is inserted per (player, scriptureIndex) pair when the player
/// completes (or DNFs) that scripture. Finishes are immutable — no UPDATE
/// or DELETE policies on the table.
///
/// Sentinel value: `mistakeCount == -1` signals DNF (timeout). `elapsedMs`
/// still records how long the player held the screen before giving up;
/// callers ranking by speed should treat DNFs as last regardless of time.
class GroupSbFinish {
  static const int dnfMistakeCount = -1;

  final String id;
  final String roomId;
  final String playerId;
  final int scriptureIndex;
  final int elapsedMs;
  final int mistakeCount;
  final DateTime completedAt;

  const GroupSbFinish({
    required this.id,
    required this.roomId,
    required this.playerId,
    required this.scriptureIndex,
    required this.elapsedMs,
    required this.mistakeCount,
    required this.completedAt,
  });

  bool get isDnf => mistakeCount == dnfMistakeCount;

  /// Mistake-based star pips for Group Play SB race finish banners.
  /// Thresholds match the solo provider's internal `starRating` getter
  /// (0 mistakes → 3, 1–3 → 2, else 1; DNF → 0) — not the solo results
  /// score-meter / word-grade UI.
  static int starRatingFor(int mistakeCount) {
    if (mistakeCount == dnfMistakeCount) return 0;
    if (mistakeCount == 0) return 3;
    if (mistakeCount <= 3) return 2;
    return 1;
  }

  int get starRating => starRatingFor(mistakeCount);

  /// Accuracy matching the solo formula
  /// (`correct / (correct + incorrectAttempts)`), where `correctChunks` is
  /// the number of chunks in the raced scripture (every finish placed all
  /// of them). Returns 0 for DNF.
  double accuracyFor(int correctChunks) {
    if (isDnf || correctChunks + mistakeCount == 0) return 0.0;
    return correctChunks / (correctChunks + mistakeCount);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'room_id': roomId,
        'player_id': playerId,
        'scripture_index': scriptureIndex,
        'elapsed_ms': elapsedMs,
        'mistake_count': mistakeCount,
        'completed_at': completedAt.toIso8601String(),
      };

  factory GroupSbFinish.fromJson(Map<String, dynamic> json) {
    return GroupSbFinish(
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
    if (other is! GroupSbFinish) return false;
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
