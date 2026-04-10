import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/scripture.dart';
import '../providers/progress_provider.dart';
import '../providers/scripture_provider.dart';
import '../providers/scripture_mastery_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/mastery_badge.dart';
import 'games/matching_game_screen.dart';
import 'games/quiz_game_screen.dart';
import 'games/word_builder/word_builder_screen.dart';

class PracticeHubScreen extends ConsumerStatefulWidget {
  const PracticeHubScreen({super.key});

  @override
  ConsumerState<PracticeHubScreen> createState() => _PracticeHubScreenState();
}

class _PracticeHubScreenState extends ConsumerState<PracticeHubScreen> {
  DifficultyLevel _selectedDifficulty = DifficultyLevel.beginner;

  @override
  Widget build(BuildContext context) {
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
              _PathSelector(
                selectedDifficulty: _selectedDifficulty,
                onDifficultyChanged: (d) =>
                    setState(() => _selectedDifficulty = d),
              ),
              const SizedBox(height: 32.0),

              // Hero Word Builder Card
              _WordBuilderHeroCard(difficulty: _selectedDifficulty),
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
  final DifficultyLevel difficulty;

  const _WordBuilderHeroCard({required this.difficulty});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastScriptureId = ref.watch(lastWordBuilderScriptureIdProvider);
    final lastScripture = lastScriptureId != null
        ? ref.watch(scriptureByIdProvider(lastScriptureId))
        : null;

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
                      // Show "Continue" button if there's a last-practiced scripture
                      if (lastScripture != null) ...[
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
                            ),
                            onPressed: () => _launchWithScripture(
                                context, lastScripture),
                            child: Text(
                              'Continue: ${lastScripture.reference}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: AppTheme.onTertiary,
                                    fontWeight: FontWeight.bold,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.onPrimary,
                              side: BorderSide(
                                color:
                                    AppTheme.onPrimary.withValues(alpha: 0.5),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                                horizontal: 24.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50.0),
                              ),
                            ),
                            onPressed: () =>
                                _showScripturePicker(context, ref),
                            child: Text(
                              'Pick a Different Scripture',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: AppTheme.onPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ),
                      ] else
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
                            ),
                            onPressed: () =>
                                _showScripturePicker(context, ref),
                            child: Text(
                              'Choose a Scripture',
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

  void _launchWithScripture(BuildContext context, Scripture scripture) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WordBuilderScreen(
          difficulty: difficulty,
          scriptures: [scripture],
        ),
      ),
    );
  }

  void _showScripturePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ScripturePickerSheet(
        difficulty: difficulty,
      ),
    );
  }
}

/// Bottom sheet that lets the user pick a scripture for Word Builder.
/// Groups scriptures by book with mastery badges.
class _ScripturePickerSheet extends ConsumerStatefulWidget {
  final DifficultyLevel difficulty;

  const _ScripturePickerSheet({required this.difficulty});

  @override
  ConsumerState<_ScripturePickerSheet> createState() =>
      _ScripturePickerSheetState();
}

