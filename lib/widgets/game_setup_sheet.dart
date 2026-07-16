import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/scripture.dart';
import '../models/scripture_mastery.dart';
import '../models/scripture_scope.dart';
import '../providers/scripture_provider.dart';
import '../providers/scripture_mastery_provider.dart';
import '../providers/scripture_scope_provider.dart';
import '../screens/games/matching_game_screen.dart';
import '../screens/games/quiz_game_screen.dart';
import '../screens/games/scripture_builder/scripture_builder_screen.dart';
import '../theme/app_theme.dart';
import 'scripture_scope_picker.dart';
import 'selection_pill.dart';

/// Opens the unified game setup sheet for any solo game.
///
/// One sheet drives all three solo games (Scripture Builder, Scripture Match,
/// Quick Quiz): pick a difficulty, pick a scope, pick how many — then start.
/// Launched from both Home (quick-launch chips) and the Practice Hub tiles.
void showGameSetupSheet(
  BuildContext context, {
  required GameType gameType,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => GameSetupSheet(gameType: gameType),
  );
}

/// Reusable setup sheet for Scripture Builder, Quick Quiz and Scripture Match.
///
/// Combines a difficulty selector, the shared [ScriptureScopePicker], and a
/// count/length segmented control. There is exactly one difficulty system in
/// the app now — it lives here, not as a separate screen-level selector.
class GameSetupSheet extends ConsumerStatefulWidget {
  final GameType gameType;

  const GameSetupSheet({super.key, required this.gameType});

  @override
  ConsumerState<GameSetupSheet> createState() => _GameSetupSheetState();
}

class _GameSetupSheetState extends ConsumerState<GameSetupSheet> {
  late DifficultyLevel _difficulty;
  late ScriptureScope _scope;
  bool _everyScripture = false;

  String get _usageContext {
    switch (widget.gameType) {
      case GameType.matching:
        return ScopeUsageContext.scriptureMatch;
      case GameType.quiz:
        return ScopeUsageContext.quickQuiz;
      case GameType.scriptureBuilder:
        return ScopeUsageContext.soloScriptureBuilder;
    }
  }

