import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/activity.dart';
import '../models/enums.dart';

/// Maximum number of activities to keep in history.
const _maxActivities = 200;

/// StateNotifier for managing the recent activity feed with Hive persistence.
class ActivityNotifier extends StateNotifier<List<Activity>> {
  static const _boxName = 'activities';
  late final Box<Map> _box;

  ActivityNotifier() : super([]);

  /// Open the Hive box and load persisted activities into state.
  Future<void> init() async {
    _box = await Hive.openBox<Map>(_boxName);
    final loaded = <Activity>[];
    for (final key in _box.keys) {
      try {
        final raw = _box.get(key);
        if (raw != null) {
          loaded.add(Activity.fromJson(Map<String, dynamic>.from(raw)));
        }
      } catch (_) {
        // Skip corrupted entries
      }
    }
    // Sort newest first
    loaded.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    state = loaded;
  }

  /// Add a new activity and persist it.
  void addActivity(Activity activity) {
    final updated = [activity, ...state];
    // Trim to max size
    if (updated.length > _maxActivities) {
      final removed = updated.sublist(_maxActivities);
      for (final a in removed) {
        _box.delete(a.id);
      }
      state = updated.sublist(0, _maxActivities);
    } else {
      state = updated;
    }
    _box.put(activity.id, activity.toJson());
  }

  /// Generate a unique ID for a new activity.
  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${state.length}';
  }

  /// Log a game completion activity.
  void logGameCompleted({
    required String scriptureId,
    required String scriptureReference,
    required GameType gameType,
    required DifficultyLevel difficulty,
    int? score,
    int? timeSeconds,
  }) {
    addActivity(Activity(
      id: _generateId(),
      type: ActivityType.gameCompleted,
      timestamp: DateTime.now(),
      scriptureId: scriptureId,
      scriptureReference: scriptureReference,
      metadata: {
        'gameType': gameType.displayName,
        'difficulty': difficulty.label,
        if (score != null) 'score': score,
        if (timeSeconds != null) 'time': timeSeconds,
      },
    ));
  }

  /// Log a mastery level-up activity.
  void logMasteryLevelUp({
    required String scriptureId,
    required String scriptureReference,
    required MasteryLevel previousLevel,
    required MasteryLevel newLevel,
  }) {
    addActivity(Activity(
      id: _generateId(),
      type: ActivityType.masteryLevelUp,
      timestamp: DateTime.now(),
      scriptureId: scriptureId,
      scriptureReference: scriptureReference,
      metadata: {
        'previousLevel': previousLevel.label,
        'newLevel': newLevel.label,
      },
    ));
  }

  /// Log a streak milestone activity (at 5, 10, 25, 50, 100).
  void logStreakMilestone({
    required String scriptureId,
    required String scriptureReference,
    required int streakCount,
    required GameType gameType,
  }) {
    addActivity(Activity(
      id: _generateId(),
      type: ActivityType.streakMilestone,
      timestamp: DateTime.now(),
      scriptureId: scriptureId,
      scriptureReference: scriptureReference,
      metadata: {
        'streakCount': streakCount,
        'gameType': gameType.displayName,
      },
    ));
  }

  /// Log a first attempt activity.
  void logFirstAttempt({
    required String scriptureId,
    required String scriptureReference,
    required GameType gameType,
  }) {
    addActivity(Activity(
      id: _generateId(),
      type: ActivityType.firstAttempt,
      timestamp: DateTime.now(),
      scriptureId: scriptureId,
      scriptureReference: scriptureReference,
      metadata: {
        'gameType': gameType.displayName,
      },
    ));
  }

  /// Log a perfect run activity.
  void logPerfectRun({
    required String scriptureId,
    required String scriptureReference,
    required GameType gameType,
    required DifficultyLevel difficulty,
  }) {
    addActivity(Activity(
      id: _generateId(),
      type: ActivityType.perfectRun,
      timestamp: DateTime.now(),
      scriptureId: scriptureId,
      scriptureReference: scriptureReference,
      metadata: {
        'gameType': gameType.displayName,
        'difficulty': difficulty.label,
      },
    ));
  }
}

/// State notifier provider for activity management.
final activityProvider =
    StateNotifierProvider<ActivityNotifier, List<Activity>>(
  (ref) => ActivityNotifier(),
);

/// Provider for recent activities (last 20).
final recentActivitiesProvider = Provider<List<Activity>>((ref) {
  final activities = ref.watch(activityProvider);
  return activities.take(20).toList();
});
