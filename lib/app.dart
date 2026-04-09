import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'theme/app_theme.dart';
import 'providers/onboarding_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/scripture_list_screen.dart';
import 'screens/scripture_detail/scripture_detail_screen.dart';
import 'screens/practice_hub_screen.dart';
import 'screens/journal/journal_screen.dart';
import 'screens/progress/progress_screen.dart';
import 'screens/sidekick_chat/sidekick_chat_screen.dart';
import 'screens/upgrade_screen.dart';

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
                  path: '/practice',
                  builder: (context, state) => const PracticeHubScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/journal',
                  builder: (context, state) => const JournalScreen(),
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
          path: '/sidekick-chat',
          builder: (context, state) {
            final scriptureId = state.uri.queryParameters['scriptureId'];
            return SidekickChatScreen(initialScriptureId: scriptureId);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Seminary Sidekick',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(),
      darkTheme: AppTheme.getDarkTheme(),
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}

/// Shell widget that wraps tab-based screens with bottom navigation.
class _AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _AppShell({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Scriptures',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz),
            label: 'Practice',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Journal',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}
