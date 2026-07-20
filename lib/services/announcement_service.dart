import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/announcement.dart';

/// Fetches broadcast announcements from Supabase.
///
/// Failures are logged and returned as an empty list — announcements are
/// best-effort and must never break the solo mastery loop when Supabase is
/// missing or unreachable.
class AnnouncementService {
  AnnouncementService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient? get _resolvedClient {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Returns currently active announcements (RLS + window already applied
  /// server-side), ordered by priority desc then created_at desc.
  Future<List<Announcement>> fetchActive() async {
    final client = _resolvedClient;
    if (client == null || client.auth.currentUser == null) {
      return const [];
    }

    try {
      final rows = await client
          .from('announcements')
          .select()
          .order('priority', ascending: false)
          .order('created_at', ascending: false);

      final list = (rows as List<dynamic>)
          .map((row) => Announcement.fromJson(
                Map<String, dynamic>.from(row as Map),
              ))
          .toList();
      return list;
    } catch (e, st) {
      developer.log(
        'Announcement fetch failed: $e',
        name: 'AnnouncementService',
        stackTrace: st,
      );
      return const [];
    }
  }
}
