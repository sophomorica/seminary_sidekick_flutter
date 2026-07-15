import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/models/enums.dart';
import 'package:seminary_sidekick/screens/onboarding/mastery_page.dart';
import 'package:seminary_sidekick/services/score_story_engine.dart';

void main() {
  testWidgets('mastery onboarding teaches meter grades and avatar journey',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MasteredPage())),
    );

    expect(find.text('3 perfect Master runs = Mastered'), findsOneWidget);
    expect(find.text('Your score meter'), findsOneWidget);
    expect(find.text('Your mastery avatar'), findsOneWidget);
    expect(find.textContaining(ScoreGrade.masterful.label), findsOneWidget);
    expect(find.text(AvatarStage.quickToObserve.label), findsOneWidget);
    expect(find.text(AvatarStage.standardBearer.label), findsOneWidget);

    // No results-style star iconography for the perfect-run mechanic.
    expect(find.byIcon(Icons.star_rounded), findsNothing);
    expect(find.byIcon(Icons.star_outline_rounded), findsNothing);
    expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(3));
  });
}
