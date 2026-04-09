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
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Editorial header
              const SizedBox(height: AppTheme.spacingLg),
              Text(
                'Practice Hub',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'Master through focused exercises and reflection',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: AppTheme.spacingXl),

              // Hero Word Builder Card
              _WordBuilderHeroCard(),
              const SizedBox(height: AppTheme.spacingXl),

              // Practice Quizzes Section
              Text(
                'Supplementary Practice',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // Scripture Match & Quick Quiz cards
              _MatchingGameCard(),
              const SizedBox(height: AppTheme.spacingMd),
              _QuizGameCard(),

              const SizedBox(height: 120), // Bottom padding for floating nav
            ],
          ),
        ),
      ),
    );
  }
}

/// Hero card for Word Builder — the primary mastery tool
class _WordBuilderHeroCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary,
            AppTheme.primaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.editorialShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Word Builder',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Prove your mastery through progressive word-building exercises. Master all four difficulty levels to achieve scripture mastery.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onPrimary,
                    height: 1.6,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.onPrimary,
                  foregroundColor: AppTheme.primary,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                ),
                onPressed: () {
                  _launchWordBuilder(context);
                },
                child: Text(
                  'Start Building',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.primary,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchWordBuilder(BuildContext context) {
    // Navigate to scripture list to select a scripture first
    // or use a default flow
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(
            child: Text('Word Builder — select from scripture detail'),
          ),
        ),
      ),
    );
  }
}

/// Scripture Match card
class _MatchingGameCard extends StatefulWidget {
  @override
  State<_MatchingGameCard> createState() => _MatchingGameCardState();
}

class _MatchingGameCardState extends State<_MatchingGameCard> {
  DifficultyLevel _selectedDifficulty = DifficultyLevel.beginner;
  Set<ScriptureBook> _selectedBooks = {};

  @override
  Widget build(BuildContext context) {
    return _PracticeCard(
      title: 'Scripture Match',
      description:
          'Match key phrases with their scripture references. Tests your recognition and familiarity.',
      icon: Icons.layers,
      iconColor: AppTheme.primary,
      difficulty: _selectedDifficulty,
      selectedBooks: _selectedBooks,
      onDifficultyChanged: (d) {
        setState(() => _selectedDifficulty = d);
      },
      onBooksChanged: (books) {
        setState(() => _selectedBooks = books);
      },
      onPressed: () => _launchMatching(context),
      buttonLabel: 'Begin Match',
    );
  }

  void _launchMatching(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MatchingGameScreen(
          difficulty: _selectedDifficulty,
          bookFilters: _selectedBooks.toList(),
        ),
      ),
    );
  }
}

/// Quick Quiz card
class _QuizGameCard extends StatefulWidget {
  @override
  State<_QuizGameCard> createState() => _QuizGameCardState();
}

class _QuizGameCardState extends State<_QuizGameCard> {
  DifficultyLevel _selectedDifficulty = DifficultyLevel.beginner;
  Set<ScriptureBook> _selectedBooks = {};

  @override
  Widget build(BuildContext context) {
    return _PracticeCard(
      title: 'Quick Quiz',
      description:
          'Answer questions about scripture passages. Tests your comprehension and understanding.',
      icon: Icons.quiz,
      iconColor: AppTheme.tertiary,
      difficulty: _selectedDifficulty,
      selectedBooks: _selectedBooks,
      onDifficultyChanged: (d) {
        setState(() => _selectedDifficulty = d);
      },
      onBooksChanged: (books) {
        setState(() => _selectedBooks = books);
      },
      onPressed: () => _launchQuiz(context),
      buttonLabel: 'Take Quiz',
    );
  }

  void _launchQuiz(BuildContext context) {
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

/// Reusable practice card component
class _PracticeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final DifficultyLevel difficulty;
  final Set<ScriptureBook> selectedBooks;
  final ValueChanged<DifficultyLevel> onDifficultyChanged;
  final ValueChanged<Set<ScriptureBook>> onBooksChanged;
  final VoidCallback onPressed;
  final String buttonLabel;

  const _PracticeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.difficulty,
    required this.selectedBooks,
    required this.onDifficultyChanged,
    required this.onBooksChanged,
    required this.onPressed,
    required this.buttonLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.editorialShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + Icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSm),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Book filter
            Text(
              'Select Books',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            _buildMultiSelectBookFilter(context, iconColor),
            const SizedBox(height: AppTheme.spacingMd),

            // Difficulty filter
            Text(
              'Difficulty',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            _buildDifficultyChips(context, iconColor),
            const SizedBox(height: AppTheme.spacingLg),

            // Start button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                ),
                onPressed: onPressed,
                child: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyChips(BuildContext context, Color accentColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: DifficultyLevel.values.map((d) {
          final isSelected = difficulty == d;
          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacingSm),
            child: FilterChip(
              label: Text(d.label),
              selected: isSelected,
              onSelected: (_) => onDifficultyChanged(d),
              backgroundColor: AppTheme.surfaceContainerLow,
              selectedColor: accentColor.withValues(alpha: 0.2),
              side: BorderSide(
                color: isSelected
                    ? accentColor
                    : AppTheme.outline.withValues(alpha: 0.2),
              ),
              labelStyle: TextStyle(
                color: isSelected ? accentColor : AppTheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMultiSelectBookFilter(BuildContext context, Color accentColor) {
    final allSelected = selectedBooks.isEmpty;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacingSm),
            child: FilterChip(
              label: const Text('All'),
              selected: allSelected,
              onSelected: (_) => onBooksChanged({}),
              backgroundColor: AppTheme.surfaceContainerLow,
              selectedColor: accentColor.withValues(alpha: 0.2),
              side: BorderSide(
                color: allSelected
                    ? accentColor
                    : AppTheme.outline.withValues(alpha: 0.2),
              ),
              labelStyle: TextStyle(
                color: allSelected ? accentColor : AppTheme.onSurface,
                fontWeight: allSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          ...ScriptureBook.values.map((book) {
            final isSelected = selectedBooks.contains(book);
            return Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingSm),
              child: FilterChip(
                label: Text(book.abbreviation),
                selected: isSelected,
                onSelected: (selected) {
                  Set<ScriptureBook> updated = {...selectedBooks};
                  if (selected) {
                    updated.add(book);
                    // Auto-clear if all selected
                    if (updated.length == ScriptureBook.values.length) {
                      updated.clear();
                    }
                  } else {
                    updated.remove(book);
                  }
                  onBooksChanged(updated);
                },
                backgroundColor: AppTheme.surfaceContainerLow,
                selectedColor: accentColor.withValues(alpha: 0.2),
                side: BorderSide(
                  color: isSelected
                      ? accentColor
                      : AppTheme.outline.withValues(alpha: 0.2),
                ),
                labelStyle: TextStyle(
                  color: isSelected ? accentColor : AppTheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
