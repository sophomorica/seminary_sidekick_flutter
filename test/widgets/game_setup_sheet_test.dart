import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/models/enums.dart';
import 'package:seminary_sidekick/providers/scripture_provider.dart';
import 'package:seminary_sidekick/theme/app_theme.dart';
import 'package:seminary_sidekick/widgets/game_setup_sheet.dart';
import 'package:seminary_sidekick/widgets/selection_pill.dart';

import '../helpers/test_helpers.dart';

void main() {
  Widget harness() {
    return ProviderScope(
      overrides: [
        scripturesProvider.overrideWithValue(testScriptures),
      ],
      child: MaterialApp(
        theme: AppTheme.getLightTheme(),
        home: const Scaffold(
          body: GameSetupSheet(gameType: GameType.quiz),
        ),
      ),
    );
  }

  testWidgets('count pills use SelectionPill and toggle with no ChoiceChip',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byType(SelectionPill), findsWidgets);

    final defaultLabel = find.textContaining('Default ·');
    final everyLabel = find.textContaining('Every scripture');
    expect(defaultLabel, findsOneWidget);
    expect(everyLabel, findsOneWidget);

    await tester.ensureVisible(everyLabel);
    await tester.tap(everyLabel);
    await tester.pumpAndSettle();

    final everyPill = tester.widget<SelectionPill>(
      find.ancestor(of: everyLabel, matching: find.byType(SelectionPill)),
    );
    expect(everyPill.selected, isTrue);

    final defaultPill = tester.widget<SelectionPill>(
      find.ancestor(of: defaultLabel, matching: find.byType(SelectionPill)),
    );
    expect(defaultPill.selected, isFalse);
  });

  testWidgets('difficulty pills are SelectionPill in a 2x2 grid', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('Intermediate'), findsOneWidget);

    await tester.tap(find.text('Intermediate'));
    await tester.pumpAndSettle();

    final intermediate = tester.widget<SelectionPill>(
      find.ancestor(
        of: find.text('Intermediate'),
        matching: find.byType(SelectionPill),
      ),
    );
    expect(intermediate.selected, isTrue);
  });

  testWidgets(
      'single tap opens selection view (no dead intermediate state)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scripturesProvider.overrideWithValue(testScriptures),
        ],
        child: MaterialApp(
          theme: AppTheme.getLightTheme(),
          home: const Scaffold(
            body: GameSetupSheet(gameType: GameType.matching),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final entry = find.byKey(const Key('scope-pick-specific'));
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();

    // One tap must land on the selection page — not a half-swapped default
    // view with the sheet title stripped (R6.1 regression).
    expect(find.byKey(const Key('scope-scripture-search')), findsOneWidget);
    expect(find.byKey(const Key('scope-pick-specific')), findsNothing);
    expect(find.text('DIFFICULTY'), findsNothing);
  });

  testWidgets('setup and selection titles share the same y position',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scripturesProvider.overrideWithValue(testScriptures),
        ],
        child: MaterialApp(
          theme: AppTheme.getLightTheme(),
          home: const Scaffold(
            body: GameSetupSheet(gameType: GameType.matching),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final setupTitle = find.byKey(const Key('scope-setup-title'));
    final setupY = tester.getTopLeft(setupTitle).dy;

    await tester.ensureVisible(find.byKey(const Key('scope-pick-specific')));
    await tester.tap(find.byKey(const Key('scope-pick-specific')));
    await tester.pumpAndSettle();

    final selectionTitle = find.byKey(const Key('scope-selection-title'));
    expect(selectionTitle, findsOneWidget);
    expect(tester.getTopLeft(selectionTitle).dy, setupY);
  });
}
