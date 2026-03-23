import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seminary_sidekick/app.dart';

void main() {
  testWidgets('App smoke test — renders without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SeminarySidekickApp(),
      ),
    );

    // Let the router and async providers settle.
    await tester.pumpAndSettle();

    // The app should render something on screen.
    expect(find.byType(SeminarySidekickApp), findsOneWidget);
  });
}