  @override
  void initState() {
    super.initState();
    _difficulty = DifficultyLevel.beginner;
    _scope =
        ref.read(scriptureScopeProvider.notifier).lastUsedScope(_usageContext) ??
            const ScriptureScope();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(scripturesProvider);
    ScriptureMastery? lookup(String id) =>
        ref.read(scriptureMasteryProvider(id));
    final resolved = _scope.resolve(all, masteryLookup: lookup);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      // Constant size for default + selection views — resizing on page-swap
      // fought the slide transition and read as a height jump (R7.1).
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  // Hoisted drag handle — shared by default + selection (R8.2).
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 8, bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(ctx)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: ScriptureScopePicker(
                        initial: _scope,
                        usageContext: _usageContext,
                        onChanged: (s) => setState(() => _scope = s),
                        fillHeight: true,
                        scrollController: scrollController,
                        pinnedHeader: SizedBox(
                          height: 48,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: Center(
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Theme.of(ctx)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusSm,
                                      ),
                                    ),
                                    child: Icon(
                                      widget.gameType.icon,
                                      color:
                                          Theme.of(ctx).colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _title,
                                  key: const Key('scope-setup-title'),
                                  style: Theme.of(ctx)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: IconButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.close),
                                ),
                              ),
                            ],
                          ),
                        ),
                        aboveFilters: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionLabel('DIFFICULTY'),
                            const SizedBox(height: 6),
                            _DifficultyChips(
                              selected: _difficulty,
                              onChanged: (d) =>
                                  setState(() => _difficulty = d),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _difficulty.descriptionForGame(widget.gameType),
                              style: Theme.of(ctx)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(ctx)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                        belowFilters: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionLabel(_countLabel),
                            const SizedBox(height: 6),
                            _CountSegmented(
                              everyScripture: _everyScripture,
                              defaultLabel: _defaultCountLabel,
                              everyLabel:
                                  'Every scripture (${resolved.length})',
                              onChanged: (v) =>
                                  setState(() => _everyScripture = v),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: resolved.isEmpty
                                    ? null
                                    : () => _start(ctx, resolved),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: AppTheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                ),
                                child: Text(
                                  _startLabel,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String get _title {
    switch (widget.gameType) {
      case GameType.matching:
        return 'Set up Scripture Match';
      case GameType.quiz:
        return 'Set up Quick Quiz';
      case GameType.scriptureBuilder:
        return 'Set up Scripture Builder';
    }
  }

  String get _startLabel {
    switch (widget.gameType) {
      case GameType.matching:
        return 'Start Match';
      case GameType.quiz:
        return 'Start Quiz';
      case GameType.scriptureBuilder:
        return 'Start Builder';
    }
  }

  String get _countLabel {
    switch (widget.gameType) {
      case GameType.matching:
        return 'PAIR COUNT';
      case GameType.quiz:
        return 'QUESTION COUNT';
      case GameType.scriptureBuilder:
        return 'SESSION LENGTH';
    }
  }

  String get _defaultCountLabel {
    switch (widget.gameType) {
      case GameType.quiz:
        return '${_difficulty.quizQuestionCount} questions';
      case GameType.matching:
        final c = _difficulty.matchingScriptureCount;
        return c == null ? 'All available' : '$c pairs';
      case GameType.scriptureBuilder:
        return '${_difficulty.scriptureCount} scriptures';
    }
  }

  Future<void> _start(BuildContext ctx, List<Scripture> resolved) async {
    // Unfiltered → let the game sample from the full corpus.
    // Otherwise pass the resolved pool (books, status filters, and/or picks).
    final scriptures = _scope.isUnfiltered ? null : resolved;
    final bookFilters = (!_scope.hasStatusFilter &&
            !_scope.hasSpecificIds &&
            _scope.books.isNotEmpty)
        ? _scope.books.toList()
        : const <ScriptureBook>[];

    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final gameType = widget.gameType;
    final everyScripture = _everyScripture;
    final difficulty = _difficulty;

    await ref
        .read(scriptureScopeProvider.notifier)
        .saveScope(_usageContext, _scope);

    if (!mounted) return;
    if (ctx.mounted) Navigator.of(ctx).pop();

    switch (gameType) {
      case GameType.quiz:
        rootNavigator.push(
          MaterialPageRoute(
            builder: (_) => QuizGameScreen(
              difficulty: difficulty,
              bookFilters: bookFilters,
              scriptures: scriptures,
              targetQuestionCount: everyScripture ? resolved.length : null,
            ),
          ),
        );
        break;
      case GameType.matching:
        rootNavigator.push(
          MaterialPageRoute(
            builder: (_) => MatchingGameScreen(
              difficulty: difficulty,
              bookFilters: bookFilters,
              scriptures: scriptures,
              // Hand-picks and "Every scripture" use the full resolved pool.
              // Otherwise honor the difficulty cap (null = Master = all).
              targetPairCount: everyScripture || _scope.hasSpecificIds
                  ? resolved.length
                  : difficulty.matchingScriptureCount,
            ),
          ),
        );
        break;
      case GameType.scriptureBuilder:
        rootNavigator.push(
          MaterialPageRoute(
            builder: (_) => ScriptureBuilderScreen(
              difficulty: difficulty,
              scriptures: _builderQueue(resolved, everyScripture, difficulty),
            ),
          ),
        );
        break;
    }
  }

  /// Builds the Scripture Builder queue from the chosen scope.
  ///
  /// Builder is a typing/tap marathon, so unlike the quizzes we keep the
  /// default session short:
  ///   * "Every scripture" → the full resolved scope.
  ///   * Unfiltered + default → null (the provider samples by difficulty).
  ///   * Hand-picked scriptures → exactly those.
  ///   * Any other filter + default → a shuffled sample of
  ///     [DifficultyLevel.scriptureCount].
  List<Scripture>? _builderQueue(
    List<Scripture> resolved,
    bool everyScripture,
    DifficultyLevel difficulty,
  ) {
    if (everyScripture) return resolved;
    if (_scope.isUnfiltered) return null;
    final pool = List<Scripture>.from(resolved)..shuffle();
    final cap = _scope.hasSpecificIds
        ? pool.length
        : math.min(difficulty.scriptureCount, pool.length);
    return pool.take(cap).toList();
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}

class _DifficultyChips extends StatelessWidget {
  static const double _gap = 8;

  final DifficultyLevel selected;
  final ValueChanged<DifficultyLevel> onChanged;

  const _DifficultyChips({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const levels = DifficultyLevel.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var row = 0; row < levels.length; row += 2) ...[
          if (row > 0) const SizedBox(height: _gap),
          Row(
            children: [
              Expanded(
                child: SelectionPill(
                  label: levels[row].label,
                  selected: levels[row] == selected,
                  onTap: () => onChanged(levels[row]),
                ),
              ),
              const SizedBox(width: _gap),
              Expanded(
                child: row + 1 < levels.length
                    ? SelectionPill(
                        label: levels[row + 1].label,
                        selected: levels[row + 1] == selected,
                        onTap: () => onChanged(levels[row + 1]),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CountSegmented extends StatelessWidget {
  static const double _gap = 8;

  final bool everyScripture;
  final String defaultLabel;
  final String everyLabel;
  final ValueChanged<bool> onChanged;

  const _CountSegmented({
    required this.everyScripture,
    required this.defaultLabel,
    required this.everyLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SelectionPill(
            label: 'Default · $defaultLabel',
            selected: !everyScripture,
            onTap: () => onChanged(false),
          ),
        ),
        const SizedBox(width: _gap),
        Expanded(
          child: SelectionPill(
            label: everyLabel,
            selected: everyScripture,
            onTap: () => onChanged(true),
          ),
        ),
      ],
    );
  }
}
