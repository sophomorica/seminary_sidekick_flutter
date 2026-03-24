import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// StateNotifier for managing per-scripture notes with Hive persistence.
class NotesNotifier extends StateNotifier<Map<String, String>> {
  static const _boxName = 'scripture_notes';
  late final Box<String> _box;

  NotesNotifier() : super({});

  /// Open the Hive box and load persisted notes into state.
  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
    final loaded = <String, String>{};
    for (final key in _box.keys) {
      final value = _box.get(key);
      if (value != null && value.isNotEmpty) {
        loaded[key as String] = value;
      }
    }
    state = loaded;
  }

  /// Save a note for a scripture. Empty string deletes the note.
  void saveNote(String scriptureId, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      state = Map.from(state)..remove(scriptureId);
      _box.delete(scriptureId);
    } else {
      state = {...state, scriptureId: trimmed};
      _box.put(scriptureId, trimmed);
    }
  }

  /// Get the note for a scripture, or null if none.
  String? getNote(String scriptureId) => state[scriptureId];
}

/// Provider for scripture notes.
final notesProvider = StateNotifierProvider<NotesNotifier, Map<String, String>>(
  (ref) => NotesNotifier(),
);

/// Family provider to get a note for a specific scripture.
final noteByScriptureProvider = Provider.family<String?, String>(
  (ref, scriptureId) {
    final notes = ref.watch(notesProvider);
    return notes[scriptureId];
  },
);
