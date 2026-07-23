import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/models/announcement.dart';

void main() {
  group('Announcement.fromJson', () {
    test('parses full row including media and CTA', () {
      final a = Announcement.fromJson({
        'id': '11111111-1111-1111-1111-111111111111',
        'title': 'Group Play is here',
        'body': 'Host a class race this week.',
        'kind': 'feature',
        'media_url': 'https://example.com/tip.gif',
        'media_type': 'gif',
        'cta_label': 'Try Group Play',
        'cta_link': '/group-play/host',
        'priority': 10,
        'starts_at': '2026-07-01T00:00:00Z',
        'ends_at': '2026-08-01T00:00:00Z',
        'created_at': '2026-07-01T12:00:00Z',
      });

      expect(a.title, 'Group Play is here');
      expect(a.kind, AnnouncementKind.feature);
      expect(a.mediaType, AnnouncementMediaType.gif);
      expect(a.hasInlineMedia, isTrue);
      expect(a.hasCta, isTrue);
      expect(a.priority, 10);
    });

    test('defaults kind and tolerates missing optional fields', () {
      final a = Announcement.fromJson({
        'id': '22222222-2222-2222-2222-222222222222',
        'title': 'Hello',
        'body': 'World',
        'starts_at': '2026-07-01T00:00:00Z',
        'created_at': '2026-07-01T00:00:00Z',
      });

      expect(a.kind, AnnouncementKind.info);
      expect(a.hasMedia, isFalse);
      expect(a.hasCta, isFalse);
      expect(a.mediaType, isNull);
    });

    test('coerces double priority from JSON', () {
      final a = Announcement.fromJson({
        'id': '33333333-3333-3333-3333-333333333333',
        'title': 'T',
        'body': 'B',
        'priority': 7.0,
        'starts_at': '2026-07-01T00:00:00Z',
        'created_at': '2026-07-01T00:00:00Z',
      });
      expect(a.priority, 7);
    });
  });

  group('URL safety', () {
    Announcement withCta(String? link, {String? mediaUrl, String? mediaType}) =>
        Announcement.fromJson({
          'id': '44444444-4444-4444-4444-444444444444',
          'title': 'T',
          'body': 'B',
          'cta_label': 'Go',
          if (link != null) 'cta_link': link,
          if (mediaUrl != null) 'media_url': mediaUrl,
          if (mediaType != null) 'media_type': mediaType,
          'starts_at': '2026-07-01T00:00:00Z',
          'created_at': '2026-07-01T00:00:00Z',
        });

    test('in-app path is a CTA and marked in-app', () {
      final a = withCta('/group-play/host');
      expect(a.hasCta, isTrue);
      expect(a.ctaIsInApp, isTrue);
      expect(a.ctaIsExternal, isFalse);
    });

    test('https link is a CTA and marked external', () {
      final a = withCta('https://example.com/x');
      expect(a.hasCta, isTrue);
      expect(a.ctaIsInApp, isFalse);
      expect(a.ctaIsExternal, isTrue);
    });

    test('scheme-relative and non-http schemes are rejected', () {
      expect(withCta('//evil.com/x').hasCta, isFalse);
      expect(withCta('javascript:alert(1)').hasCta, isFalse);
      expect(withCta('file:///etc/passwd').hasCta, isFalse);
      expect(Announcement.isHttpUrl('//evil.com/x'), isFalse);
      expect(Announcement.isHttpUrl('javascript:alert(1)'), isFalse);
      expect(Announcement.isHttpUrl('https://ok.com/a'), isTrue);
    });

    test('non-http media URL means no media', () {
      final a = withCta(null,
          mediaUrl: 'javascript:alert(1)', mediaType: 'gif');
      expect(a.hasMedia, isFalse);
      expect(a.hasInlineMedia, isFalse);
    });

    test('empty video url shows no watch button', () {
      final a = withCta(null, mediaUrl: '', mediaType: 'video');
      expect(a.hasVideoMedia, isFalse);
    });
  });

  group('Announcement.isLiveAt', () {
    final base = Announcement(
      id: 'a',
      title: 't',
      body: 'b',
      startsAt: DateTime.utc(2026, 7, 1),
      endsAt: DateTime.utc(2026, 7, 10),
      createdAt: DateTime.utc(2026, 7, 1),
    );

    test('false before starts_at', () {
      expect(base.isLiveAt(DateTime.utc(2026, 6, 30)), isFalse);
    });

    test('true inside window', () {
      expect(base.isLiveAt(DateTime.utc(2026, 7, 5)), isTrue);
    });

    test('false at or after ends_at', () {
      expect(base.isLiveAt(DateTime.utc(2026, 7, 10)), isFalse);
      expect(base.isLiveAt(DateTime.utc(2026, 7, 11)), isFalse);
    });

    test('open-ended stays live after start', () {
      final open = Announcement(
        id: 'b',
        title: 't',
        body: 'b',
        startsAt: DateTime.utc(2026, 7, 1),
        createdAt: DateTime.utc(2026, 7, 1),
      );
      expect(open.isLiveAt(DateTime.utc(2027, 1, 1)), isTrue);
    });
  });

  group('AnnouncementKind', () {
    test('fromName falls back to info', () {
      expect(AnnouncementKind.fromName(null), AnnouncementKind.info);
      expect(AnnouncementKind.fromName('nope'), AnnouncementKind.info);
      expect(AnnouncementKind.fromName('tip'), AnnouncementKind.tip);
    });
  });
}
