import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../theme/app_theme.dart';
import 'games/matching_game_screen.dart';
import 'games/quiz_game_screen.dart';

class PracticeHubScreen extends ConsumerWidget {
  const PracticeHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only show supplementary practice quizzes — Word Builder lives under scripture detail
    final practiceQuizTypes = GameType.values
        .where((gt) => gt != GameType.wordOrder)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sharpen your recognition with practice quizzes',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 24),
            ...practiceQuizTypes.map((gameType) {
              return _QuizCard(gameType: gameType);
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _QuizCard extends StatefulWidget {
  final GameType gameType;

  const _QuizCard({required this.gameType});

  @override
  State<_QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<_QuizCard> {
  DifficultyLevel _selectedDifficulty = DifficultyLevel.beginner;
  Set<ScriptureBook> _selectedBooks = {}; // empty = all books

  @override
  Widget build(BuildContext context) {
    final color = _getColorForQuiz(widget.gameType);
    const isAvailable = true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        color: color.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quiz header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.gameType.icon,
                      color: color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.gameType.displayName,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.gameType.description,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (isAvailable) ...[
                const SizedBox(height: 16),

                // Book filter — multi-select for both matching and quiz
                Text(
                  'Select Books',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                _buildMultiSelectBookFilter(context, color),
                const SizedBox(height: 16),

                // Difficulty selector
                Text(
                  'Difficulty',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: DifficultyLevel.values.map((difficulty) {
                      final isSelected = _selectedDifficulty == difficulty;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(difficulty.label),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() => _selectedDifficulty = difficulty);
                          },
                          selectedColor: color.withValues(alpha: 0.2),
                          side: BorderSide(
                            color: isSelected
                                ? color
                                : color.withValues(alpha: 0.3),
                          ),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? color
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.7),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _selectedDifficulty.descriptionForGame(widget.gameType),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                ),
                const SizedBox(height: 16),

                // Start button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _launchQuiz(context),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow, size: 24),
                        SizedBox(width: 8),
                        Text('Start', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelectBookFilter(BuildContext context, Color accentColor) {
    final allSelected = _selectedBooks.isEmpty;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // "All" chip — selected when no individual books are selected
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: allSelected,
              onSelected: (_) {
                setState(() => _selectedBooks = {});
              },
              selectedColor: accentColor.withValues(alpha: 0.2),
              checkmarkColor: accentColor,
              side: BorderSide(
                color: allSelected
                    ? accentColor
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              labelStyle: TextStyle(
                color: allSelected
                    ? accentColor
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                fontWeight: allSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
          ...ScriptureBook.values.map((book) {
            final isSelected = _selectedBooks.contains(book);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(book.abbreviation),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedBooks = {..._selectedBooks, book};
                      // If all 4 books are now selected, clear to "All"
                      if (_selectedBooks.length == ScriptureBook.values.length) {
                        _selectedBooks = {};
                      }
                    } else {
                      _selectedBooks = {..._selectedBooks}..remove(book);
                    }
                  });
                },
                selectedColor: accentColor.withValues(alpha: 0.2),
                checkmarkColor: accentColor,
                side: BorderSide(
                  color: isSelected
                      ? accentColor
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                labelStyle: TextStyle(
                  color: isSelected
                      ? accentColor
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _launchQuiz(BuildContext context) {
    if (widget.gameType == GameType.matching) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MatchingGameScreen(
            difficulty: _selectedDifficulty,
            bookFilters: _selectedBooks.toList(),
          ),
        ),
      );
    } else if (widget.gameType == GameType.quiz) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuizGameScreen(
            difficulty: _selectedDifficulty,
            bookFilters: _selectedBooks.toList(),
          ),
        ),
      );
    }
  }

  Color _getColorForQuiz(GameType gameType) {
    switch (gameType) {
      case GameType.matching:
        return AppTheme.primary;
      case GameType.quiz:
        return AppTheme.gold;
      default:
        return AppTheme.secondary;
    }
  }
}
