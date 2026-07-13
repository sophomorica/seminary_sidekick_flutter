import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/services/sidekick_service.dart';

void main() {
  group('SidekickService.isTransientSidekickStatus', () {
    test('treats overload and gateway codes as transient (FLUTTER-6)', () {
      expect(SidekickService.isTransientSidekickStatus(429), isTrue);
      expect(SidekickService.isTransientSidekickStatus(502), isTrue);
      expect(SidekickService.isTransientSidekickStatus(503), isTrue);
      expect(SidekickService.isTransientSidekickStatus(529), isTrue);
    });

    test('does not treat entitlement or hard failures as transient', () {
      expect(SidekickService.isTransientSidekickStatus(null), isFalse);
      expect(SidekickService.isTransientSidekickStatus(403), isFalse);
      expect(SidekickService.isTransientSidekickStatus(500), isFalse);
      expect(SidekickService.isTransientSidekickStatus(401), isFalse);
    });
  });

  group('SidekickUnavailableException', () {
    test('exposes a retry-friendly message without raw status codes', () {
      const e = SidekickUnavailableException();
      expect(e.message, contains('briefly unavailable'));
      expect(e.message.toLowerCase(), isNot(contains('529')));
      expect(e.toString(), startsWith('SidekickUnavailableException:'));
    });
  });
}
