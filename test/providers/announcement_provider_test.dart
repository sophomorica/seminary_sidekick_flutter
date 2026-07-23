import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:seminary_sidekick/models/announcement.dart';
import 'package:seminary_sidekick/providers/announcement_provider.dart';
import 'package:seminary_sidekick/services/announcement_service.dart';

class _FakeAnnouncementService extends AnnouncementService {
  _FakeAnnouncementService(this.rows);

  List<Announcement>? rows;

  @override
  Future<List<Announcement>?> fetchActive() async => rows;
}

Announcement _announcement({
  required String id,
  int priority = 0,
  DateTime? startsAt,
  DateTime? endsAt,
}) {
  return Announcement(
    id: id,
    title: 'Title $id',
    body: 'Body $id',
    priority: priority,
    startsAt: startsAt ?? DateTime.utc(2020, 1, 1),
    endsAt: endsAt,
    createdAt: DateTime.utc(2020, 1, 1),
  );
}

void main() {
  late Directory tempDir;
  late Box box;
  late _FakeAnnouncementService service;
  late AnnouncementNotifier notifier;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('announcement_test_');
    Hive.init(tempDir.path);
    box = await Hive.openBox('announcements_test');
    service = _FakeAnnouncementService([]);
    notifier = AnnouncementNotifier(service: service, box: box);
    await notifier.init();
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('visible is null when there are no announcements', () {
    expect(notifier.state.visible, isNull);
  });

  test('refresh surfaces highest-priority live announcement', () async {
    service.rows = [
      _announcement(id: 'low', priority: 1),
      _announcement(id: 'high', priority: 5),
    ];
    await notifier.refresh();
    expect(notifier.state.visible?.id, 'high');
  });

  test('dismiss hides announcement and persists across re-init', () async {
    service.rows = [_announcement(id: 'keep', priority: 1)];
    await notifier.refresh();
    expect(notifier.state.visible?.id, 'keep');

    await notifier.dismiss('keep');
    expect(notifier.state.visible, isNull);
    expect(box.get('dismissed_ids'), contains('keep'));

    final again = AnnouncementNotifier(service: service, box: box);
    await again.init();
    await again.refresh();
    expect(again.state.visible, isNull);
    expect(again.state.dismissedIds, contains('keep'));
  });

  test('expired announcements are not visible', () async {
    service.rows = [
      _announcement(
        id: 'old',
        priority: 99,
        endsAt: DateTime.utc(2021, 1, 1),
      ),
    ];
    await notifier.refresh();
    expect(notifier.state.visible, isNull);
  });

  test('failed fetch (null) keeps last-known-good announcements', () async {
    service.rows = [_announcement(id: 'keep', priority: 1)];
    await notifier.refresh();
    expect(notifier.state.visible?.id, 'keep');

    // Simulate no-session / network failure (e.g. right after data reset).
    service.rows = null;
    await notifier.refresh();
    expect(notifier.state.visible?.id, 'keep');
    expect(notifier.state.isLoading, isFalse);
  });

  test('empty fetch really clears announcements', () async {
    service.rows = [_announcement(id: 'gone', priority: 1)];
    await notifier.refresh();
    service.rows = [];
    await notifier.refresh();
    expect(notifier.state.visible, isNull);
  });

  test('skips dismissed and shows next by priority', () async {
    service.rows = [
      _announcement(id: 'a', priority: 10),
      _announcement(id: 'b', priority: 5),
    ];
    await notifier.refresh();
    await notifier.dismiss('a');
    expect(notifier.state.visible?.id, 'b');
  });
}
