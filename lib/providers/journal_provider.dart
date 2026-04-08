import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/journal_entry.dart';
import '../providers/sidekick_provider.dart';

// ─── State ──────────────────────────────────────────────────────────────────

/// State for the journal feature.
class JournalState {
  /// All journal entries, sorted newest first.
  final List<JournalEntry> entries;

  /// The entry currently being edited (null = list view).
  final JournalEntry? activeEntry;

  /// Whether we're saving.
  final bool isSaving;

  const JournalState({
    this.entries = const [],
    this.activeEntry,
    this.isSaving = false,
  });

  JournalState copyWith({
    List<JournalEntry>? entries,
    JournalEntry? activeEntry,
    bool? isSaving,
    bool clearActiveEntry = false,
  }) {
    return JournalState(
      entries: entries ?? this.entries,
      activeEntry: clearActiveEntry ? null : (activeEntry ?? this.activeEntry),
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

// ─── Notifier ───────────────────────────────────────────────────────────────

/// Manages journal entries with Hive persistence.
///
/// Entries are stored as JSON strings in a Hive box, keyed by their ID.
class JournalNotifier extends StateNotifier<JournalState> {
  static const String _boxName = 'journal_entries';

  JournalNotifier() : super(const JournalState());

  /// Load all entries from Hive.
  Future<void> init() async {
    final box = await Hive.openBox<String>(_boxName);
    final entries = <JournalEntry>[];

    for (final key in box.keys) {
      try {
        final jsonStr = box.get(key);
        if (jsonStr != null) {
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          entries.add(JournalEntry.fromJson(json));
        }
      } catch (_) {
        // Skip corrupt entries
      }
    }

    // Sort newest first
    entries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = state.copyWith(entries: entries);
  }

  /// Create a new journal entry, optionally seeded with a prompt and scripture.
  JournalEntry createEntry({
    String? prompt,
    String? scriptureId,
    String? scriptureReference,
  }) {
    final entry = JournalEntry.create(
      prompt: prompt,
      scriptureId: scriptureId,
      scriptureReference: scriptureReference,
    );
    state = state.copyWith(activeEntry: entry);
    return entry;
  }

  /// Open an existing entry for editing.
  void editEntry(JournalEntry entry) {
    state = state.copyWith(activeEntry: entry);
  }

  /// Save the current active entry (create or update).
  Future<void> saveEntry({
    required String title,
    required String content,
    List<String>? scriptureIds,
    List<String>? scriptureReferences,
  }) async {
    final active = state.activeEntry;
    if (active == null) return;

    state = state.copyWith(isSaving: true);

    final now = DateTime.now();
    final updated = active.copyWith(
      title: title.isNotEmpty ? title : _generateTitle(content, active.prompt),
      content: content,
      scriptureIds: scriptureIds,
      scriptureReferences: scriptureReferences,
      updatedAt: now,
    );

    // Persist to Hive
    try {
      final box = Hive.box<String>(_boxName);
      await box.put(updated.id, jsonEncode(updated.toJson()));
    } catch (_) {
      // Persist failure is non-fatal
    }

    // Update entries list
    final entries = List<JournalEntry>.from(state.entries);
    final existingIndex = entries.indexWhere((e) => e.id == updated.id);
    if (existingIndex >= 0) {
      entries[existingIndex] = updated;
    } else {
      entries.insert(0, updated);
    }
    entries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    state = state.copyWith(
      entries: entries,
      activeEntry: updated,
      isSaving: false,
    );
  }

  /// Toggle favorite on an entry.
  Future<void> toggleFavorite(String entryId) async {
    final entries = List<JournalEntry>.from(state.entries);
    final index = entries.indexWhere((e) => e.id == entryId);
    if (index < 0) return;

    final updated = entries[index].copyWith(
      isFavorite: !entries[index].isFavorite,
      updatedAt: DateTime.now(),
    );
    entries[index] = updated;

    state = state.copyWith(entries: entries);

    // Also update active entry if it's the same
    if (state.activeEntry?.id == entryId) {
      state = state.copyWith(activeEntry: updated);
    }

    // Persist
    try {
      final box = Hive.box<String>(_boxName);
      await box.put(updated.id, jsonEncode(updated.toJson()));
    } catch (_) {}
  }

  /// Delete an entry.
  Future<void> deleteEntry(String entryId) async {
    final entries = state.entries.where((e) => e.id != entryId).toList();
    state = state.copyWith(
      entries: entries,
      clearActiveEntry: state.activeEntry?.id == entryId,
    );

    try {
      final box = Hive.box<String>(_boxName);
      await box.delete(entryId);
    } catch (_) {}
  }

  /// Close the active entry editor (go back to list).
  void closeEditor() {
    state = state.copyWith(clearActiveEntry: true);
  }

  /// Generate a default title from content or prompt.
  String _generateTitle(String content, String? prompt) {
    if (content.trim().isNotEmpty) {
      final firstLine = content.trim().split('\n').first;
      if (firstLine.length <= 60) return firstLine;
      return '${firstLine.substring(0, 57)}...';
    }
    if (prompt != null && prompt.isNotEmpty) {
      if (prompt.length <= 60) return prompt;
      return '${prompt.substring(0, 57)}...';
    }
    return 'Journal Entry';
  }
}

// ─── Providers ──────────────────────────────────────────────────────────────

final journalProvider =
    StateNotifierProvider<JournalNotifier, JournalState>(
  (ref) => JournalNotifier(),
);

/// All entries.
final journalEntriesProvider = Provider<List<JournalEntry>>((ref) {
  return ref.watch(journalProvider).entries;
});

/// The entry currently being edited, if any.
final activeJournalEntryProvider = Provider<JournalEntry?>((ref) {
  return ref.watch(journalProvider).activeEntry;
});

/// Entries tagged with a specific scripture.
final journalEntriesByScriptureProvider =
    Provider.family<List<JournalEntry>, String>((ref, scriptureId) {
  return ref
      .watch(journalEntriesProvider)
      .where((e) => e.scriptureIds.contains(scriptureId))
      .toList();
});

/// Favorites only.
final favoriteJournalEntriesProvider = Provider<List<JournalEntry>>((ref) {
  return ref
      .watch(journalEntriesProvider)
      .where((e) => e.isFavorite)
      .toList();
});

/// Total journal entry count.
final journalEntryCountProvider = Provider<int>((ref) {
  return ref.watch(journalEntriesProvider).length;
});

/// Current reflection prompts from the Sidekick (convenience re-export).
final currentReflectionPromptsProvider = Provider<List<String>>((ref) {
  return ref.watch(reflectionPromptsProvider);
});
