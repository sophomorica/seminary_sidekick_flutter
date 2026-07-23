import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/activity_provider.dart';
import '../providers/announcement_provider.dart';
import '../providers/goals_provider.dart';
import '../providers/journal_provider.dart';
import '../providers/mastery_dates_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/scripture_scope_provider.dart';
import '../providers/sidekick_provider.dart';
import '../providers/spaced_repetition_provider.dart';
import '../providers/study_streak_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_preferences_provider.dart';
import 'audio_service.dart' show audioProvider;

/// Permanently erases all locally-stored user data.
///
/// Used by Settings → "Delete All My Data" to satisfy the App Store / Play
/// account-deletion requirement and to give users genuine control over their
/// data. Everything this app stores about a user lives either in local Hive
/// boxes or in an anonymous Supabase session (group play) — there is no
/// server-side personal account, so clearing both is a complete deletion.
class DataResetService {
  DataResetService._();

  /// Every Hive box the app writes user data into. Cleared in place (not
  /// deleted from disk) so already-open box handles stay valid and providers
  /// can re-initialize without a full app restart.
  static const List<String> _boxNames = <String>[
    'activities',
    'announcements',
    'audio_settings',
    'goals',
    'journal_entries',
    'mastery_dates',
    'onboarding',
    'scripture_notes',
    'scripture_scope_prefs',
    'settings',
    'sidekick_cache',
    'spaced_repetition',
    'study_streak',
    'subscription',
    'user_preferences',
    'user_progress',
  ];

  /// Wipe all local data, sign out of any anonymous Supabase session, and
  /// reload every provider so in-memory state reflects the now-empty boxes.
  ///
  /// Note on premium: the local `subscription` box is cleared, but premium
  /// status is owned by RevenueCat/the store — the background sync on re-init
  /// restores it if the user still has an active subscription.
  static Future<void> deleteAllData(WidgetRef ref) async {
    // 1. Clear every Hive box in place. Best-effort per box.
    for (final name in _boxNames) {
      try {
        if (Hive.isBoxOpen(name)) {
          await Hive.box(name).clear();
        }
      } catch (_) {
        // Ignore — a box that won't clear shouldn't block the rest.
      }
    }

    // 2. Sign out the anonymous Supabase session (group play). Guarded —
    //    Supabase may not be configured in this build.
    try {
      final auth = Supabase.instance.client.auth;
      if (auth.currentSession != null) {
        await auth.signOut();
      }
    } catch (_) {
      // Supabase not initialized — nothing to sign out of.
    }

    // 3. Reload providers from the cleared boxes so the UI shows a clean slate
    //    without requiring an app restart.
    await Future.wait<void>([
      ref.read(progressProvider.notifier).init(),
      ref.read(notesProvider.notifier).init(),
      ref.read(masteryDatesProvider.notifier).init(),
      ref.read(spacedRepetitionProvider.notifier).init(),
      ref.read(activityProvider.notifier).init(),
      ref.read(onboardingProvider.notifier).init(),
      ref.read(themeProvider.notifier).init(),
      ref.read(subscriptionProvider.notifier).init(),
      ref.read(journalProvider.notifier).init(),
      ref.read(audioProvider.notifier).init(),
      ref.read(userPreferencesProvider.notifier).init(),
      ref.read(studyStreakProvider.notifier).init(),
      ref.read(scriptureScopeProvider.notifier).init(),
      ref.read(goalsProvider.notifier).init(),
    ]);

    // Sidekick reloads its own cache (non-blocking, mirrors main.dart).
    ref.read(sidekickProvider.notifier).init();
    // Announcements: restore (now-empty) dismissals then refetch. The refetch
    // races the anonymous re-sign-in triggered by the signOut above; if it
    // loses (no session yet), refresh() keeps the last-known-good broadcast
    // list rather than blanking the banner until next cold start.
    await ref.read(announcementProvider.notifier).init();
    ref.read(announcementProvider.notifier).refresh();
  }
}
