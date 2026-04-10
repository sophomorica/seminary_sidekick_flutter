import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/models/journal_entry.dart';

void main() {
  group('JournalEntry', () {
    final now = DateTime(2026, 4, 9, 12, 0, 0);

    JournalEntry makeEntry({
      String id = 'entry-1',
      String title = 'My Entry',
      String content = 'Some journal content here',
      List<String> scriptureIds = const ['1', '2'],
      List<String> scriptureReferences = const ['1 Nephi 3:7', 'John 3:16'],
      String? prompt,
      bool isFavorite = false,
    }) {
      return JournalEntry(
        id: id,
        title: title,
        content: content,
        scriptureIds: scriptureIds,
        scriptureReferences: scriptureReferences,
        prompt: prompt,
        createdAt: now,
        updatedAt: now,
        isFavorite: isFavorite,
      );
    }

    group('construction', () {
      test('creates with required fields', () {
        final entry = makeEntry();
        expect(entry.id, 'entry-1');
        expect(entry.title, 'My Entry');
        expect(entry.content, 'Some journal content here');
        expect(entry.scriptureIds, ['1', '2']);
        expect(entry.scriptureReferences, ['1 Nephi 3:7', 'John 3:16']);
        expect(entry.prompt, isNull);
        expect(entry.isFavorite, false);
        expect(entry.createdAt, now);
        expect(entry.updatedAt, now);
      });

      test('defaults for optional fields', () {
        final entry = JournalEntry(
          id: 'x',
          title: '',
          content: '',
          createdAt: now,
          updatedAt: now,
        );
        expect(entry.scriptureIds, isEmpty);
        expect(entry.scriptureReferences, isEmpty);
        expect(entry.prompt, isNull);
        expect(entry.isFavorite, false);
      });
    });

    group('copyWith', () {
      test('copies with new title', () {
        final original = makeEntry();
        final copy = original.copyWith(title: 'New Title');
        expect(copy.title, 'New Title');
        expect(copy.id, original.id);
        expect(copy.content, original.content);
        expect(copy.createdAt, original.createdAt);
      });

      test('copies with modified content', () {
        final copy = makeEntry().copyWith(content: 'Updated content');
        expect(copy.content, 'Updated content');
      });

      test('copies with new scripture tags', () {
        final copy = makeEntry().copyWith(
          scriptureIds: ['3'],
          scriptureReferences: ['Proverbs 3:5-6'],
        );
        expect(copy.scriptureIds, ['3']);
        expect(copy.scriptureReferences, ['Proverbs 3:5-6']);
      });

      test('copies with isFavorite toggled', () {
        final copy = makeEntry().copyWith(isFavorite: true);
        expect(copy.isFavorite, true);
      });

      test('copies with new updatedAt', () {
        final later = now.add(const Duration(hours: 1));
        final copy = makeEntry().copyWith(updatedAt: later);
        expect(copy.updatedAt, later);
        expect(copy.createdAt, now); // createdAt unchanged
      });

      test('preserves id and createdAt', () {
        final copy = makeEntry().copyWith(title: 'X');
        expect(copy.id, 'entry-1');
        expect(copy.createdAt, now);
      });
    });

    group('computed properties', () {
      test('isEmpty is true for blank content', () {
        expect(makeEntry(content: '').isEmpty, true);
        expect(makeEntry(content: '   ').isEmpty, true);
        expect(makeEntry(content: '\n  \t').isEmpty, true);
      });

      test('isEmpty is false for non-blank content', () {
        expect(makeEntry(content: 'Hello').isEmpty, false);
      });

      test('hasPrompt is true when prompt is non-empty', () {
        expect(makeEntry(prompt: 'Reflect on this').hasPrompt, true);
      });

      test('hasPrompt is false when prompt is null or empty', () {
        expect(makeEntry(prompt: null).hasPrompt, false);
        expect(makeEntry(prompt: '').hasPrompt, false);
      });

      test('preview returns full content when <= 100 chars', () {
        final entry = makeEntry(content: 'Short text');
        expect(entry.preview, 'Short text');
      });

      test('preview truncates at 100 chars with ellipsis', () {
        final longContent = 'A' * 150;
        final entry = makeEntry(content: longContent);
        expect(entry.preview.length, 103); // 100 + '...'
        expect(entry.preview.endsWith('...'), true);
      });

      test('preview returns empty string for empty content', () {
        expect(makeEntry(content: '').preview, '');
      });

      test('preview trims whitespace', () {
        final entry = makeEntry(content: '   Hello   ');
        expect(entry.preview, 'Hello');
      });
    });

    group('JSON serialization', () {
      test('toJson includes all fields', () {
        final entry = makeEntry(prompt: 'Think about this');
        final json = entry.toJson();

        expect(json['id'], 'entry-1');
        expect(json['title'], 'My Entry');
        expect(json['content'], 'Some journal content here');
        expect(json['scriptureIds'], ['1', '2']);
        expect(json['scriptureReferences'], ['1 Nephi 3:7', 'John 3:16']);
        expect(json['prompt'], 'Think about this');
        expect(json['createdAt'], now.toIso8601String());
        expect(json['updatedAt'], now.toIso8601String());
        expect(json['isFavorite'], false);
      });

      test('toJson omits prompt when null', () {
        final json = makeEntry(prompt: null).toJson();
        expect(json.containsKey('prompt'), false);
      });

      test('fromJson parses all fields', () {
        final json = makeEntry(prompt: 'Some prompt', isFavorite: true).toJson();
        final parsed = JournalEntry.fromJson(json);

        expect(parsed.id, 'entry-1');
        expect(parsed.title, 'My Entry');
        expect(parsed.content, 'Some journal content here');
        expect(parsed.scriptureIds, ['1', '2']);
        expect(parsed.scriptureReferences, ['1 Nephi 3:7', 'John 3:16']);
        expect(parsed.prompt, 'Some prompt');
        expect(parsed.isFavorite, true);
      });

      test('fromJson handles missing optional fields', () {
        final json = {
          'id': 'x',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };
        final parsed = JournalEntry.fromJson(json);
        expect(parsed.title, '');
        expect(parsed.content, '');
        expect(parsed.scriptureIds, isEmpty);
        expect(parsed.scriptureReferences, isEmpty);
        expect(parsed.prompt, isNull);
        expect(parsed.isFavorite, false);
      });

      test('roundtrip: toJson → fromJson preserves data', () {
        final original = makeEntry(prompt: 'Prompt', isFavorite: true);
        final roundtripped = JournalEntry.fromJson(original.toJson());

        expect(roundtripped.id, original.id);
        expect(roundtripped.title, original.title);
        expect(roundtripped.content, original.content);
        expect(roundtripped.scriptureIds, original.scriptureIds);
        expect(roundtripped.scriptureReferences, original.scriptureReferences);
        expect(roundtripped.prompt, original.prompt);
        expect(roundtripped.isFavorite, original.isFavorite);
      });
    });

    group('factory create', () {
      test('creates empty entry with defaults', () {
        final entry = JournalEntry.create();
        expect(entry.title, '');
        expect(entry.content, '');
        expect(entry.scriptureIds, isEmpty);
        expect(entry.scriptureReferences, isEmpty);
        expect(entry.prompt, isNull);
        expect(entry.isFavorite, false);
        expect(entry.id, isNotEmpty);
      });

      test('creates entry with prompt', () {
        final entry = JournalEntry.create(prompt: 'Think deeply');
        expect(entry.prompt, 'Think deeply');
      });

      test('creates entry with scripture pre-tagged', () {
        final entry = JournalEntry.create(
          scriptureId: '42',
          scriptureReference: 'Mosiah 3:19',
        );
        expect(entry.scriptureIds, ['42']);
        expect(entry.scriptureReferences, ['Mosiah 3:19']);
      });

      test('creates entry with both prompt and scripture', () {
        final entry = JournalEntry.create(
          prompt: 'Reflect on this',
          scriptureId: '1',
          scriptureReference: '1 Nephi 3:7',
        );
        expect(entry.prompt, 'Reflect on this');
        expect(entry.scriptureIds, ['1']);
      });

      test('id is based on timestamp', () {
        final entry = JournalEntry.create();
        // Should be a valid ISO timestamp
        expect(() => DateTime.parse(entry.id), returnsNormally);
      });

      test('createdAt and updatedAt are equal on creation', () {
        final entry = JournalEntry.create();
        expect(entry.createdAt, entry.updatedAt);
      });
    });
  });
}
