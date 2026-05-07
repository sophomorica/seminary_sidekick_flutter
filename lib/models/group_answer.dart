/// A single answer submission. Mirrors the `answers` table.
///
/// `pointsEarned` already accounts for the speed-weighted scoring formula
/// computed on the client. The formula:
///
/// ```
/// if (!isCorrect || timedOut) points = 0
/// else points = round(maxPoints * (1 - 0.5 * elapsedSec / timeoutSec))
/// ```
///
/// Default `maxPoints = 1000`. So a perfect-speed correct answer is 1000;
/// a just-in-time correct answer is 500; wrong/timeout is 0. See
/// [computeSpeedWeightedPoints] for the canonical implementation.
class GroupAnswer {
  final String id;
  final String roomId;
  final String playerId;
  final int questionIndex;
  final int selectedChoice;
  final bool isCorrect;
  final int responseTimeMs;
  final int pointsEarned;
  final DateTime submittedAt;

  const GroupAnswer({
    required this.id,
    required this.roomId,
    required this.playerId,
    required this.questionIndex,
    required this.selectedChoice,
    required this.isCorrect,
    required this.responseTimeMs,
    required this.pointsEarned,
    required this.submittedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'room_id': roomId,
        'player_id': playerId,
        'question_index': questionIndex,
        'selected_choice': selectedChoice,
        'is_correct': isCorrect,
        'response_time_ms': responseTimeMs,
        'points_earned': pointsEarned,
        'submitted_at': submittedAt.toIso8601String(),
      };

  factory GroupAnswer.fromJson(Map<String, dynamic> json) {
    return GroupAnswer(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      playerId: json['player_id'] as String,
      questionIndex: json['question_index'] as int,
      selectedChoice: json['selected_choice'] as int,
      isCorrect: json['is_correct'] as bool,
      responseTimeMs: json['response_time_ms'] as int,
      pointsEarned: json['points_earned'] as int,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
    );
  }
}

/// Compute the speed-weighted points awarded for a correct answer.
///
/// Returns 0 if [isCorrect] is false or the player timed out.
/// Returns a value in [maxPoints/2, maxPoints] otherwise.
int computeSpeedWeightedPoints({
  required bool isCorrect,
  required int responseTimeMs,
  required int questionTimeoutSeconds,
  int maxPoints = 1000,
}) {
  if (!isCorrect) return 0;
  final timeoutMs = questionTimeoutSeconds * 1000;
  if (responseTimeMs >= timeoutMs) return 0;
  final fraction = responseTimeMs / timeoutMs; // 0.0 fast → 1.0 slow
  final scaled = maxPoints * (1.0 - 0.5 * fraction);
  return scaled.round().clamp((maxPoints / 2).round(), maxPoints);
}
