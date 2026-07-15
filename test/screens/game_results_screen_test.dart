import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/models/enums.dart';
import 'package:seminary_sidekick/providers/progress_provider.dart';
import 'package:seminary_sidekick/screens/games/game_results_screen.dart';
import 'package:seminary_sidekick/services/haptic_service.dart';
import 'package:seminary_sidekick/services/score_story_engine.dart';

void main() {
  Widget buildHarness({
    required WidgetBuilder openResults,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        hapticProvider.overrideWithValue(const HapticService.disabled()),
        ...overrides,
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

  GameResultsScreen buildResults({
    required WidgetBuilder tryAgainBuilder,
    int correctMatches = 5,
    int incorrectAttempts = 1,
    bool isNewMastery = false,
  }) {
    return GameResultsScreen(
      gameType: GameType.scriptureBuilder,
      difficulty: DifficultyLevel.beginner,
      correctMatches: correctMatches,
      incorrectAttempts: incorrectAttempts,
      totalPairs: 5,
      completionTime: const Duration(seconds: 30),
      // starRating unused by UI; keep non-celebratory callers happy.
      starRating: 2,
      isNewMastery: isNewMastery,
      tryAgainBuilder: tryAgainBuilder,
    );
  }

  Future<void> openAndSkip(WidgetTester tester) async {
    await tester.tap(find.text('Open Results'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // route transition
    expect(find.byKey(const Key('score-story-skip')), findsOneWidget);
    // Tap content to skip the score-story sequence (avoids confetti/timers).
    await tester.tap(find.byKey(const Key('score-story-skip')));
    await tester.pump();
    // Flush any in-flight sequence delays that early-return on skip.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
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

    await openAndSkip(tester);

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

    await openAndSkip(tester);

    expect(find.text('Back to Practice'), findsOneWidget);

    await tester.tap(find.text('Back to Practice'));
    await tester.pumpAndSettle();

    expect(find.text('Open Results'), findsOneWidget);
    expect(find.text('Try Again'), findsNothing);
    expect(find.text('Should not appear'), findsNothing);
  });

  testWidgets('tap-to-skip shows final grade and all receipt rows',
      (tester) async {
    final story = ScoreStoryEngine.build(
      gameType: GameType.scriptureBuilder,
      difficulty: DifficultyLevel.beginner,
      correctMatches: 5,
      incorrectAttempts: 1,
      totalPairs: 5,
      completionTime: const Duration(seconds: 30),
    );

    await tester.pumpWidget(
      buildHarness(
        openResults: (_) => buildResults(
          tryAgainBuilder: (_) => const Scaffold(body: Text('x')),
        ),
      ),
    );

    await openAndSkip(tester);

    expect(find.text(story.grade.label), findsOneWidget);
    expect(find.text('${story.finalScore}'), findsOneWidget);
    for (final event in story.events) {
      expect(find.text(event.label), findsWidgets);
      expect(find.text(event.signedPoints), findsWidgets);
    }
    // No star icons on the redesigned screen.
    expect(find.byIcon(Icons.star_rounded), findsNothing);
    expect(find.byIcon(Icons.star_outline_rounded), findsNothing);
  });

  testWidgets('miss events appear mid-sequence in receipt list', (tester) async {
    await tester.pumpWidget(
      buildHarness(
        openResults: (_) => buildResults(
          incorrectAttempts: 2,
          tryAgainBuilder: (_) => const Scaffold(body: Text('x')),
        ),
      ),
    );

    await openAndSkip(tester);

    expect(find.text('Misses'), findsOneWidget);
    expect(find.text('Flawless'), findsNothing);
  });

  testWidgets('avatar morph path only when stage changes via new mastery',
      (tester) async {
    // after=3 (Stalwart), isNewMastery ⇒ before=2 (Quick to Observe).
    final stats = UserStats(
      totalAttempted: 5,
      totalMemorized: 0,
      totalMastered: 3,
      needsReview: 0,
      currentStreak: 0,
      overallAccuracy: 100,
    );

    await tester.pumpWidget(
      buildHarness(
        overrides: [
          userStatsProvider.overrideWithValue(stats),
        ],
        openResults: (_) => buildResults(
          isNewMastery: true,
          tryAgainBuilder: (_) => const Scaffold(body: Text('x')),
        ),
      ),
    );

    await openAndSkip(tester);

    // Final stage label after skip.
    expect(find.text(AvatarStage.stalwart.label), findsOneWidget);
    expect(find.text('Scripture Mastered!'), findsOneWidget);
  });

  testWidgets('avatar shows the pre-round stage during the run, not the final',
      (tester) async {
    // after=3 (Stalwart), isNewMastery ⇒ before=2 (Quick to Observe).
    final stats = UserStats(
      totalAttempted: 5,
      totalMemorized: 0,
      totalMastered: 3,
      needsReview: 0,
      currentStreak: 0,
      overallAccuracy: 100,
    );

    await tester.pumpWidget(
      buildHarness(
        overrides: [
          userStatsProvider.overrideWithValue(stats),
        ],
        openResults: (_) => buildResults(
          isNewMastery: true,
          tryAgainBuilder: (_) => const Scaffold(body: Text('x')),
        ),
      ),
    );

    await tester.tap(find.text('Open Results'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // route transition
    // Mid-run: first score event is animating; morph hasn't started.
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(AvatarStage.quickToObserve.label), findsOneWidget);
    expect(find.text(AvatarStage.stalwart.label), findsNothing);

    // Skip to the end to flush the sequence, then verify the final stage.
    await tester.tap(find.byKey(const Key('score-story-skip')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text(AvatarStage.stalwart.label), findsOneWidget);
  });
}
