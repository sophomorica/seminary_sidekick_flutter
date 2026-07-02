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
            const ScopeAll();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(scripturesProvider);
    ScriptureMastery? lookup(String id) =>
        ref.read(scriptureMasteryProvider(id));
    final resolved = _scope.resolve(all, masteryLookup: lookup);

    return DraggableScrollableSheet(
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
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(ctx)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Icon(
                          widget.gameType.icon,
                          color: AppTheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _title,
                          style: Theme.of(ctx)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _SectionLabel('DIFFICULTY'),
                  const SizedBox(height: 6),
                  _DifficultyChips(
                    selected: _difficulty,
                    onChanged: (d) => setState(() => _difficulty = d),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _difficulty.descriptionForGame(widget.gameType),
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 20),
                  ScriptureScopePicker(
                    initial: _scope,
                    usageContext: _usageContext,
                    onChanged: (s) => setState(() => _scope = s),
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel(_countLabel),
                  const SizedBox(height: 6),
                  _CountSegmented(
                    everyScripture: _everyScripture,
                    defaultLabel: _defaultCountLabel,
                    everyLabel: 'Every scripture (${resolved.length})',
                    onChanged: (v) => setState(() => _everyScripture = v),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          resolved.isEmpty ? null : () => _start(ctx, resolved),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
        );
      },
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
    final scriptures = _scope is ScopeAll ? null : resolved;
    final bookFilters = _scope is ScopeBooks
        ? (_scope as ScopeBooks).books.toList()
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
              targetPairCount: everyScripture ? resolved.length : null,
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
  ///   * Scope = All + default → null (the provider samples by difficulty).
  ///   * Specifically-picked scriptures → exactly those.
  ///   * Any other scope (book / needs-review / nearly-mastered) + default →
  ///     a shuffled sample of [DifficultyLevel.scriptureCount].
  List<Scripture>? _builderQueue(
    List<Scripture> resolved,
    bool everyScripture,
    DifficultyLevel difficulty,
  ) {
    if (everyScripture) return resolved;
    if (_scope is ScopeAll) return null;
    final pool = List<Scripture>.from(resolved)..shuffle();
    final cap = _scope is ScopeScriptureIds
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
  final DifficultyLevel selected;
  final ValueChanged<DifficultyLevel> onChanged;

  const _DifficultyChips({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DifficultyLevel.values.map((d) {
        final isSelected = d == selected;
        return ChoiceChip(
          label: Text(d.label),
          selected: isSelected,
          onSelected: (_) => onChanged(d),
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.onPrimary : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          selectedColor: AppTheme.primary,
        );
      }).toList(),
    );
  }
}

class _CountSegmented extends StatelessWidget {
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text('Default · $defaultLabel'),
          selected: !everyScripture,
          onSelected: (_) => onChanged(false),
          labelStyle: TextStyle(
            color: !everyScripture ? AppTheme.onPrimary : null,
            fontWeight: !everyScripture ? FontWeight.bold : FontWeight.normal,
          ),
          selectedColor: AppTheme.primary,
        ),
        ChoiceChip(
          label: Text(everyLabel),
          selected: everyScripture,
          onSelected: (_) => onChanged(true),
          labelStyle: TextStyle(
            color: everyScripture ? AppTheme.onPrimary : null,
            fontWeight: everyScripture ? FontWeight.bold : FontWeight.normal,
          ),
          selectedColor: AppTheme.primary,
        ),
      ],
    );
  }
}
