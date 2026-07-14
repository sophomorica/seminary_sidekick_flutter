/// Owner's weekly Group Play hosting quota row (`host_usage` table).
///
/// Written only via the `bump_host_usage` RPC; the client may SELECT its own
/// row to decide whether the home card should show the free-tier lock state.
class HostUsage {
  final int roomsThisWeek;

  /// Monday 00:00 UTC for the ISO week this counter applies to — matches
  /// Postgres `date_trunc('week', now())`.
  final DateTime weekStartsAt;

  const HostUsage({
    required this.roomsThisWeek,
    required this.weekStartsAt,
  });

  factory HostUsage.fromJson(Map<String, dynamic> json) {
    return HostUsage(
      roomsThisWeek: json['rooms_this_week'] as int? ?? 0,
      weekStartsAt: DateTime.parse(json['week_starts_at'] as String),
    );
  }
}

/// Pure helpers for the free-host weekly room limit.
///
/// Server enforcement in [GroupPlayService.createRoom] bumps first, then
/// checks `usage > freeHostWeeklyLimit` on the **post-bump** count. After a
/// successful free host, the stored row has `rooms_this_week == 1`, so the
/// UI lock check uses `roomsThisWeek >= freeHostWeeklyLimit` on the
/// **stored** value. Both operators are correct — do not "align" them.
class FreeHostWeeklyLimit {
  FreeHostWeeklyLimit._();

  /// Same boundary as Postgres `date_trunc('week', timestamptz)` in UTC:
  /// Monday 00:00:00 UTC of the ISO week containing [nowUtc].
  static DateTime currentWeekStartUtc(DateTime nowUtc) {
    final utc = nowUtc.toUtc();
    final daysFromMonday = utc.weekday - DateTime.monday;
    return DateTime.utc(utc.year, utc.month, utc.day - daysFromMonday);
  }

  /// Truncate a timestamptz to a calendar-day UTC midnight for equality
  /// checks against [currentWeekStartUtc].
  static DateTime weekStartDayUtc(DateTime weekStartsAt) {
    final utc = weekStartsAt.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }

  /// Whether a free host has already used their weekly hosting slot.
  ///
  /// Locked only when [usage.weekStartsAt] falls on the same UTC calendar-day
  /// Monday as the current week start (time-of-day ignored). Prior weeks (stale
  /// row) and future weeks (clock skew / weird data) both unlock.
  static bool isLocked({
    required HostUsage? usage,
    required DateTime nowUtc,
    required bool isPremium,
    int weeklyLimit = 1,
  }) {
    if (isPremium) return false;
    if (usage == null) return false;
    if (usage.roomsThisWeek < weeklyLimit) return false;

    final currentMonday = currentWeekStartUtc(nowUtc);
    final storedMonday = weekStartDayUtc(usage.weekStartsAt);
    return storedMonday == currentMonday;
  }
}
