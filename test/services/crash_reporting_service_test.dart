import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/services/crash_reporting_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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

    group('transient HTTP status helpers (FLUTTER-6)', () {
      test('isTransientHttpStatus matches overload / gateway codes', () {
        for (final code in [429, 502, 503, 529]) {
          expect(
            CrashReportingService.isTransientHttpStatus(code),
            isTrue,
            reason: 'expected $code to be transient',
          );
        }
      });

      test('isTransientHttpStatus rejects null and non-transient codes', () {
        expect(CrashReportingService.isTransientHttpStatus(null), isFalse);
        expect(CrashReportingService.isTransientHttpStatus(400), isFalse);
        expect(CrashReportingService.isTransientHttpStatus(403), isFalse);
        expect(CrashReportingService.isTransientHttpStatus(500), isFalse);
        expect(CrashReportingService.isTransientHttpStatus(404), isFalse);
      });

      test('drops native HTTPClientError with status 529', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'HTTPClientError',
              value: 'HTTP Client Error with status code: 529',
            ),
          ],
        );
        expect(
          CrashReportingService.shouldDropTransientHttpClientError(event),
          isTrue,
        );
      });

      test('drops Dart SentryHttpClientError with status 503', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'SentryHttpClientError',
              value: 'HTTP Client Error with status code: 503',
            ),
          ],
        );
        expect(
          CrashReportingService.shouldDropTransientHttpClientError(event),
          isTrue,
        );
      });

      test('keeps HTTPClientError for non-transient 500', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'HTTPClientError',
              value: 'HTTP Client Error with status code: 500',
            ),
          ],
        );
        expect(
          CrashReportingService.shouldDropTransientHttpClientError(event),
          isFalse,
        );
      });

      test('keeps unrelated exceptions', () {
        final event = SentryEvent(
          exceptions: [
            SentryException(
              type: 'StateError',
              value: 'Bad state: something broke',
            ),
          ],
        );
        expect(
          CrashReportingService.shouldDropTransientHttpClientError(event),
          isFalse,
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
