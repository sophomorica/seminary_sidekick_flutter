import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'theme/app_theme.dart';
import 'providers/onboarding_provider.dart';
import 'providers/study_streak_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_preferences_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/scripture_list_screen.dart';
import 'screens/scripture_detail/scripture_detail_screen.dart';
import 'screens/scripture_library/scripture_library_screen.dart';
import 'screens/practice_hub_screen.dart';
import 'screens/journal/journal_screen.dart';
import 'screens/progress/progress_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/sidekick_chat/sidekick_chat_screen.dart';
import 'screens/upgrade_screen.dart';
import 'screens/group_play/_placeholder_screens.dart';
import 'screens/group_play/group_quiz_screen.dart';
import 'screens/group_play/group_results_screen.dart';
import 'screens/group_play/group_scripture_builder_screen.dart';
import 'screens/group_play/host_lobby_screen.dart';
import 'screens/group_play/join_lobby_screen.dart';
import 'services/crash_reporting_service.dart';

class SeminarySidekickApp extends ConsumerStatefulWidget {
  const SeminarySidekickApp({super.key});

  @override
  ConsumerState<SeminarySidekickApp> createState() =>
      _SeminarySidekickAppState();
}

class _SeminarySidekickAppState extends ConsumerState<SeminarySidekickApp> {
  late final GoRouter _router;

  bool _onboardingShown = false;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/',
      // Crash-report breadcrumbs for root-navigator routes (scripture detail,
      // games, group play, settings...). Tab switches inside the shell are
      // breadcrumbed manually in _AppShell. No-op without a SENTRY_DSN.
      observers: [SentryNavigatorObserver()],
      redirect: (context, state) {
        final hasCompleted = ref.read(onboardingProvider);
        final isOnboarding = state.uri.toString() == '/onboarding';
        if (!hasCompleted && !_onboardingShown && !isOnboarding) {
          _onboardingShown = true;
          return '/onboarding';
        }
        if (hasCompleted && isOnboarding) {
          return '/';
        }
        return null;
      },
      routes: [
        // Onboarding route (first-launch only)
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        // Shell with bottom navigation for main tabs
        // 5 tabs: Home, Library, Practice, Stats, Sidekick
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return _AppShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/library',
                  builder: (context, state) => const ScriptureLibraryScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/practice',
                  builder: (context, state) => const PracticeHubScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/progress',
                  builder: (context, state) => const ProgressScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/sidekick',
                  builder: (context, state) => const SidekickChatScreen(),
                ),
              ],
            ),
          ],
        ),
        // Full-screen routes (no bottom nav)
        GoRoute(
          path: '/scriptures/:bookId',
          builder: (context, state) => ScriptureListScreen(
            bookId: state.pathParameters['bookId']!,
          ),
        ),
        GoRoute(
          path: '/scripture/:id',
          builder: (context, state) => ScriptureDetailScreen(
            scriptureId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/upgrade',
          builder: (context, state) => const UpgradeScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/journal',
          builder: (context, state) => const JournalScreen(),
        ),
        GoRoute(
          path: '/sidekick-chat',
          builder: (context, state) {
            final scriptureId = state.uri.queryParameters['scriptureId'];
            return SidekickChatScreen(initialScriptureId: scriptureId);
          },
        ),
        // ─── Group Play (TASK-052..TASK-061) ────────────────────────────
        // Each route currently renders a placeholder. Phase-3 agents
        // (TASK-053..TASK-056) replace each `*PlaceholderScreen` import
        // and reference below with the real screen.
        GoRoute(
          path: '/group-play/host',
          builder: (context, state) => const HostLobbyScreen(),
        ),
        GoRoute(
          path: '/group-play/join',
          builder: (context, state) => const JoinLobbyScreen(),
        ),
        GoRoute(
          path: '/group-play/lobby/:code',
          builder: (context, state) => GroupLobbyPlaceholderScreen(
            code: state.pathParameters['code']!,
          ),
        ),
        GoRoute(
          path: '/group-play/quiz/:code',
          builder: (context, state) => GroupQuizScreen(
            code: state.pathParameters['code']!,
          ),
        ),
        GoRoute(
          path: '/group-play/word-builder/:code',
          builder: (context, state) => GroupScriptureBuilderScreen(
            code: state.pathParameters['code']!,
          ),
        ),
        GoRoute(
          path: '/group-play/results/:code',
          builder: (context, state) => GroupResultsScreen(
            code: state.pathParameters['code']!,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final fontScale = ref.watch(userPreferencesProvider).fontScale;

    return MaterialApp.router(
      title: 'Seminary Sidekick',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(),
      darkTheme: AppTheme.getDarkTheme(),
      themeMode: themeMode,
      routerConfig: _router,
      builder: (context, child) {
        // Apply user's font scale preference
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(fontScale),
          ),
          child: child!,
        );
      },
    );
  }
}

