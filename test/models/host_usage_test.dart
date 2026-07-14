import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/models/host_usage.dart';
import 'package:seminary_sidekick/services/group_play_service.dart';

void main() {
  // Fixed "now": Wednesday 2026-07-15 15:00 UTC → current Monday is 2026-07-13.
  final nowUtc = DateTime.utc(2026, 7, 15, 15);
  final currentMonday = DateTime.utc(2026, 7, 13);
  final priorMonday = DateTime.utc(2026, 7, 6);
  final futureMonday = DateTime.utc(2026, 7, 20);

  group('FreeHostWeeklyLimit.currentWeekStartUtc', () {
    test('matches Postgres date_trunc week — Monday 00:00 UTC', () {
      expect(
        FreeHostWeeklyLimit.currentWeekStartUtc(nowUtc),
        currentMonday,
      );
      expect(
        FreeHostWeeklyLimit.currentWeekStartUtc(DateTime.utc(2026, 7, 13)),
        currentMonday,
      );
      expect(
        FreeHostWeeklyLimit.currentWeekStartUtc(DateTime.utc(2026, 7, 19, 23, 59)),
        currentMonday,
      );
    });
  });

  group('FreeHostWeeklyLimit.isLocked', () {
    test(
      'same week + roomsThisWeek >= freeHostWeeklyLimit → locked '
      '(UI uses >= on stored count; service uses > on post-bump count — '
      'both correct after a successful free host leaves rooms_this_week = 1; '
      'do not "align" the operators)',
      () {
        final usage = HostUsage(
          roomsThisWeek: GroupPlayService.freeHostWeeklyLimit,
          weekStartsAt: currentMonday,
        );
        expect(
          FreeHostWeeklyLimit.isLocked(
            usage: usage,
            nowUtc: nowUtc,
            isPremium: false,
            weeklyLimit: GroupPlayService.freeHostWeeklyLimit,
          ),
          isTrue,
        );
      },
    );

    test('roomsThisWeek below limit → unlocked even in current week', () {
      final usage = HostUsage(
        roomsThisWeek: 0,
        weekStartsAt: currentMonday,
      );
      expect(
        FreeHostWeeklyLimit.isLocked(
          usage: usage,
          nowUtc: nowUtc,
          isPremium: false,
        ),
        isFalse,
      );
    });

    test('prior weekStartsAt → unlocked even if count is high', () {
      final usage = HostUsage(
        roomsThisWeek: 5,
        weekStartsAt: priorMonday,
      );
      expect(
        FreeHostWeeklyLimit.isLocked(
          usage: usage,
          nowUtc: nowUtc,
          isPremium: false,
        ),
        isFalse,
      );
    });

    test(
      'future weekStartsAt (clock skew / weird data) → unlocked',
      () {
        final usage = HostUsage(
          roomsThisWeek: 1,
          weekStartsAt: futureMonday,
        );
        expect(
          FreeHostWeeklyLimit.isLocked(
            usage: usage,
            nowUtc: nowUtc,
            isPremium: false,
          ),
          isFalse,
        );
      },
    );

    test('null usage row → available', () {
      expect(
        FreeHostWeeklyLimit.isLocked(
          usage: null,
          nowUtc: nowUtc,
          isPremium: false,
        ),
        isFalse,
      );
    });

    test('premium never locks', () {
      final usage = HostUsage(
        roomsThisWeek: 1,
        weekStartsAt: currentMonday,
      );
      expect(
        FreeHostWeeklyLimit.isLocked(
          usage: usage,
          nowUtc: nowUtc,
          isPremium: true,
        ),
        isFalse,
      );
    });

    test(
      'stale cached row + now past Monday → unlocked without refetch',
      () {
        // Usage still points at last week's Monday; wall clock is next Tuesday.
        final usage = HostUsage(
          roomsThisWeek: 1,
          weekStartsAt: currentMonday,
        );
        final nextTuesday = DateTime.utc(2026, 7, 21, 10);
        expect(
          FreeHostWeeklyLimit.isLocked(
            usage: usage,
            nowUtc: nextTuesday,
            isPremium: false,
          ),
          isFalse,
        );
      },
    );

    test('weekStartsAt with time-of-day still matches calendar Monday', () {
      final usage = HostUsage(
        roomsThisWeek: 1,
        weekStartsAt: DateTime.utc(2026, 7, 13, 0, 0, 0, 123),
      );
      expect(
        FreeHostWeeklyLimit.isLocked(
          usage: usage,
          nowUtc: nowUtc,
          isPremium: false,
        ),
        isTrue,
      );
    });
  });

  group('HostUsage.fromJson', () {
    test('parses host_usage row', () {
      final usage = HostUsage.fromJson({
        'rooms_this_week': 1,
        'week_starts_at': '2026-07-13T00:00:00+00:00',
      });
      expect(usage.roomsThisWeek, 1);
      expect(usage.weekStartsAt.toUtc(), DateTime.utc(2026, 7, 13));
    });
  });
}
