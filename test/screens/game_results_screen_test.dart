import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/models/enums.dart';
import 'package:seminary_sidekick/screens/games/game_results_screen.dart';
import 'package:seminary_sidekick/services/haptic_service.dart';

void main() {
  Widget buildHarness({required WidgetBuilder openResults}) {
    return ProviderScope(
      overrides: [
        hapticProvider.overrideWithValue(const HapticService.disabled()),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: openResults),
                  );
                },
                child: const Text('Open Results'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  GameResultsScreen buildResults({required WidgetBuilder tryAgainBuilder}) {
    return GameResultsScreen(
      gameType: GameType.scriptureBuilder,
      difficulty: DifficultyLevel.beginner,
      correctMatches: 5,
      incorrectAttempts: 1,
      totalPairs: 5,
      completionTime: const Duration(seconds: 30),
      // Avoid confetti path (starRating == 3) so pumpAndSettle settles cleanly.
      starRating: 2,
      tryAgainBuilder: tryAgainBuilder,
    );
  }

  testWidgets('Try Again replaces results with the rebuilt game',
      (tester) async {
    await tester.pumpWidget(
      buildHarness(
        openResults: (_) => buildResults(
          tryAgainBuilder: (_) => const Scaffold(
            key: Key('retried-game'),
            body: Text('Retried Game'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Results'));
    await tester.pumpAndSettle();

    expect(find.text('Try Again'), findsOneWidget);
    expect(find.byKey(const Key('retried-game')), findsNothing);

    await tester.tap(find.text('Try Again'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('retried-game')), findsOneWidget);
    expect(find.text('Try Again'), findsNothing);
    expect(find.text('Open Results'), findsNothing);
  });

  testWidgets('Back to Practice pops to the previous screen', (tester) async {
    await tester.pumpWidget(
      buildHarness(
        openResults: (_) => buildResults(
          tryAgainBuilder: (_) => const Scaffold(
            body: Text('Should not appear'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Results'));
    await tester.pumpAndSettle();

    expect(find.text('Back to Practice'), findsOneWidget);

    await tester.tap(find.text('Back to Practice'));
    await tester.pumpAndSettle();

    expect(find.text('Open Results'), findsOneWidget);
    expect(find.text('Try Again'), findsNothing);
    expect(find.text('Should not appear'), findsNothing);
  });
}
