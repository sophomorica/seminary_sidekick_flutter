/// Types of activities that can appear in the recent activity feed.
enum ActivityType {
  gameCompleted('Game Completed'),
  masteryLevelUp('Mastery Level Up'),
  streakMilestone('Streak Milestone'),
  firstAttempt('First Attempt'),
  perfectRun('Perfect Run');

  const ActivityType(this.displayName);
  final String displayName;
}

/// A single activity event for the recent activity feed.
///
/// Immutable. Persisted to Hive as JSON.
class Activity {
  final String id;
  final ActivityType type;
  final DateTime timestamp;
  final String scriptureId;
  final String scriptureReference;

  /// Optional metadata depending on [type]:
  /// - gameCompleted: gameType, difficulty, score, time
  /// - masteryLevelUp: previousLevel, newLevel
  /// - streakMilestone: streakCount, gameType
  /// - firstAttempt: gameType
  /// - perfectRun: gameType, difficulty
  final Map<String, dynamic> metadata;

  const Activity({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.scriptureId,
    required this.scriptureReference,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'scriptureId': scriptureId,
      'scriptureReference': scriptureReference,
      'metadata': metadata,
    };
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      type: ActivityType.values.byName(json['type'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      scriptureId: json['scriptureId'] as String,
      scriptureReference: json['scriptureReference'] as String,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  /// Human-readable description for the activity feed.
  String get description {
    switch (type) {
      case ActivityType.gameCompleted:
        final gameType = metadata['gameType'] as String? ?? '';
        final difficulty = metadata['difficulty'] as String? ?? '';
        return 'Completed $gameType at $difficulty difficulty';
      case ActivityType.masteryLevelUp:
        final newLevel = metadata['newLevel'] as String? ?? '';
        return 'Reached $newLevel mastery';
      case ActivityType.streakMilestone:
        final count = metadata['streakCount'] as int? ?? 0;
        return 'Hit a $count-streak!';
      case ActivityType.firstAttempt:
        final gameType = metadata['gameType'] as String? ?? '';
        return 'First attempt at $gameType';
      case ActivityType.perfectRun:
        final difficulty = metadata['difficulty'] as String? ?? '';
        return 'Perfect run at $difficulty difficulty!';
    }
  }
}
