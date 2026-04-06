import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/enums.dart';
import '../models/scripture.dart';
import '../services/spaced_repetition.dart';
import 'scripture_provider.dart';
import 'scripture_mastery_provider.dart';

/// Persists spaced repetition data per scripture via Hive.
///
/// Each scripture gets ONE SR schedule (not per-game) because mastery
/// is holistic. When a user practices any game type for a scripture,
/// the quality score updates the single SR record.
class SpacedRepetitionNotifier
    extends StateNotifier<Map<String, SpacedRepetitionData>> {
  static const _boxName = 'spaced_repetition';
  late final Box<Map> _box;

  SpacedRepetitionNotifier() : super({});

  /// Open the Hive box and load persisted SR data.
  Future<void> init() async {
    _box = await Hive.openBox<Map>(_boxName);
    final loaded = <String, SpacedRepetitionData>{};
    for (final key in _box.keys) {
      try {
        final raw = _box.get(key);
        if (raw != null) {
          loaded[key as String] =
              SpacedRepetitionData.fromJson(Map<String, dynamic>.from(raw));
        }
      } catch (_) {
        // Skip corrupted entries
      }
    }
    state = loaded;
  }

  /// Persist a single SR entry.
  void _persist(String scriptureId, SpacedRepetitionData data) {
    _box.put(scriptureId, data.toJson());
  }

  /// Get SR data for a scripture, or null if never reviewed.
  SpacedRepetitionData? getData(String scriptureId) {
    return state[scriptureId];
  }

  /// Record a review and update the SM-2 schedule.
  ///
  /// Called from ProgressNotifier after a game attempt.
  void recordReview({
    required String scriptureId,
    required bool correct,
    required double accuracy,
    required GameType gameType,
    DifficultyLevel? difficulty,
    int? timeSeconds,
  }) {
    final current = state[scriptureId] ?? SpacedRepetition.initial();

    final quality = SpacedRepetition.computeQuality(
      correct: correct,
      accuracy: accuracy,
      gameType: gameType,
      difficulty: difficulty,
      timeSeconds: timeSeconds,
    );

    final updated = SpacedRepetition.review(current, quality);

    state = {...state, scriptureId: updated};
    _persist(scriptureId, updated);
  }

  /// Get the next review date for a scripture, or null if never practiced.
  DateTime? getNextReviewDate(String scriptureId) {
    return state[scriptureId]?.nextReviewDate;
  }
}

/// State notifier provider for spaced repetition data.
final spacedRepetitionProvider = StateNotifierProvider<
    SpacedRepetitionNotifier, Map<String, SpacedRepetitionData>>(
  (ref) => SpacedRepetitionNotifier(),
);

/// SR data for a single scripture.
final spacedRepetitionDataProvider =
    Provider.family<SpacedRepetitionData?, String>((ref, scriptureId) {
  final srMap = ref.watch(spacedRepetitionProvider);
  return srMap[scriptureId];
});

/// Whether a scripture is currently due for review.
final isScriptureDueProvider =
    Provider.family<bool, String>((ref, scriptureId) {
  final data = ref.watch(spacedRepetitionDataProvider(scriptureId));
  if (data == null) return false; // Never practiced → not "due"
  return data.isDue;
});

/// All scriptures that are due for review, sorted by priority (most urgent first).
final dueScripturesProvider = Provider<List<Scripture>>((ref) {
  final allScriptures = ref.watch(scripturesProvider);
  final srMap = ref.watch(spacedRepetitionProvider);

  final due = <(Scripture, double)>[];

  for (final scripture in allScriptures) {
    final data = srMap[scripture.id];
    if (data != null && data.isDue) {
      due.add((scripture, data.priority));
    }
  }

  // Sort by priority descending (most overdue first)
  due.sort((a, b) => b.$2.compareTo(a.$2));

  return due.map((pair) => pair.$1).toList();
});

/// Count of scriptures currently due for review.
final dueCountProvider = Provider<int>((ref) {
  return ref.watch(dueScripturesProvider).length;
});

/// Smart "Continue Learning" queue that blends:
/// 1. Overdue spaced repetition reviews (highest priority)
/// 2. Scriptures flagged needsReview by mastery decay
/// 3. Scriptures close to leveling up
/// 4. Random unstarted scriptures (to keep things fresh)
final smartReviewQueueProvider = Provider<List<Scripture>>((ref) {
  final allScriptures = ref.watch(scripturesProvider);
  final srMap = ref.watch(spacedRepetitionProvider);

  final queue = <(Scripture, double)>[];
  final seen = <String>{};

  // 1. Overdue SR reviews — highest priority
  for (final scripture in allScriptures) {
    final data = srMap[scripture.id];
    if (data != null && data.isDue) {
      // Priority: 100 base + overdue priority
      queue.add((scripture, 100.0 + data.priority));
      seen.add(scripture.id);
    }
  }

  // 2. Mastery decay needsReview (not already in SR queue)
  for (final scripture in allScriptures) {
    if (seen.contains(scripture.id)) continue;
    final mastery = ref.watch(scriptureMasteryProvider(scripture.id));
    if (mastery.needsReview) {
      queue.add((scripture, 50.0));
      seen.add(scripture.id);
    }
  }

  // 3. Close to leveling up (subProgress >= 0.6)
  for (final scripture in allScriptures) {
    if (seen.contains(scripture.id)) continue;
    final mastery = ref.watch(scriptureMasteryProvider(scripture.id));
    if (mastery.level != MasteryLevel.mastered &&
        mastery.level != MasteryLevel.eternal &&
        mastery.level != MasteryLevel.newScripture &&
        mastery.subProgress >= 0.6) {
      queue.add((scripture, 20.0 + mastery.subProgress * 10));
      seen.add(scripture.id);
    }
  }

  // Sort by priority descending
  queue.sort((a, b) => b.$2.compareTo(a.$2));

  return queue.map((pair) => pair.$1).toList();
});
