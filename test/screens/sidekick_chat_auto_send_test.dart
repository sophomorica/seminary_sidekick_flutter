import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/screens/sidekick_chat/sidekick_chat_screen.dart';

void main() {
  group('isExplicitSidekickStarter', () {
    test('non-empty hot-button text is explicit', () {
      expect(isExplicitSidekickStarter('What does this verse mean?'), isTrue);
    });

    test('null is not explicit', () {
      expect(isExplicitSidekickStarter(null), isFalse);
    });

    test('whitespace-only is not explicit', () {
      expect(isExplicitSidekickStarter('   '), isFalse);
    });
  });

  group('decideSidekickAutoOpen', () {
    test('free users never auto-send', () {
      expect(
        decideSidekickAutoOpen(
          isPremium: false,
          initialMessage: 'What does this mean?',
          initialScriptureId: '1',
          chatIsEmpty: true,
        ),
        SidekickAutoOpenAction.none,
      );
    });

    test('hot-button starter clears and sends even with history', () {
      expect(
        decideSidekickAutoOpen(
          isPremium: true,
          initialMessage: 'Quiz me on this scripture.',
          initialScriptureId: '1',
          chatIsEmpty: false,
        ),
        SidekickAutoOpenAction.clearAndSendStarter,
      );
    });

    test('hot-button starter clears and sends on empty chat', () {
      expect(
        decideSidekickAutoOpen(
          isPremium: true,
          initialMessage: 'What does this mean?',
          initialScriptureId: null,
          chatIsEmpty: true,
        ),
        SidekickAutoOpenAction.clearAndSendStarter,
      );
    });

    test('scripture-only open sends generic opener only when empty', () {
      expect(
        decideSidekickAutoOpen(
          isPremium: true,
          initialMessage: null,
          initialScriptureId: '1',
          chatIsEmpty: true,
        ),
        SidekickAutoOpenAction.sendGenericIfEmpty,
      );
      expect(
        decideSidekickAutoOpen(
          isPremium: true,
          initialMessage: null,
          initialScriptureId: '1',
          chatIsEmpty: false,
        ),
        SidekickAutoOpenAction.none,
      );
    });

    test('whitespace message falls through to scripture-only rules', () {
      expect(
        decideSidekickAutoOpen(
          isPremium: true,
          initialMessage: '  ',
          initialScriptureId: '1',
          chatIsEmpty: true,
        ),
        SidekickAutoOpenAction.sendGenericIfEmpty,
      );
      expect(
        decideSidekickAutoOpen(
          isPremium: true,
          initialMessage: '  ',
          initialScriptureId: '1',
          chatIsEmpty: false,
        ),
        SidekickAutoOpenAction.none,
      );
    });

    test('no args means no auto-open action', () {
      expect(
        decideSidekickAutoOpen(
          isPremium: true,
          initialMessage: null,
          initialScriptureId: null,
          chatIsEmpty: true,
        ),
        SidekickAutoOpenAction.none,
      );
    });
  });
}