class _ScripturePickerSheetState extends ConsumerState<_ScripturePickerSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final allScriptures = ref.watch(scripturesProvider);
    final filteredScriptures = _searchQuery.isEmpty
        ? allScriptures
        : allScriptures.where((s) {
            final q = _searchQuery.toLowerCase();
            return s.reference.toLowerCase().contains(q) ||
                s.name.toLowerCase().contains(q) ||
                s.keyPhrase.toLowerCase().contains(q);
          }).toList();

    // Group by book
    final grouped = <ScriptureBook, List<Scripture>>{};
    for (final s in filteredScriptures) {
      grouped.putIfAbsent(s.book, () => []).add(s);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24.0),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Choose a Scripture',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 8.0),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search scriptures...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 12.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4.0),
              // Scripture list
              Expanded(
                child: filteredScriptures.isEmpty
                    ? Center(
                        child: Text(
                          'No scriptures match your search',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: _buildListItems(grouped).length,
                        itemBuilder: (context, index) {
                          final item = _buildListItems(grouped)[index];
                          if (item is ScriptureBook) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                  top: 16.0, bottom: 8.0, left: 8.0),
                              child: Text(
                                item.displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                            );
                          }
                          final scripture = item as Scripture;
                          final mastery = ref
                              .watch(scriptureMasteryProvider(scripture.id));
                          return _ScripturePickerTile(
                            scripture: scripture,
                            masteryLevel: mastery.level,
                            onTap: () {
                              Navigator.pop(context); // Close bottom sheet
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => WordBuilderScreen(
                                    difficulty: widget.difficulty,
                                    scriptures: [scripture],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds a flat list of headers (ScriptureBook) and scriptures for the ListView.
  List<Object> _buildListItems(Map<ScriptureBook, List<Scripture>> grouped) {
    final items = <Object>[];
    for (final book in ScriptureBook.values) {
      final scriptures = grouped[book];
      if (scriptures != null && scriptures.isNotEmpty) {
        items.add(book);
        items.addAll(scriptures);
      }
    }
    return items;
  }
}

/// A single scripture tile in the picker bottom sheet.
class _ScripturePickerTile extends StatelessWidget {
  final Scripture scripture;
  final MasteryLevel masteryLevel;
  final VoidCallback onTap;

  const _ScripturePickerTile({
    required this.scripture,
    required this.masteryLevel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3.0),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        leading: MasteryBadge.compact(
          masteryLevel: masteryLevel,
        ),
        title: Text(
          scripture.reference,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Text(
          scripture.name,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }
}

/// Path Selector — Difficulty selection control
class _PathSelector extends StatelessWidget {
  final DifficultyLevel selectedDifficulty;
  final ValueChanged<DifficultyLevel> onDifficultyChanged;

  const _PathSelector({
    required this.selectedDifficulty,
    required this.onDifficultyChanged,
  });

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
            label: 'Easy',
            isSelected: selectedDifficulty == DifficultyLevel.beginner,
            onPressed: () => onDifficultyChanged(DifficultyLevel.beginner),
          ),
          _PathButton(
            label: 'Medium',
            isSelected: selectedDifficulty == DifficultyLevel.intermediate,
            onPressed: () => onDifficultyChanged(DifficultyLevel.intermediate),
          ),
          _PathButton(
            label: 'Master',
            isSelected: selectedDifficulty == DifficultyLevel.master,
            onPressed: () => onDifficultyChanged(DifficultyLevel.master),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.secondary.withValues(alpha: 0.15)
            : AppTheme.secondaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark
              ? AppTheme.secondaryFixedDim.withValues(alpha: 0.3)
              : AppTheme.secondary.withValues(alpha: 0.25),
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
                    color: isDark
                        ? AppTheme.secondary.withValues(alpha: 0.3)
                        : AppTheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(
                    Icons.layers,
                    color: isDark ? AppTheme.secondaryFixedDim : AppTheme.secondary,
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
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Match key phrases with their scripture references. Tests your recognition and familiarity.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                      color: isDark ? AppTheme.secondaryFixedDim : AppTheme.secondaryDark,
                    ),
              ),
              icon: Icon(
                Icons.arrow_forward,
                color: isDark ? AppTheme.secondaryFixedDim : AppTheme.secondaryDark,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.tertiary.withValues(alpha: 0.15)
            : AppTheme.tertiaryFixed.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark
              ? AppTheme.tertiaryFixedDim.withValues(alpha: 0.3)
              : AppTheme.tertiary.withValues(alpha: 0.25),
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
                    color: isDark
                        ? AppTheme.tertiary.withValues(alpha: 0.3)
                        : AppTheme.tertiaryFixedDim.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(
                    Icons.quiz,
                    color: isDark ? AppTheme.tertiaryFixedDim : AppTheme.tertiary,
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
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Answer questions about scripture passages. Tests your comprehension and understanding.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                      color: isDark ? AppTheme.tertiaryFixedDim : AppTheme.onTertiaryFixed,
                    ),
              ),
              icon: Icon(
                Icons.arrow_forward,
                color: isDark ? AppTheme.tertiaryFixedDim : AppTheme.onTertiaryFixed,
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
