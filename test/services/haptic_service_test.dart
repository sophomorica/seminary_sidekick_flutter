import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/services/haptic_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // -------------------------------------------------------
  // Track platform channel calls to verify haptic behavior.
  // Flutter's HapticFeedback.* calls go through the
  // SystemChannels.platform method channel.
  // -------------------------------------------------------
  late List<String> hapticCalls;

  setUp(() {
    hapticCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        hapticCalls.add(methodCall.method);
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  // -------------------------------------------------------
  // Enabled state
  // -------------------------------------------------------
  group('when enabled', () {
    test('light() triggers HapticFeedback.lightImpact', () {
      const service = HapticService.enabled();
      service.light();
      expect(hapticCalls, contains('HapticFeedback.vibrate'));
    });

    test('medium() triggers HapticFeedback.mediumImpact', () {
      const service = HapticService.enabled();
      service.medium();
      expect(hapticCalls, isNotEmpty);
    });

    test('heavy() triggers HapticFeedback.heavyImpact', () {
      const service = HapticService.enabled();
      service.heavy();
      expect(hapticCalls, isNotEmpty);
    });

    test('selection() triggers HapticFeedback.selectionClick', () {
      const service = HapticService.enabled();
      service.selection();
      expect(hapticCalls, isNotEmpty);
    });
  });

  // -------------------------------------------------------
  // Disabled state
  // -------------------------------------------------------
  group('when disabled', () {
    test('light() does nothing', () {
      const service = HapticService.disabled();
      service.light();
      expect(hapticCalls, isEmpty);
    });

    test('medium() does nothing', () {
      const service = HapticService.disabled();
      service.medium();
      expect(hapticCalls, isEmpty);
    });

    test('heavy() does nothing', () {
      const service = HapticService.disabled();
      service.heavy();
      expect(hapticCalls, isEmpty);
    });

    test('selection() does nothing', () {
      const service = HapticService.disabled();
      service.selection();
      expect(hapticCalls, isEmpty);
    });
  });
}
