import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/services/crash_reporting_service.dart';

void main() {
  group('CrashReportingService', () {
    group('isDsnConfigured', () {
      test('empty DSN is not configured', () {
        expect(CrashReportingService.isDsnConfigured(''), isFalse);
      });

      test('whitespace-only DSN is not configured', () {
        expect(CrashReportingService.isDsnConfigured('   '), isFalse);
      });

      test('real DSN is configured', () {
        expect(
          CrashReportingService.isDsnConfigured(
            'https://abc123@o0.ingest.sentry.io/1234',
          ),
          isTrue,
        );
      });
    });

    group('without a DSN (test environment)', () {
      // Tests never define SENTRY_DSN, so the service must be fully inert.
      test('isEnabled is false', () {
        expect(CrashReportingService.isEnabled, isFalse);
      });

      test('init runs the appRunner directly', () async {
        var ran = false;
        await CrashReportingService.init(() {
          ran = true;
        });
        expect(ran, isTrue);
      });

      test('recordError is a no-op and does not throw', () async {
        await CrashReportingService.recordError(
          Exception('boom'),
          StackTrace.current,
          hint: 'test',
        );
      });

      test('addBreadcrumb is a no-op and does not throw', () {
        CrashReportingService.addBreadcrumb('tab: home',
            category: 'navigation');
      });

      test('setPremiumTag is a no-op and does not throw', () {
        CrashReportingService.setPremiumTag(true);
        CrashReportingService.setPremiumTag(false);
      });
    });
  });
}
