import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/screens/games/scripture_builder/typed_display_rules.dart';

void main() {
  group('firstLetterIndices', () {
    test('marks the first letter of each space-separated word', () {
      const target = 'For God so loved';
      expect(TypedDisplayRules.firstLetterIndices(target), {0, 4, 8, 11});
    });

    test('treats newlines as word boundaries', () {
      const target = 'one\ntwo';
      expect(TypedDisplayRules.firstLetterIndices(target), {0, 4});
    });

    test('skips leading punctuation so the hint is the first real letter', () {
      const target = '"Behold, (my) word';
      expect(TypedDisplayRules.firstLetterIndices(target), {1, 10, 14});
    });

    test('mid-word punctuation does not start a new word', () {
      const target = "self-made o'clock";
      expect(TypedDisplayRules.firstLetterIndices(target), {0, 10});
    });

    test('never contains punctuation or whitespace indices', () {
      const target = '"And it came — to pass," he said.';
      final hints = TypedDisplayRules.firstLetterIndices(target);
      for (final i in hints) {
        final ch = target[i];
        expect(ch == ' ' || ch == '\n', isFalse,
            reason: 'index $i is whitespace');
        expect(TypedDisplayRules.punctuation.hasMatch(ch), isFalse,
            reason: 'index $i ("$ch") is punctuation');
      }
    });
  });

  group('nextLetterIndex', () {
    test('returns from when it already points at a letter', () {
      expect(TypedDisplayRules.nextLetterIndex('abc', 1), 1);
    });

    test('skips spaces and auto-filled punctuation', () {
      const target = 'go, ye';
      expect(TypedDisplayRules.nextLetterIndex(target, 2), 4);
    });

    test('returns -1 when only auto-fill characters remain', () {
      const target = 'end."';
      expect(TypedDisplayRules.nextLetterIndex(target, 3), -1);
    });

    test('returns -1 at end of text', () {
      const target = 'end';
      expect(TypedDisplayRules.nextLetterIndex(target, 3), -1);
    });
  });

  group('untypedGlyph', () {
    const target = '"For God—so loved," he\nsaid';

    test('Advanced never discloses a non-hint letter (MAINT-006)', () {
      final hints = TypedDisplayRules.firstLetterIndices(target);
      for (var i = 0; i < target.length; i++) {
        final glyph = TypedDisplayRules.untypedGlyph(
          target,
          i,
          isMaster: false,
          hintIndices: hints,
        );
        final ch = target[i];
        if (ch == ' ' || ch == '\n') {
          expect(glyph, ch, reason: 'whitespace at $i must be preserved');
        } else if (hints.contains(i)) {
          expect(glyph, ch, reason: 'hint at $i must be shown');
        } else {
          expect(glyph, '_', reason: 'index $i ("$ch") must stay hidden');
        }
      }
    });

    test('Master blanks everything except whitespace, including hints', () {
      final hints = TypedDisplayRules.firstLetterIndices(target);
      for (var i = 0; i < target.length; i++) {
        final glyph = TypedDisplayRules.untypedGlyph(
          target,
          i,
          isMaster: true,
          hintIndices: hints,
        );
        final ch = target[i];
        expect(glyph, ch == ' ' || ch == '\n' ? ch : '_');
      }
    });
  });

  test('punctuation set matches the provider auto-fill characters', () {
    // Spot-check the characters the provider auto-fills; if this drifts
    // from _punctuation in scripture_builder_provider.dart, the cursor
    // could land on a slot the user never types.
    const autoFilled = [',', ';', ':', '!', '?', '-', '—', '–', '.',
        "'", '"', '(', ')', '[', ']'];
    for (final ch in autoFilled) {
      expect(TypedDisplayRules.punctuation.hasMatch(ch), isTrue,
          reason: '"$ch" should be treated as auto-filled punctuation');
    }
  });
}
