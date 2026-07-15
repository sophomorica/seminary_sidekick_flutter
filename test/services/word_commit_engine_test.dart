import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/services/word_commit_engine.dart';

void main() {
  group('WordCommitEngine.normalize', () {
    test('lowercases and strips punctuation and whitespace', () {
      expect(WordCommitEngine.normalize('Check!'), 'check');
      expect(WordCommitEngine.normalize("Lord's"), 'lords');
      expect(WordCommitEngine.normalize('  world, '), 'world');
      expect(WordCommitEngine.normalize('HELLO'), 'hello');
    });

    test('keeps digits', () {
      expect(WordCommitEngine.normalize('2nd'), '2nd');
    });

    test('empty and punctuation-only input normalize to empty', () {
      expect(WordCommitEngine.normalize(''), '');
      expect(WordCommitEngine.normalize(' ,.— '), '');
    });
  });

  group('WordCommitEngine.tryCommit — basic matching', () {
    const target = 'In the beginning was the Word, and the Word was God.';

    test('correct word commits with trailing space absorbed', () {
      final r = WordCommitEngine.tryCommit(
          target: target, position: 0, buffer: 'In ');
      expect(r.status, WordCommitStatus.committed);
      expect(r.committedText, 'In ');
    });

    test('matching is case-insensitive and returns target casing', () {
      final r = WordCommitEngine.tryCommit(
          target: target, position: 0, buffer: 'in');
      expect(r.status, WordCommitStatus.committed);
      expect(r.committedText, 'In ');
    });

    test('wrong word is rejected', () {
      final r = WordCommitEngine.tryCommit(
          target: target, position: 0, buffer: 'On ');
      expect(r.status, WordCommitStatus.wrongWord);
      expect(r.committedText, isEmpty);
    });

    test('empty or whitespace-only buffer is nothingToCommit', () {
      expect(
        WordCommitEngine.tryCommit(target: target, position: 0, buffer: '')
            .status,
        WordCommitStatus.nothingToCommit,
      );
      expect(
        WordCommitEngine.tryCommit(target: target, position: 0, buffer: '  ')
            .status,
        WordCommitStatus.nothingToCommit,
      );
    });

    test('position at or past end of target is nothingToCommit', () {
      expect(
        WordCommitEngine.tryCommit(
                target: target, position: target.length, buffer: 'God')
            .status,
        WordCommitStatus.nothingToCommit,
      );
    });

    test('commit walks the whole target word by word', () {
      const words = [
        'in', 'the', 'beginning', 'was', 'the', 'word', // "Word,"
        'and', 'the', 'word', 'was', 'god', // "God."
      ];
      var position = 0;
      final committed = StringBuffer();
      for (final w in words) {
        final r = WordCommitEngine.tryCommit(
            target: target, position: position, buffer: '$w ');
        expect(r.status, WordCommitStatus.committed,
            reason: 'word "$w" at $position should commit');
        committed.write(r.committedText);
        position += r.committedText.length;
      }
      expect(committed.toString(), target);
    });
  });

  group('WordCommitEngine.tryCommit — punctuation forgiveness', () {
    test('trailing punctuation in target is absorbed into the commit', () {
      const target = 'the Word, and';
      final r = WordCommitEngine.tryCommit(
          target: target, position: 4, buffer: 'word ');
      expect(r.status, WordCommitStatus.committed);
      expect(r.committedText, 'Word, ');
    });

    test('punctuation typed by the user is ignored in the comparison', () {
      const target = 'the Word, and';
      final r = WordCommitEngine.tryCommit(
          target: target, position: 4, buffer: 'Word, ');
      expect(r.status, WordCommitStatus.committed);
      expect(r.committedText, 'Word, ');
    });

    test('apostrophe words match with or without the apostrophe', () {
      const target = "the Lord's word";
      for (final buffer in ['lords ', "Lord's "]) {
        final r = WordCommitEngine.tryCommit(
            target: target, position: 4, buffer: buffer);
        expect(r.status, WordCommitStatus.committed,
            reason: 'buffer "$buffer" should match');
        expect(r.committedText, "Lord's ");
      }
    });

    test('final word absorbs the closing period', () {
      const target = 'was God.';
      final r = WordCommitEngine.tryCommit(
          target: target, position: 4, buffer: 'god ');
      expect(r.status, WordCommitStatus.committed);
      expect(r.committedText, 'God.');
    });

    test('leading auto-fill at the position is skipped before matching', () {
      // Position sits on the comma+space left behind by a hypothetical
      // partial commit.
      const target = 'now, as I said';
      final r = WordCommitEngine.tryCommit(
          target: target, position: 3, buffer: 'as ');
      expect(r.status, WordCommitStatus.committed);
      expect(r.committedText, ', as ');
    });
  });

  group('WordCommitEngine.tryCommit — dash-joined words', () {
    const target = 'concerning faith—faith is not';

    test('each side of an em-dash can be committed separately', () {
      final first = WordCommitEngine.tryCommit(
          target: target, position: 11, buffer: 'faith ');
      expect(first.status, WordCommitStatus.committed);
      expect(first.committedText, 'faith—');

      final second = WordCommitEngine.tryCommit(
          target: target, position: 11 + first.committedText.length,
          buffer: 'faith ');
      expect(second.status, WordCommitStatus.committed);
      expect(second.committedText, 'faith ');
    });

    test('the full dash-joined span typed as one word also matches', () {
      final r = WordCommitEngine.tryCommit(
          target: target, position: 11, buffer: 'faithfaith ');
      expect(r.status, WordCommitStatus.committed);
      expect(r.committedText, 'faith—faith ');
    });

    test('a wrong word before a dash is still rejected', () {
      final r = WordCommitEngine.tryCommit(
          target: target, position: 11, buffer: 'faiths ');
      expect(r.status, WordCommitStatus.wrongWord);
    });
  });

  group('WordCommitEngine.tryCommit — multi-word spans', () {
    const target = 'In the beginning was the Word';

    test('an autocorrect-split buffer spanning two words commits both', () {
      final r = WordCommitEngine.tryCommit(
          target: target, position: 0, buffer: 'in the ');
      expect(r.status, WordCommitStatus.committed);
      expect(r.committedText, 'In the ');
    });

    test('spans up to maxTokensPerCommit words are accepted', () {
      final r = WordCommitEngine.tryCommit(
          target: target, position: 0, buffer: 'in the beginning was ');
      expect(r.status, WordCommitStatus.committed);
      expect(r.committedText, 'In the beginning was ');
    });

    test('spans longer than maxTokensPerCommit are rejected', () {
      final r = WordCommitEngine.tryCommit(
          target: target, position: 0, buffer: 'in the beginning was the ');
      expect(r.status, WordCommitStatus.wrongWord);
    });

    test('a two-word span with a wrong second word is rejected', () {
      final r = WordCommitEngine.tryCommit(
          target: target, position: 0, buffer: 'in thy ');
      expect(r.status, WordCommitStatus.wrongWord);
    });
  });
}
