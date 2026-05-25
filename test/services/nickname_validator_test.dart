import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/services/nickname_validator.dart';

void main() {
  group('NicknameValidator', () {
    setUp(() {
      // Each test starts with a fresh, deterministic in-memory wordlist.
      NicknameValidator.resetForTesting();
      NicknameValidator.loadWordsForTesting('''
badword
bypass
rude
stupid
loser
''');
    });

    tearDown(() {
      NicknameValidator.resetForTesting();
    });

    group('length', () {
      test('empty string is too short', () {
        expect(NicknameValidator.validate(''), isA<NicknameTooShort>());
      });

      test('single character is too short', () {
        expect(NicknameValidator.validate('a'), isA<NicknameTooShort>());
      });

      test('whitespace-only string is too short after trim', () {
        expect(NicknameValidator.validate('   '), isA<NicknameTooShort>());
      });

      test('two characters is valid', () {
        expect(NicknameValidator.validate('Al'), isA<NicknameValid>());
      });

      test('14 characters is valid', () {
        expect(
          NicknameValidator.validate('Patrick L Mart'),
          isA<NicknameValid>(),
        );
      });

      test('15 characters is too long', () {
        expect(
          NicknameValidator.validate('PatrickLMartine1'),
          isA<NicknameTooLong>(),
        );
      });
    });

    group('charset', () {
      test('emoji is rejected', () {
        expect(
          NicknameValidator.validate('Patrick 🎉'),
          isA<NicknameInvalidChars>(),
        );
      });

      test('punctuation is rejected', () {
        expect(
          NicknameValidator.validate('Patrick!'),
          isA<NicknameInvalidChars>(),
        );
      });

      test('underscore is rejected', () {
        expect(
          NicknameValidator.validate('cool_kid'),
          isA<NicknameInvalidChars>(),
        );
      });

      test('alphanumeric + spaces is accepted', () {
        expect(
          NicknameValidator.validate('Player 42'),
          isA<NicknameValid>(),
        );
      });
    });

    group('clean names', () {
      test('ordinary name passes', () {
        expect(NicknameValidator.validate('Sarah'), isA<NicknameValid>());
      });

      test('substring of a profanity word does NOT trigger (Cassandra)', () {
        // The seeded wordlist contains "rude" but does not contain "udo".
        // The seeded wordlist also contains "stupid"; "Stu" should not trigger.
        expect(NicknameValidator.validate('Stu'), isA<NicknameValid>());
        expect(
          NicknameValidator.validate('Cassandra'),
          isA<NicknameValid>(),
        );
      });

      test('partial-word containing seed letters is fine', () {
        // "loser" is in the list but "lose" alone is not — exact match only.
        expect(NicknameValidator.validate('Lose'), isA<NicknameValid>());
      });
    });

    group('profanity', () {
      test('exact match is caught', () {
        expect(
          NicknameValidator.validate('badword'),
          isA<NicknameProfanity>(),
        );
      });

      test('mixed case bypass is caught', () {
        expect(
          NicknameValidator.validate('BadWord'),
          isA<NicknameProfanity>(),
        );
      });

      test('l33t-speak bypass is caught (B@dW0rd → badword)', () {
        expect(
          NicknameValidator.validate('B@dW0rd'),
          isA<NicknameProfanity>(),
        );
      });

      test('l33t-speak bypass with multiple substitutions', () {
        // "b4dw0rd" → "badword" (4→a, 0→o)
        expect(
          NicknameValidator.validate('b4dw0rd'),
          isA<NicknameProfanity>(),
        );
      });

      test('spaces inserted between letters is caught', () {
        // "b a d w o r d" → stripped → "badword"
        expect(
          NicknameValidator.validate('b a d w o r d'),
          isA<NicknameProfanity>(),
        );
      });

      test('profanity as a separate word is caught', () {
        // tokens: ["the", "loser"] → "loser" hits.
        expect(
          NicknameValidator.validate('the loser'),
          isA<NicknameProfanity>(),
        );
      });
    });

    group('fail-open behavior', () {
      test('skips profanity check when wordlist not loaded', () {
        NicknameValidator.resetForTesting();
        // No wordlist loaded — length/charset still apply, but profanity does
        // not. The worst case is a missed hit, never a false positive.
        expect(
          NicknameValidator.validate('badword'),
          isA<NicknameValid>(),
        );
        expect(NicknameValidator.validate('a'), isA<NicknameTooShort>());
        expect(
          NicknameValidator.validate('cool!'),
          isA<NicknameInvalidChars>(),
        );
      });
    });
  });
}
