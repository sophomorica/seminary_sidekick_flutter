import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:seminary_sidekick/providers/journal_provider.dart';
import 'package:seminary_sidekick/models/journal_entry.dart';

void main() {
  late JournalNotifier notifier;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_journal_test_');
    Hive.init(tempDir.path);
    notifier = JournalNotifier();
    await notifier.init();
  });

  tearDown(() async {
    // Allow fire-and-forget persist calls to complete
    await Future.delayed(const Duration(milliseconds: 50));
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  // ─── JournalState ──────────────────────────────────────────────────

  group('JournalState', () {
    test('defaults', () {
      const state = JournalState();
      expect(state.entries, isEmpty);
      expect(state.activeEntry, isNull);
      expect(state.isSaving, false);
    });

    test('copyWith entries', () {
      const state = JournalState();
      final entry = JournalEntry.create();
      final copy = state.copyWith(entries: [entry]);
      expect(copy.entries, hasLength(1));
    });

    test('copyWith clearActiveEntry', () {
      final entry = JournalEntry.create();
      final state = JournalState(activeEntry: entry);
      final copy = state.copyWith(clearActiveEntry: true);
      expect(copy.activeEntry, isNull);
    });
  });

  // ─── JournalNotifier ──────────────────────────────────────────────

  group('JournalNotifier', () {
    test('initializes with empty state', () {
      expect(notifier.state.entries, isEmpty);
      expect(notifier.state.activeEntry, isNull);
    });

    group('createEntry', () {
      test('creates empty entry and sets as active', () {
        final entry = notifier.createEntry();
        expect(entry.title, '');
        expect(entry.content, '');
        expect(notifier.state.activeEntry, isNotNull);
        expect(notifier.state.activeEntry!.id, entry.id);
      });

      test('creates entry with prompt', () {
        final entry = notifier.createEntry(prompt: 'How does this apply?');
        expect(entry.prompt, 'How does this apply?');
      });

      test('creates entry with scripture pre-tagged', () {
        final entry = notifier.createEntry(
          scriptureId: '42',
          scriptureReference: 'Mosiah 3:19',
        );
        expect(entry.scriptureIds, ['42']);
        expect(entry.scriptureReferences, ['Mosiah 3:19']);
      });
    });

    group('saveEntry', () {
      test('saves entry with content', () async {
        notifier.createEntry();
        await notifier.saveEntry(title: 'My Entry', content: 'Some content');

        expect(notifier.state.entries, hasLength(1));
        expect(notifier.state.entries.first.title, 'My Entry');
        expect(notifier.state.entries.first.content, 'Some content');
      });

      test('auto-generates title from content when title is empty', () async {
        notifier.createEntry();
        await notifier.saveEntry(title: '', content: 'First line of content');

        expect(notifier.state.entries.first.title, 'First line of content');
      });

      test('auto-generates title from prompt when content is empty', () async {
        notifier.createEntry(prompt: 'Reflect on this verse');
        await notifier.saveEntry(title: '', content: '');

        expect(notifier.state.entries.first.title, 'Reflect on this verse');
      });

      test('auto-generates fallback title when everything empty', () async {
        notifier.createEntry();
        await notifier.saveEntry(title: '', content: '');

        expect(notifier.state.entries.first.title, 'Journal Entry');
      });

      test('truncates long auto-generated title', () async {
        notifier.createEntry();
        final longContent = 'A' * 100;
        await notifier.saveEntry(title: '', content: longContent);

        expect(
            notifier.state.entries.first.title.length, lessThanOrEqualTo(60));
        expect(notifier.state.entries.first.title.endsWith('...'), true);
      });

      test('updates existing entry instead of creating duplicate', () async {
        notifier.createEntry();
        await notifier.saveEntry(title: 'V1', content: 'Content 1');

        final saved = notifier.state.entries.first;
        notifier.editEntry(saved);
        await notifier.saveEntry(title: 'V2', content: 'Content 2');

        expect(notifier.state.entries, hasLength(1));
        expect(notifier.state.entries.first.title, 'V2');
      });

      test('saves scripture tags', () async {
        notifier.createEntry();
        await notifier.saveEntry(
          title: 'Tagged',
          content: 'Content',
          scriptureIds: ['1', '2'],
          scriptureReferences: ['1 Nephi 3:7', 'John 3:16'],
        );

        final saved = notifier.state.entries.first;
        expect(saved.scriptureIds, ['1', '2']);
        expect(saved.scriptureReferences, ['1 Nephi 3:7', 'John 3:16']);
      });

      test('does nothing when no active entry', () async {
        await notifier.saveEntry(title: 'X', content: 'Y');
        expect(notifier.state.entries, isEmpty);
      });
    });

    group('editEntry', () {
      test('sets entry as active for editing', () async {
        notifier.createEntry();
        await notifier.saveEntry(title: 'Test', content: 'Content');
        notifier.closeEditor();

        final entry = notifier.state.entries.first;
        notifier.editEntry(entry);
        expect(notifier.state.activeEntry?.id, entry.id);
      });
    });

    group('toggleFavorite', () {
      test('toggles favorite on entry', () async {
        notifier.createEntry();
        await notifier.saveEntry(title: 'Test', content: 'Content');
        final id = notifier.state.entries.first.id;

        expect(notifier.state.entries.first.isFavorite, false);

        await notifier.toggleFavorite(id);
        expect(notifier.state.entries.first.isFavorite, true);

        await notifier.toggleFavorite(id);
        expect(notifier.state.entries.first.isFavorite, false);
      });

      test('also updates active entry if same', () async {
        notifier.createEntry();
        await notifier.saveEntry(title: 'Test', content: 'Content');
        final entry = notifier.state.entries.first;
        notifier.editEntry(entry);

        await notifier.toggleFavorite(entry.id);
        expect(notifier.state.activeEntry?.isFavorite, true);
      });

      test('no-op for non-existent entry', () async {
        await notifier.toggleFavorite('nonexistent');
        // Should not throw
      });
    });

    group('deleteEntry', () {
      test('removes entry from list', () async {
        notifier.createEntry();
        await notifier.saveEntry(title: 'Test', content: 'Content');
        final id = notifier.state.entries.first.id;

        expect(notifier.state.entries, hasLength(1));
        await notifier.deleteEntry(id);
        expect(notifier.state.entries, isEmpty);
      });

      test('clears active entry if deleting the one being edited', () async {
        notifier.createEntry();
        await notifier.saveEntry(title: 'Test', content: 'Content');
        final entry = notifier.state.entries.first;
        notifier.editEntry(entry);

        await notifier.deleteEntry(entry.id);
        expect(notifier.state.activeEntry, isNull);
      });

      test('preserves active entry if deleting a different one', () async {
        notifier.createEntry();
        await notifier.saveEntry(title: 'Entry 1', content: 'Content 1');
        notifier.createEntry();
        await notifier.saveEntry(title: 'Entry 2', content: 'Content 2');

        final first = notifier.state.entries.last; // oldest
        final second = notifier.state.entries.first; // newest
        notifier.editEntry(second);

        await notifier.deleteEntry(first.id);
        expect(notifier.state.activeEntry?.id, second.id);
        expect(notifier.state.entries, hasLength(1));
      });
    });

    group('closeEditor', () {
      test('clears active entry', () {
        notifier.createEntry();
        expect(notifier.state.activeEntry, isNotNull);

        notifier.closeEditor();
        expect(notifier.state.activeEntry, isNull);
      });
    });

    group('sorting', () {
      test('entries are sorted newest first', () async {
        notifier.createEntry();
        await notifier.saveEntry(title: 'Old', content: 'Old content');

        // Small delay so timestamps differ
        await Future.delayed(const Duration(milliseconds: 10));

        notifier.createEntry();
        await notifier.saveEntry(title: 'New', content: 'New content');

        expect(notifier.state.entries.first.title, 'New');
        expect(notifier.state.entries.last.title, 'Old');
      });
    });

    group('persistence', () {
      test('persists entries and restores on init', () async {
        notifier.createEntry();
        await notifier.saveEntry(title: 'Persisted', content: 'Content');

        // Create a new notifier (simulating app restart)
        final restored = JournalNotifier();
        await restored.init();

        expect(restored.state.entries, hasLength(1));
        expect(restored.state.entries.first.title, 'Persisted');
      });

      test('delete persists removal', () async {
        notifier.createEntry();
        await notifier.saveEntry(title: 'To Delete', content: 'Content');
        await notifier.deleteEntry(notifier.state.entries.first.id);

        final restored = JournalNotifier();
        await restored.init();
        expect(restored.state.entries, isEmpty);
      });
    });
  });
}