/// Sacred Editorial shell — header + glassmorphic bottom nav with 5 destinations.
class _AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const _AppShell({required this.navigationShell});

  /// Tab names for crash-report breadcrumbs (index-aligned with destinations).
  static const _tabNames = ['home', 'library', 'practice', 'stats', 'sidekick'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    // Sidekick is a sticky chat column — let Scaffold allocate space above
    // the tab bar (flex layout) instead of overlaying the nav on the body.
    // Other tabs keep extendBody so content can scroll under the glass nav.
    final isSidekickTab = navigationShell.currentIndex == 4;
    final navBg = isDark
        ? AppTheme.darkBackground.withValues(alpha: 0.9)
        : AppTheme.surface.withValues(alpha: 0.8);
    final headerBg = isDark
        ? AppTheme.darkBackground.withValues(alpha: 0.9)
        : AppTheme.surface.withValues(alpha: 0.8);

    return Scaffold(
      // Let the active tab (e.g. chat) own keyboard insets. Keeping the shell
      // from resizing avoids squashing the header + stacking the bottom nav
      // on top of the keyboard.
      resizeToAvoidBottomInset: false,
      extendBody: !isSidekickTab && !keyboardOpen,
      body: Column(
        children: [
          // ─── Sacred Editorial Header ─────────────────────────
          ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                color: headerBg,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 20,
                  right: 20,
                  bottom: 12,
                ),
                child: Row(
                  children: [
                    // Profile avatar — tappable → settings
                    GestureDetector(
                      onTap: () => context.push('/settings'),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? AppTheme.darkSurfaceContainerHigh
                              : AppTheme.secondaryContainer,
                          border: Border.all(
                            color: isDark
                                ? AppTheme.secondaryFixedDim.withValues(alpha: 0.2)
                                : AppTheme.outlineVariant.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 20,
                          color: isDark
                              ? AppTheme.secondaryFixedDim
                              : AppTheme.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Wordmark
                    Text(
                      'Seminary Sidekick',
                      style: GoogleFonts.merriweather(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? AppTheme.primaryFixedDim
                            : AppTheme.primary,
                      ),
                    ),
                    const Spacer(),
                    // Dynamic streak badge
                    _StreakBadge(isDark: isDark),
                  ],
                ),
              ),
            ),
          ),
          // ─── Tab content ─────────────────────────────────────
          Expanded(child: navigationShell),
        ],
      ),
      // Hide the tab bar while the keyboard is up so chat (and any other
      // text field) isn't trapped above a nav stack the user can't reach.
      bottomNavigationBar: keyboardOpen
          ? null
          : ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXxl),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: navBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusXxl),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F221A17),
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: NavigationBar(
                  selectedIndex: navigationShell.currentIndex,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  indicatorColor: Colors.transparent,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  onDestinationSelected: (index) {
                    CrashReportingService.addBreadcrumb(
                      'tab: ${_tabNames[index]}',
                      category: 'navigation',
                    );
                    navigationShell.goBranch(
                      index,
                      initialLocation: index == navigationShell.currentIndex,
                    );
                  },
                  destinations: [
                    _buildNavDestination(
                      context,
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home,
                      label: 'HOME',
                      isSelected: navigationShell.currentIndex == 0,
                    ),
                    _buildNavDestination(
                      context,
                      icon: Icons.menu_book_outlined,
                      selectedIcon: Icons.menu_book,
                      label: 'LIBRARY',
                      isSelected: navigationShell.currentIndex == 1,
                    ),
                    _buildNavDestination(
                      context,
                      icon: Icons.extension_outlined,
                      selectedIcon: Icons.extension,
                      label: 'PRACTICE',
                      isSelected: navigationShell.currentIndex == 2,
                    ),
                    _buildNavDestination(
                      context,
                      icon: Icons.leaderboard_outlined,
                      selectedIcon: Icons.leaderboard,
                      label: 'STATS',
                      isSelected: navigationShell.currentIndex == 3,
                    ),
                    _buildNavDestination(
                      context,
                      icon: Icons.explore_outlined,
                      selectedIcon: Icons.explore,
                      label: 'SIDEKICK',
                      isSelected: navigationShell.currentIndex == 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  NavigationDestination _buildNavDestination(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppTheme.primaryFixedDim : AppTheme.primary;
    final inactiveColor = isDark
        ? AppTheme.darkOnSurface.withValues(alpha: 0.5)
        : AppTheme.secondary;

    return NavigationDestination(
      icon: Icon(icon, color: inactiveColor, size: 24),
      selectedIcon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: activeColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        ),
        child: Icon(selectedIcon, color: activeColor, size: 24),
      ),
      label: label,
    );
  }
}

/// Live streak badge that reads from [studyStreakProvider].
class _StreakBadge extends ConsumerWidget {
  final bool isDark;

  const _StreakBadge({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(currentStreakProvider);
    if (streak <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.primaryFixedDim : AppTheme.primary)
            .withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            size: 16,
            color: isDark ? AppTheme.primaryFixedDim : AppTheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.primaryFixedDim : AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
