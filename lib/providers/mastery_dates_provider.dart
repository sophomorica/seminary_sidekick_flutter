import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Tracks the date each scripture first reached "Mastered" level.
///
/// Used to determine when a scripture qualifies for the permanent "Eternal"
/// tier (6 months of sustained mastery). If the scripture drops below Mastered,
/// the date is cleared and the clock resets.
///
/// Persisted via a dedicated Hive box ('mastery_dates').
class MasteryDatesNotifier extends StateNotifier<Map<String, DateTime>> {
  static const _boxName = 'mastery_dates';
  late final Box<String> _box;

  MasteryDatesNotifier() : super({});

  /// Open the Hive box and load persisted dates.
  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
    final loaded = <String, DateTime>{};
    for (final key in _box.keys) {
      try {
        final raw = _box.get(key);
        if (raw != null) {
          loaded[key as String] = DateTime.parse(raw);
        }
      } catch (_) {
        // Skip corrupted entries
      }
    }
    state = loaded;
  }

  /// Record that a scripture just reached Mastered level.
  /// Only sets the date if one isn't already recorded (preserves original date).
  void markMastered(String scriptureId) {
    if (state.containsKey(scriptureId)) return; // Already tracking
    final now = DateTime.now();
    state = {...state, scriptureId: now};
    _box.put(scriptureId, now.toIso8601String());
  }

  /// Clear the mastered date (scripture dropped below Mastered).
  void clearMastered(String scriptureId) {
    if (!state.containsKey(scriptureId)) return;
    state = Map.from(state)..remove(scriptureId);
    _box.delete(scriptureId);
  }

  /// Mark as permanently eternal (set date far in the past so it always qualifies).
  /// This is called once when the 6-month threshold is crossed.
  /// After this, the date is never cleared.
  void markEternal(String scriptureId) {
    // Use a sentinel date (year 2000) to indicate permanent eternal status
    final sentinel = DateTime(2000, 1, 1);
    state = {...state, scriptureId: sentinel};
    _box.put(scriptureId, sentinel.toIso8601String());
  }

  /// Get the date a scripture first reached Mastered, or null.
  DateTime? getMasteredSince(String scriptureId) {
    return state[scriptureId];
  }

  /// Check if a scripture has earned permanent Eternal status.
  bool isEternal(String scriptureId) {
    final date = state[scriptureId];
    if (date == null) return false;
    // Sentinel date means permanently eternal
    if (date.year == 2000 && date.month == 1 && date.day == 1) return true;
    // Otherwise check if 6 months have passed
    final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 183));
    return date.isBefore(sixMonthsAgo);
  }
}

final masteryDatesProvider =
    StateNotifierProvider<MasteryDatesNotifier, Map<String, DateTime>>(
  (ref) => MasteryDatesNotifier(),
);
