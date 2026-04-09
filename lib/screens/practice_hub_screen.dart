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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Editorial header
              const SizedBox(height: 48.0),
              Text(
                'Practice Hub',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontFamily: 'Merriweather',
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
              ),
              const SizedBox(height: 16.0),
              Text(
                'Engage with sacred texts through focused exercises designed to deepen your spiritual retention and understanding.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32.0),

              // Path Selector
              _PathSelector(),
              const SizedBox(height: 32.0),

              // Hero Word Builder Card
              _WordBuilderHeroCard(),
              const SizedBox(height: 32.0),

              // Scripture Match & Quick Quiz cards
              _MatchingGameCard(),
              const SizedBox(height: 16.0),
              _QuizGameCard(),
              const SizedBox(height: 32.0),

              // Sacred Achievement section
              _SacredAchievementSection(),

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
    return Stack(
      children: [
        // Decorative blurred circle in top right
        Positioned(
          top: -40,
          right: -40,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.tertiary.withValues(alpha: 0.1),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.tertiary.withValues(alpha: 0.08),
                  blurRadius: 40,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
        ),
        Container(
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
            padding: const EdgeInsets.all(32.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side: content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "FEATURED MASTERY" badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 6.0,
                        ),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.tertiaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(
                            color: AppTheme.tertiaryFixedDim
                                .withValues(alpha: 0.2),
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          'FEATURED MASTERY',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppTheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2.0,
                                    fontSize: 10.0,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        'Word Builder',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontFamily: 'Merriweather',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              color: AppTheme.onPrimary,
                            ),
                      ),
                      const SizedBox(height: 12.0),
                      Text(
                        'Prove your mastery through progressive word-building exercises. Master all four difficulty levels to achieve scripture mastery.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.onPrimary.withValues(alpha: 0.85),
                              height: 1.6,
                            ),
                      ),
                      const SizedBox(height: 24.0),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.tertiary,
                            foregroundColor: AppTheme.onTertiary,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14.0,
                              horizontal: 24.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50.0),
                            ),
                            elevation: 0,
                            shadowColor:
                                AppTheme.tertiary.withValues(alpha: 0.4),
                          ),
                          onPressed: () {
                            _launchWordBuilder(context);
                          },
                          child: Text(
                            'Start Building',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: AppTheme.onTertiary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24.0),
                // Right side: icon area
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.tertiaryFixed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: const Icon(
                    Icons.build,
                    size: 48,
                    color: AppTheme.tertiaryFixed,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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

/// Path Selector — Difficulty selection control
class _PathSelector extends StatefulWidget {
  @override
  State<_PathSelector> createState() => _PathSelectorState();
}

class _PathSelectorState extends State<_PathSelector> {
  DifficultyLevel _selectedDifficulty = DifficultyLevel.beginner;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(50.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _PathButton(
            label: 'Beginner',
            isSelected: _selectedDifficulty == DifficultyLevel.beginner,
            onPressed: () {
              setState(() => _selectedDifficulty = DifficultyLevel.beginner);
            },
          ),
          _PathButton(
            label: 'Intermediate',
            isSelected: _selectedDifficulty == DifficultyLevel.intermediate,
            onPressed: () {
              setState(
                  () => _selectedDifficulty = DifficultyLevel.intermediate);
            },
          ),
          _PathButton(
            label: 'Master',
            isSelected: _selectedDifficulty == DifficultyLevel.master,
            onPressed: () {
              setState(() => _selectedDifficulty = DifficultyLevel.master);
            },
          ),
        ],
      ),
    );
  }
}

/// Individual path button in the selector
class _PathButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _PathButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(50.0),
                boxShadow: AppTheme.editorialShadow,
              )
            : null,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(50.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Center(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: isSelected
                            ? AppTheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                ),
              ),
            ),
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
  final DifficultyLevel _selectedDifficulty = DifficultyLevel.beginner;
  final Set<ScriptureBook> _selectedBooks = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.secondaryContainer.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + Title + Description
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(
                    Icons.layers,
                    color: AppTheme.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scripture Match',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontFamily: 'Merriweather',
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic,
                                  color: AppTheme.onSecondaryContainer,
                                ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Match key phrases with their scripture references. Tests your recognition and familiarity.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.onSecondaryContainer,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            // "Begin Session" button
            TextButton.icon(
              onPressed: () => _launchMatching(context),
              label: Text(
                'Begin Session',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.secondary,
                    ),
              ),
              icon: const Icon(
                Icons.arrow_forward,
                color: AppTheme.secondary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
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
  final DifficultyLevel _selectedDifficulty = DifficultyLevel.beginner;
  final Set<ScriptureBook> _selectedBooks = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.tertiaryFixed.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.tertiaryFixedDim.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + Title + Description
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.tertiaryFixedDim.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(
                    Icons.quiz,
                    color: AppTheme.tertiary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Quiz',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontFamily: 'Merriweather',
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic,
                                  color: AppTheme.onTertiaryContainer,
                                ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Answer questions about scripture passages. Tests your comprehension and understanding.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.onTertiaryContainer,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            // "Take Quiz" button
            TextButton.icon(
              onPressed: () => _launchQuiz(context),
              label: Text(
                'Take Quiz',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.tertiary,
                    ),
              ),
              icon: const Icon(
                Icons.arrow_forward,
                color: AppTheme.tertiary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
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

/// Sacred Achievement section at bottom
class _SacredAchievementSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sacred Achievement',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontFamily: 'Merriweather',
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12.0),
          Text(
            'Complete 3 Practice sessions today to unlock your next Mastery Badge',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24.0),
          // Progress bar
          Container(
            height: 8.0,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Stack(
              children: [
                Container(
                  height: 8.0,
                  width: MediaQuery.of(context).size.width * 0.66,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24.0),
          // Medal icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MedalIcon(),
              const SizedBox(width: 24.0),
              _MedalIcon(),
              const SizedBox(width: 24.0),
              _MedalIcon(),
            ],
          ),
        ],
      ),
    );
  }
}

/// Medal icon component
class _MedalIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56.0,
      height: 56.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.tertiary.withValues(alpha: 0.1),
        border: Border.all(
          color: AppTheme.tertiary.withValues(alpha: 0.3),
          width: 2.0,
        ),
      ),
      child: const Icon(
        Icons.emoji_events,
        color: AppTheme.tertiary,
        size: 28.0,
      ),
    );
  }
}
