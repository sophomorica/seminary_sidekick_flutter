import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/scripture_list_screen.dart';
import 'screens/scripture_detail_screen.dart';
import 'screens/games_hub_screen.dart';
import 'screens/progress_screen.dart';

class SeminarySidekickApp extends StatefulWidget {
  const SeminarySidekickApp({super.key});

  @override
  State<SeminarySidekickApp> createState() => _SeminarySidekickAppState();
}

class _SeminarySidekickAppState extends State<SeminarySidekickApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/',
      routes: [
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
                  path: '/games',
                  builder: (context, state) => const GamesHubScreen(),
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Seminary Sidekick',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(),
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
            icon: Icon(Icons.sports_esports_outlined),
            selectedIcon: Icon(Icons.sports_esports),
            label: 'Games',
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
