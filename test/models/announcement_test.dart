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
