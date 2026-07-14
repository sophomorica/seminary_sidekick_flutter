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
}
