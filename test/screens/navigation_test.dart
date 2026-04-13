import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Tests that GoRouter navigation to and from scripture detail never throws
/// "There is nothing to pop." These tests mirror the real app's route structure:
/// - StatefulShellRoute with 5 tabs (/, /library, /practice, /progress, /sidekick)
/// - Top-level routes: /scripture/:id, /scriptures/:bookId, /upgrade, /journal
///
/// The bug: navigating with `context.go('/scripture/1')` replaces the stack,
/// so `context.pop()` throws. Fix: use `context.push()` for scripture detail,
/// and add `canPop()` guard on back buttons.
void main() {
  late GoRouter router;

  GoRouter buildRouter({String initialLocation = '/'}) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return Scaffold(
              body: navigationShell,
              bottomNavigationBar: NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
                  NavigationDestination(
                      icon: Icon(Icons.book), label: 'Library'),
                  NavigationDestination(
                      icon: Icon(Icons.quiz), label: 'Practice'),
                  NavigationDestination(
                      icon: Icon(Icons.bar_chart), label: 'Progress'),
                  NavigationDestination(
                      icon: Icon(Icons.chat), label: 'Sidekick'),
                ],
                onDestinationSelected: (i) => navigationShell.goBranch(i),
              ),
            );
          },
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/',
                  builder: (_, __) =>
                      const _TestPage(key: Key('home'), label: 'Home')),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/library',
                  builder: (_, __) =>
                      const _TestPage(key: Key('library'), label: 'Library')),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/practice',
                  builder: (_, __) =>
                      const _TestPage(key: Key('practice'), label: 'Practice')),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/progress',
                  builder: (_, __) =>
                      const _TestPage(key: Key('progress'), label: 'Progress')),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/sidekick',
                  builder: (_, __) =>
                      const _TestPage(key: Key('sidekick'), label: 'Sidekick')),
            ]),
          ],
        ),
        GoRoute(
          path: '/scripture/:id',
          builder: (context, state) => _ScriptureDetailPage(
            scriptureId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/scriptures/:bookId',
          builder: (context, state) => _ScriptureListPage(
            bookId: state.pathParameters['bookId']!,
          ),
        ),
      ],
    );
  }

  Widget buildApp(GoRouter r) {
    return MaterialApp.router(routerConfig: r);
  }

  group('Scripture detail navigation', () {
    testWidgets('push to scripture detail then pop returns to previous screen',
        (tester) async {
      router = buildRouter();
      await tester.pumpWidget(buildApp(router));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home')), findsOneWidget);

      // Push scripture detail (correct pattern)
      router.push('/scripture/42');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('scripture-detail-42')), findsOneWidget);

      // Pop should work — we pushed, so there's something to pop
      await tester.tap(find.byKey(const Key('back-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home')), findsOneWidget);
    });

    testWidgets(
        'go to scripture detail then back button navigates home (canPop guard)',
        (tester) async {
      router = buildRouter();
      await tester.pumpWidget(buildApp(router));
      await tester.pumpAndSettle();

      // Use go — replaces stack (the old buggy pattern)
      router.go('/scripture/42');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('scripture-detail-42')), findsOneWidget);

      // Back button should NOT throw — canPop guard falls back to go('/')
      await tester.tap(find.byKey(const Key('back-button')));
      await tester.pumpAndSettle();

      // Should land on home, not crash
      expect(find.byKey(const Key('home')), findsOneWidget);
    });

    testWidgets('push from library tab to scripture detail preserves stack',
        (tester) async {
      router = buildRouter();
      await tester.pumpWidget(buildApp(router));
      await tester.pumpAndSettle();

      // Switch to library tab
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('library')), findsOneWidget);

      // Push scripture detail
      router.push('/scripture/7');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('scripture-detail-7')), findsOneWidget);

      // Pop back to library
      await tester.tap(find.byKey(const Key('back-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('library')), findsOneWidget);
    });

    testWidgets('push scripture list then push scripture detail — double pop',
        (tester) async {
      router = buildRouter();
      await tester.pumpWidget(buildApp(router));
      await tester.pumpAndSettle();

      // Push scripture list
      router.push('/scriptures/bookOfMormon');
      await tester.pumpAndSettle();
      expect(
          find.byKey(const Key('scripture-list-bookOfMormon')), findsOneWidget);

      // Push scripture detail
      router.push('/scripture/3');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('scripture-detail-3')), findsOneWidget);

      // Pop to list
      await tester.tap(find.byKey(const Key('back-button')));
      await tester.pumpAndSettle();
      expect(
          find.byKey(const Key('scripture-list-bookOfMormon')), findsOneWidget);

      // Pop to home
      await tester.tap(find.byKey(const Key('list-back-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home')), findsOneWidget);
    });

    testWidgets('deep link directly to scripture detail — back goes home',
        (tester) async {
      // Simulate deep link: app starts at /scripture/99
      router = buildRouter(initialLocation: '/scripture/99');
      await tester.pumpWidget(buildApp(router));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('scripture-detail-99')), findsOneWidget);

      // No stack to pop — canPop guard should send to home
      await tester.tap(find.byKey(const Key('back-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home')), findsOneWidget);
    });
  });
}

/// Minimal test page for tab content.
class _TestPage extends StatelessWidget {
  final String label;
  const _TestPage({super.key, required this.label});

  @override
  Widget build(BuildContext context) => Center(child: Text(label));
}

/// Minimal scripture detail page that mirrors the real back button behavior:
/// `context.canPop() ? context.pop() : context.go('/')`
class _ScriptureDetailPage extends StatelessWidget {
  final String scriptureId;
  const _ScriptureDetailPage({required this.scriptureId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: Key('scripture-detail-$scriptureId'),
      appBar: AppBar(
        leading: IconButton(
          key: const Key('back-button'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text('Scripture $scriptureId'),
      ),
      body: const SizedBox.shrink(),
    );
  }
}

/// Minimal scripture list page.
class _ScriptureListPage extends StatelessWidget {
  final String bookId;
  const _ScriptureListPage({required this.bookId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: Key('scripture-list-$bookId'),
      appBar: AppBar(
        leading: IconButton(
          key: const Key('list-back-button'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text('Book: $bookId'),
      ),
      body: const SizedBox.shrink(),
    );
  }
}
