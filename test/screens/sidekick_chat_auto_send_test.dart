import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/screens/sidekick_chat/sidekick_chat_screen.dart';

void main() {
  group('shouldAutoSendInitialMessage', () {
    test('explicit hot-button message always sends, even with history', () {
      expect(
        shouldAutoSendInitialMessage(
          initialMessage: 'What does this verse mean?',
          chatIsEmpty: false,
        ),
        isTrue,
      );
    });

    test('explicit hot-button message sends on empty chat', () {
      expect(
        shouldAutoSendInitialMessage(
          initialMessage: 'Quiz me on this scripture.',
          chatIsEmpty: true,
        ),
        isTrue,
      );
    });

    test('whitespace-only message is not treated as explicit', () {
      expect(
        shouldAutoSendInitialMessage(
          initialMessage: '   ',
          chatIsEmpty: false,
        ),
        isFalse,
      );
    });

    test('scripture-only open sends only when chat is empty', () {
      expect(
        shouldAutoSendInitialMessage(
          initialMessage: null,
          chatIsEmpty: true,
        ),
        isTrue,
      );
      expect(
        shouldAutoSendInitialMessage(
          initialMessage: null,
          chatIsEmpty: false,
        ),
        isFalse,
      );
    });
  });
}
