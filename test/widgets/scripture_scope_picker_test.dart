import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/models/enums.dart';
import 'package:seminary_sidekick/models/scripture_mastery.dart';
import 'package:seminary_sidekick/models/scripture_scope.dart';
import 'package:seminary_sidekick/providers/scripture_mastery_provider.dart';
import 'package:seminary_sidekick/providers/scripture_provider.dart';
import 'package:seminary_sidekick/theme/app_theme.dart';
import 'package:seminary_sidekick/widgets/scripture_scope_picker.dart';
import 'package:seminary_sidekick/widgets/selection_pill.dart';

import '../helpers/test_helpers.dart';

ScriptureMastery _mastery({
  required String id,
  MasteryLevel level = MasteryLevel.learning,
  double subProgress = 0,
  bool needsReview = false,
}) {
  return ScriptureMastery(
    scriptureId: id,
    level: level,
    subProgress: subProgress,
    needsReview: needsReview,
    lastPracticedAny: null,
    highestDifficultyPerGame: const {},
    overallAccuracy: 0,
    totalAttemptsAllGames: 0,
    nextLevelRequirements: const [],
    gameTypesAttempted: 0,
    gameTypesWithCorrect: 0,
  );
}

void main() {
  Widget harness({
    ValueChanged<ScriptureScope>? onChanged,
    ScriptureScope initial = const ScriptureScope(),
    Map<String, ScriptureMastery>? masteryById,
    bool showIndividualSection = false,
    bool fillHeight = false,
  }) {
    final picker = ScriptureScopePicker(
      initial: initial,
      onChanged: onChanged ?? (_) {},
      showIndividualSection: showIndividualSection,
      fillHeight: fillHeight,
    );
    return ProviderScope(
      overrides: [
        scripturesProvider.overrideWithValue(testScriptures),
        if (masteryById != null)
          scriptureMasteryProvider.overrideWith((ref, id) {
            return masteryById[id] ?? _mastery(id: id);
          }),
      ],
      child: MaterialApp(
        theme: AppTheme.getLightTheme(),
        home: Scaffold(
          body: fillHeight
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: picker,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: picker,
                ),
        ),
      ),
    );
  }

  InkWell needsReviewInkWell(WidgetTester tester) {
    return tester.widget<InkWell>(
      find.ancestor(
        of: find.text('Needs Review'),
        matching: find.byType(InkWell),
      ),
    );
  }

  testWidgets('filter chips use fixed grid cells with no FilterChip',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(harness());

    expect(find.byType(FilterChip), findsNothing);
    expect(find.text('Doctrine and Covenants'), findsOneWidget);
    expect(find.text('Needs Review'), findsOneWidget);
    expect(find.text('Nearly Mastered'), findsOneWidget);

    final dnc = find.text('Doctrine and Covenants');
    final chip = find.ancestor(of: dnc, matching: find.byType(SelectionPill));
    final before = tester.getSize(chip);
    await tester.tap(dnc);
    await tester.pumpAndSettle();
    final after = tester.getSize(chip);

    expect(after, before);
  });

  testWidgets('tapping a book chip updates scope via onChanged', (tester) async {
    ScriptureScope? latest;
    await tester.pumpWidget(harness(onChanged: (s) => latest = s));

    await tester.tap(find.text('Book of Mormon'));
    await tester.pumpAndSettle();

    expect(latest, isNotNull);
    expect(latest!.books.length, 1);
  });

  testWidgets('selectedChipGradient is light hero in light, dark lift in Midnight',
      (tester) async {
    late LinearGradient lightGradient;
    late LinearGradient darkGradient;

    await tester.pumpWidget(
      Theme(
        data: AppTheme.getLightTheme(),
        child: Builder(
          builder: (context) {
            lightGradient = AppTheme.selectedChipGradient(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(lightGradient, AppTheme.heroGradient);

    await tester.pumpWidget(
      Theme(
        data: AppTheme.getDarkTheme(),
        child: Builder(
          builder: (context) {
            darkGradient = AppTheme.selectedChipGradient(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(darkGradient, AppTheme.heroGradientDark);
  });

  testWidgets('Needs Review is disabled when no scripture needs review',
      (tester) async {
    ScriptureScope? latest;
    final mastery = {
      for (final s in testScriptures) s.id: _mastery(id: s.id),
    };

    await tester.pumpWidget(
      harness(onChanged: (s) => latest = s, masteryById: mastery),
    );
    await tester.pumpAndSettle();

    expect(needsReviewInkWell(tester).onTap, isNull);

    final label = tester.widget<Text>(find.text('Needs Review'));
    expect(label.style?.color?.a, closeTo(0.38, 0.01));

    await tester.tap(find.text('Needs Review'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(latest, isNull);
  });

  testWidgets('Needs Review is enabled when a scripture needs review',
      (tester) async {
    ScriptureScope? latest;
    final mastery = {
      for (final s in testScriptures) s.id: _mastery(id: s.id),
      'test-1': _mastery(id: 'test-1', needsReview: true),
    };

    await tester.pumpWidget(
      harness(onChanged: (s) => latest = s, masteryById: mastery),
    );
    await tester.pumpAndSettle();

    expect(needsReviewInkWell(tester).onTap, isNotNull);

    await tester.tap(find.text('Needs Review'));
    await tester.pumpAndSettle();

    expect(latest?.needsReview, isTrue);
  });

  testWidgets('clears Needs Review on init when pool is empty', (tester) async {
    ScriptureScope? latest;
    final mastery = {
      for (final s in testScriptures) s.id: _mastery(id: s.id),
    };

    await tester.pumpWidget(
      harness(
        initial: const ScriptureScope(needsReview: true),
        onChanged: (s) => latest = s,
        masteryById: mastery,
      ),
    );
    await tester.pumpAndSettle();

    expect(latest?.needsReview, isFalse);
    expect(needsReviewInkWell(tester).onTap, isNull);
  });

  testWidgets('pick-specific row opens selection page with search',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      harness(showIndividualSection: true, fillHeight: true),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('scope-pick-specific')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('scope-scripture-search')), findsOneWidget);
    expect(find.text('1 Nephi 3:7'), findsOneWidget);
    expect(find.text('John 3:16'), findsOneWidget);
  });

  testWidgets('selection search filters the list', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      harness(showIndividualSection: true, fillHeight: true),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scope-pick-specific')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('scope-scripture-search')),
      'John',
    );
    await tester.pumpAndSettle();

    expect(find.text('John 3:16'), findsOneWidget);
    expect(find.text('1 Nephi 3:7'), findsNothing);
  });

  testWidgets('toggle + Done keeps specificIds; back keeps selection',
      (tester) async {
    ScriptureScope? latest;
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      harness(
        showIndividualSection: true,
        fillHeight: true,
        onChanged: (s) => latest = s,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scope-pick-specific')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('1 Nephi 3:7'));
    await tester.pumpAndSettle();
    expect(latest?.specificIds, ['test-1']);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('scope-pick-specific')), findsOneWidget);
    expect(latest?.specificIds, ['test-1']);

    await tester.tap(find.byKey(const Key('scope-pick-specific')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('John 3:16'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(latest?.specificIds, containsAll(['test-1', 'test-2']));
    expect(find.byKey(const Key('scope-pick-specific')), findsOneWidget);
  });

  testWidgets('selection list respects book filter pool', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      harness(showIndividualSection: true, fillHeight: true),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Book of Mormon'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scope-pick-specific')));
    await tester.pumpAndSettle();

    expect(find.text('1 Nephi 3:7'), findsOneWidget);
    expect(find.text('Moroni 10:4-5'), findsOneWidget);
    expect(find.text('John 3:16'), findsNothing);
    expect(find.text('Proverbs 3:5-6'), findsNothing);
  });
}
