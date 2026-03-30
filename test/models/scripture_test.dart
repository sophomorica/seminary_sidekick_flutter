import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/models/scripture.dart';
import 'package:seminary_sidekick/models/enums.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('Scripture — word splitting', () {
    test('words are split from fullText', () {
      final scripture = testScriptures[0]; // test-1: 20 words
      expect(scripture.words, isNotEmpty);
      expect(scripture.words.length, 20);
      expect(scripture.words, everyElement(isNotEmpty));
    });

    test('wordCount matches words.length', () {
      for (final s in testScriptures) {
        expect(s.wordCount, equals(s.words.length),
            reason: '${s.reference} wordCount mismatch');
      }
    });

    test('words do not contain empty strings', () {
      for (final s in testScriptures) {
        expect(s.words, everyElement(isNot(equals(''))),
            reason: '${s.reference} has empty word');
      }
    });

    test('verse numbers are stripped from words', () {
      final scripture = Scripture(
        id: 'verse-num-test',
        book: ScriptureBook.bookOfMormon,
        volume: '1 Nephi',
        reference: '1 Nephi 3:7',
        name: 'Test',
        keyPhrase: 'Test',
        fullText: '7 And it came to pass',
      );
      // The leading "7 " should be stripped as a verse number
      expect(scripture.words.first, equals('And'));
      expect(scripture.words, isNot(contains('7')));
    });

    test('paragraph marks are stripped from words', () {
      final scripture = Scripture(
        id: 'para-test',
        book: ScriptureBook.bookOfMormon,
        volume: '1 Nephi',
        reference: '1 Nephi 3:7',
        name: 'Test',
        keyPhrase: 'Test',
        fullText: 'And it came ¶ to pass',
      );
      for (final word in scripture.words) {
        expect(word.contains('¶'), isFalse,
            reason: 'Word "$word" contains paragraph mark');
      }
    });

    test('multiple spaces are collapsed', () {
      final scripture = Scripture(
        id: 'space-test',
        book: ScriptureBook.bookOfMormon,
        volume: '1 Nephi',
        reference: '1 Nephi 3:7',
        name: 'Test',
        keyPhrase: 'Test',
        fullText: 'And   it   came   to   pass',
      );
      expect(scripture.words, equals(['And', 'it', 'came', 'to', 'pass']));
    });
  });

  group('Scripture — difficultyScore', () {
    test('short scripture (≤15 words) returns 1', () {
      // test-3 has 14 words
      expect(testScriptures[2].wordCount, lessThanOrEqualTo(15));
      expect(testScriptures[2].difficultyScore, equals(1));
    });

    test('medium scripture (≤30 words) returns 3', () {
      // test-1 has 20 words, test-4 has 18 words, test-2 has 24 words
      expect(testScriptures[0].wordCount, greaterThan(15));
      expect(testScriptures[0].wordCount, lessThanOrEqualTo(30));
      expect(testScriptures[0].difficultyScore, equals(3));
    });

    test('longer scripture (≤50 words) returns 5', () {
      final scripture = Scripture(
        id: 'diff-50',
        book: ScriptureBook.bookOfMormon,
        volume: 'Test',
        reference: 'Test 1:1',
        name: 'Test',
        keyPhrase: 'Test',
        fullText: List.generate(40, (i) => 'word$i').join(' '),
      );
      expect(scripture.wordCount, equals(40));
      expect(scripture.difficultyScore, equals(5));
    });

    test('long scripture (≤75 words) returns 7', () {
      final scripture = Scripture(
        id: 'diff-75',
        book: ScriptureBook.bookOfMormon,
        volume: 'Test',
        reference: 'Test 1:1',
        name: 'Test',
        keyPhrase: 'Test',
        fullText: List.generate(60, (i) => 'word$i').join(' '),
      );
      expect(scripture.wordCount, equals(60));
      expect(scripture.difficultyScore, equals(7));
    });

    test('very long scripture (>75 words) returns 10', () {
      final scripture = Scripture(
        id: 'diff-100',
        book: ScriptureBook.bookOfMormon,
        volume: 'Test',
        reference: 'Test 1:1',
        name: 'Test',
        keyPhrase: 'Test',
        fullText: List.generate(80, (i) => 'word$i').join(' '),
      );
      expect(scripture.wordCount, equals(80));
      expect(scripture.difficultyScore, equals(10));
    });

    test('boundary: exactly 15 words returns 1', () {
      final scripture = Scripture(
        id: 'diff-15',
        book: ScriptureBook.bookOfMormon,
        volume: 'Test',
        reference: 'Test 1:1',
        name: 'Test',
        keyPhrase: 'Test',
        fullText: List.generate(15, (i) => 'word$i').join(' '),
      );
      expect(scripture.wordCount, equals(15));
      expect(scripture.difficultyScore, equals(1));
    });

    test('boundary: exactly 30 words returns 3', () {
      final scripture = Scripture(
        id: 'diff-30',
        book: ScriptureBook.bookOfMormon,
        volume: 'Test',
        reference: 'Test 1:1',
        name: 'Test',
        keyPhrase: 'Test',
        fullText: List.generate(30, (i) => 'word$i').join(' '),
      );
      expect(scripture.wordCount, equals(30));
      expect(scripture.difficultyScore, equals(3));
    });
  });

  group('Scripture — copyWith', () {
    test('copyWith preserves all fields when no arguments passed', () {
      final original = testScriptures[0];
      final copy = original.copyWith();
      expect(copy.id, equals(original.id));
      expect(copy.book, equals(original.book));
      expect(copy.volume, equals(original.volume));
      expect(copy.reference, equals(original.reference));
      expect(copy.name, equals(original.name));
      expect(copy.keyPhrase, equals(original.keyPhrase));
      expect(copy.fullText, equals(original.fullText));
      expect(copy.userNotes, equals(original.userNotes));
    });

    test('copyWith updates userNotes', () {
      final original = testScriptures[0];
      final copy = original.copyWith(userNotes: 'My note');
      expect(copy.userNotes, equals('My note'));
      expect(copy.id, equals(original.id));
      expect(copy.reference, equals(original.reference));
    });

    test('copyWith with userNotes does not change other fields', () {
      final original = testScriptures[1];
      final copy = original.copyWith(userNotes: 'Test note');
      expect(copy.fullText, equals(original.fullText));
      expect(copy.words.length, equals(original.words.length));
    });
  });

  group('Scripture — equality', () {
    test('two scriptures with same id are equal', () {
      final a = testScriptures[0];
      final b = Scripture(
        id: a.id,
        book: ScriptureBook.newTestament, // different book
        volume: 'Different',
        reference: 'Different 1:1',
        name: 'Different',
        keyPhrase: 'Different',
        fullText: 'Different text entirely',
      );
      expect(a, equals(b));
    });

    test('two scriptures with different ids are not equal', () {
      expect(testScriptures[0], isNot(equals(testScriptures[1])));
    });

    test('hashCode is consistent with equality', () {
      final a = testScriptures[0];
      final b = Scripture(
        id: a.id,
        book: ScriptureBook.newTestament,
        volume: 'Different',
        reference: 'Different 1:1',
        name: 'Different',
        keyPhrase: 'Different',
        fullText: 'Different text',
      );
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different ids produce different hashCodes', () {
      // Not guaranteed by contract but practically expected
      expect(testScriptures[0].hashCode,
          isNot(equals(testScriptures[1].hashCode)));
    });

    test('identical scripture is equal to itself', () {
      final s = testScriptures[0];
      expect(s, equals(s));
    });
  });

  group('Scripture — toString', () {
    test('toString contains reference and name', () {
      final s = testScriptures[0];
      final str = s.toString();
      expect(str, contains(s.reference));
      expect(str, contains(s.name));
    });
  });
}
