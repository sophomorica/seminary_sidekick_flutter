import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seminary_sidekick/models/enums.dart';
import 'package:seminary_sidekick/models/scripture.dart';
import 'package:seminary_sidekick/providers/scripture_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  // ---------------------------------------------------------------------------
  // scripturesProvider
  // ---------------------------------------------------------------------------
  group('scripturesProvider', () {
    test('returns exactly 100 scriptures', () {
      final scriptures = container.read(scripturesProvider);
      expect(scriptures.length, 100);
    });

    test('every scripture has a non-empty id', () {
      final scriptures = container.read(scripturesProvider);
      for (final s in scriptures) {
        expect(s.id, isNotEmpty);
      }
    });

    test('every scripture has non-empty required fields', () {
      final scriptures = container.read(scripturesProvider);
      for (final s in scriptures) {
        expect(s.reference, isNotEmpty);
        expect(s.name, isNotEmpty);
        expect(s.keyPhrase, isNotEmpty);
        expect(s.fullText, isNotEmpty);
        expect(s.volume, isNotEmpty);
      }
    });

    test('all scripture ids are unique', () {
      final scriptures = container.read(scripturesProvider);
      final ids = scriptures.map((s) => s.id).toSet();
      expect(ids.length, scriptures.length);
    });
  });

  // ---------------------------------------------------------------------------
  // scripturesByBookProvider
  // ---------------------------------------------------------------------------
  group('scripturesByBookProvider', () {
    test('filters correctly for each book', () {
      for (final book in ScriptureBook.values) {
        final filtered = container.read(scripturesByBookProvider(book));
        expect(filtered, isNotEmpty,
            reason: '${book.displayName} should have at least 1 scripture');
        for (final s in filtered) {
          expect(s.book, book);
        }
      }
    });

    test('all book counts sum to 100', () {
      int total = 0;
      for (final book in ScriptureBook.values) {
        total += container.read(scripturesByBookProvider(book)).length;
      }
      expect(total, 100);
    });

    test('no book returns an empty list', () {
      for (final book in ScriptureBook.values) {
        final filtered = container.read(scripturesByBookProvider(book));
        expect(filtered, isNotEmpty,
            reason: '${book.displayName} should not be empty');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // scriptureByIdProvider
  // ---------------------------------------------------------------------------
  group('scriptureByIdProvider', () {
    test('valid id returns the correct scripture', () {
      final all = container.read(scripturesProvider);
      final target = all.first;
      final result = container.read(scriptureByIdProvider(target.id));
      expect(result, isNotNull);
      expect(result!.id, target.id);
      expect(result.reference, target.reference);
    });

    test('returns null for an invalid id', () {
      final result =
          container.read(scriptureByIdProvider('nonexistent-id-xyz'));
      expect(result, isNull);
    });

    test('returns null for an empty id', () {
      final result = container.read(scriptureByIdProvider(''));
      expect(result, isNull);
    });

    test('can look up every scripture by its id', () {
      final all = container.read(scripturesProvider);
      for (final s in all) {
        final found = container.read(scriptureByIdProvider(s.id));
        expect(found, isNotNull, reason: 'Should find scripture ${s.id}');
        expect(found!.id, s.id);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // searchScripturesProvider
  // ---------------------------------------------------------------------------
  group('searchScripturesProvider', () {
    test('empty query returns all scriptures', () {
      final results = container.read(searchScripturesProvider(''));
      expect(results.length, 100);
    });

    test('search by reference finds matching scriptures', () {
      // Pick a known scripture reference from the real data
      final all = container.read(scripturesProvider);
      final target = all.first;
      final results =
          container.read(searchScripturesProvider(target.reference));
      expect(results, isNotEmpty);
      expect(results.any((s) => s.id == target.id), isTrue);
    });

    test('search by name finds matching scriptures', () {
      final all = container.read(scripturesProvider);
      final target = all.first;
      final results = container.read(searchScripturesProvider(target.name));
      expect(results, isNotEmpty);
      expect(results.any((s) => s.id == target.id), isTrue);
    });

    test('search by key phrase finds matching scriptures', () {
      final all = container.read(scripturesProvider);
      final target = all.first;
      final results =
          container.read(searchScripturesProvider(target.keyPhrase));
      expect(results, isNotEmpty);
      expect(results.any((s) => s.id == target.id), isTrue);
    });

    test('search is case insensitive', () {
      final all = container.read(scripturesProvider);
      final target = all.first;
      final upperResults =
          container.read(searchScripturesProvider(target.name.toUpperCase()));
      final lowerResults =
          container.read(searchScripturesProvider(target.name.toLowerCase()));
      expect(upperResults.length, lowerResults.length);
      expect(upperResults.any((s) => s.id == target.id), isTrue);
      expect(lowerResults.any((s) => s.id == target.id), isTrue);
    });

    test('no match returns empty list', () {
      final results = container
          .read(searchScripturesProvider('zzzznonexistentqueryxyz123'));
      expect(results, isEmpty);
    });

    test('partial reference match works', () {
      // Search for a partial string that should match at least one scripture
      final all = container.read(scripturesProvider);
      final target = all.first;
      // Use first 5 characters of the reference as a partial query
      final partial = target.reference.substring(0, 5);
      final results = container.read(searchScripturesProvider(partial));
      expect(results, isNotEmpty);
    });
  });
}
