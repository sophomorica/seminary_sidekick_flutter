import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/announcement.dart';
import '../services/announcement_service.dart';

/// Immutable state for in-app announcements.
class AnnouncementState {
  /// All active announcements from the last successful fetch.
  final List<Announcement> announcements;

  /// Announcement IDs the user has dismissed (persisted in Hive).
  final Set<String> dismissedIds;

  final bool isLoading;
  final bool hasLoaded;

  const AnnouncementState({
    this.announcements = const [],
    this.dismissedIds = const {},
    this.isLoading = false,
    this.hasLoaded = false,
  });

  /// Highest-priority undismissed announcement that is still live.
  Announcement? get visible {
    final now = DateTime.now().toUtc();
    Announcement? best;
    for (final a in announcements) {
      if (dismissedIds.contains(a.id)) continue;
      if (!a.isLiveAt(now)) continue;
      if (best == null ||
          a.priority > best.priority ||
          (a.priority == best.priority && a.createdAt.isAfter(best.createdAt))) {
        best = a;
      }
    }
    return best;
  }

  AnnouncementState copyWith({
    List<Announcement>? announcements,
    Set<String>? dismissedIds,
    bool? isLoading,
    bool? hasLoaded,
  }) {
    return AnnouncementState(
      announcements: announcements ?? this.announcements,
      dismissedIds: dismissedIds ?? this.dismissedIds,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

/// Loads announcements from Supabase and tracks local dismissals in Hive.
class AnnouncementNotifier extends StateNotifier<AnnouncementState> {
  static const boxName = 'announcements';
  static const _dismissedKey = 'dismissed_ids';

  AnnouncementNotifier({
    AnnouncementService? service,
    Box? box,
  })  : _service = service ?? AnnouncementService(),
        _boxOverride = box,
        super(const AnnouncementState());

  final AnnouncementService _service;
  final Box? _boxOverride;
  Box? _box;

  /// Open Hive and restore dismissed IDs. Safe to call before Supabase is up.
  Future<void> init() async {
    _box = _boxOverride ?? await Hive.openBox(boxName);
    final raw = _box!.get(_dismissedKey);
    final dismissed = <String>{};
    if (raw is List) {
      for (final item in raw) {
        if (item is String && item.isNotEmpty) dismissed.add(item);
      }
    }
    state = state.copyWith(dismissedIds: dismissed, hasLoaded: false);
  }

  /// Fetch latest announcements from Supabase (best-effort).
  ///
  /// A failed/unavailable fetch (null) keeps the last-known-good list —
  /// announcements are broadcast content, so stale beats blank. This matters
  /// after Settings → "Delete All My Data": the refresh there races the
  /// anonymous re-sign-in and would otherwise wipe the banner until the next
  /// cold start.
  Future<void> refresh() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);
    final list = await _service.fetchActive();
    if (!mounted) return;
    if (list == null) {
      state = state.copyWith(isLoading: false);
      return;
    }
    state = state.copyWith(
      announcements: list,
      isLoading: false,
      hasLoaded: true,
    );
  }

  /// Persist dismissal so this announcement never shows again on this device.
  Future<void> dismiss(String id) async {
    if (id.isEmpty || state.dismissedIds.contains(id)) return;
    final next = {...state.dismissedIds, id};
    state = state.copyWith(dismissedIds: next);
    await _persistDismissed(next);
  }

  Future<void> _persistDismissed(Set<String> ids) async {
    final box = _box ?? _boxOverride;
    if (box == null) return;
    await box.put(_dismissedKey, ids.toList());
  }
}

final announcementProvider =
    StateNotifierProvider<AnnouncementNotifier, AnnouncementState>(
  (ref) => AnnouncementNotifier(),
);

/// Convenience: the single announcement to render on Home, if any.
final visibleAnnouncementProvider = Provider<Announcement?>((ref) {
  return ref.watch(announcementProvider).visible;
});
