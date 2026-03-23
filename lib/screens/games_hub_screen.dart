import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../theme/app_theme.dart';
import 'games/matching_game_screen.dart';
import 'games/word_builder_screen.dart';
import 'games/quiz_game_screen.dart';

class GamesHubScreen extends ConsumerWidget {
  const GamesHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Games'),
        elevation: 0,
        backgroundColor: AppTheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a game to practice',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 24),
            ...GameType.values.map((gameType) {
              return _GameCard(gameType: gameType);
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatefulWidget {
  final GameType gameType;

  const _GameCard({required this.gameType});

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard> {
  DifficultyLevel _selectedDifficulty = DifficultyLevel.beginner;
  ScriptureBook? _selectedBook; // null = all books

  @override
  Widget build(BuildContext context) {
    final color = _getColorForGame(widget.gameType);
    final isAvailable = true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        color: color.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Game header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
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
                                    color: Colors.grey.shade600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (isAvailable) ...[
                const SizedBox(height: 16),

                // Book filter
                Text(
                  'Filter by Book',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildBookChip(context, null, 'All', color),
                      ...ScriptureBook.values.map((book) {
                        return _buildBookChip(
                          context,
                          book,
                          book.abbreviation,
                          color,
                        );
                      }),
                    ],
                  ),
                ),
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
                          selectedColor: color.withOpacity(0.2),
                          side: BorderSide(
                            color: isSelected ? color : color.withOpacity(0.3),
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? color : Colors.grey.shade700,
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
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                ),
                const SizedBox(height: 16),

                // Play button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _launchGame(context),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow, size: 24),
                        SizedBox(width: 8),
                        Text('Play', style: TextStyle(fontSize: 16)),
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

  Widget _buildBookChip(
    BuildContext context,
    ScriptureBook? book,
    String label,
    Color accentColor,
  ) {
    final isSelected = _selectedBook == book;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedBook = book);
        },
        selectedColor: accentColor.withOpacity(0.2),
        side: BorderSide(
          color: isSelected ? accentColor : Colors.grey.shade300,
        ),
        labelStyle: TextStyle(
          color: isSelected ? accentColor : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }

  void _launchGame(BuildContext context) {
    if (widget.gameType == GameType.matching) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MatchingGameScreen(
            difficulty: _selectedDifficulty,
            bookFilter: _selectedBook,
          ),
        ),
      );
    } else if (widget.gameType == GameType.wordOrder) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WordBuilderScreen(
            difficulty: _selectedDifficulty,
            bookFilter: _selectedBook,
          ),
        ),
      );
    } else if (widget.gameType == GameType.quiz) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuizGameScreen(
            difficulty: _selectedDifficulty,
            bookFilter: _selectedBook,
          ),
        ),
      );
    }
  }

  Color _getColorForGame(GameType gameType) {
    switch (gameType) {
      case GameType.matching:
        return AppTheme.primary;
      case GameType.wordOrder:
        return AppTheme.secondary;
      case GameType.quiz:
        return AppTheme.gold;
    }
  }
}
