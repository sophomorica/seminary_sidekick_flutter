import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/enums.dart';
import '../../models/scripture.dart';
import '../../providers/scripture_provider.dart';
import '../../providers/scripture_mastery_provider.dart';
import '../../theme/app_theme.dart';

/// Sacred Editorial Scripture Library — browse all 100 scriptures by volume.
class ScriptureLibraryScreen extends ConsumerStatefulWidget {
  const ScriptureLibraryScreen({super.key});

  @override
  ConsumerState<ScriptureLibraryScreen> createState() =>
      _ScriptureLibraryScreenState();
}

class _ScriptureLibraryScreenState
    extends ConsumerState<ScriptureLibraryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allScriptures = ref.watch(scripturesProvider);
    ref.watch(holisticStatsProvider);

    // Filter by search query
    final filtered = _searchQuery.isEmpty
        ? allScriptures
        : ref.watch(searchScripturesProvider(_searchQuery));

    // Group by book
    final bookGroups = <ScriptureBook, List<Scripture>>{};
    for (final s in filtered) {
      bookGroups.putIfAbsent(s.book, () => []).add(s);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Editorial header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scripture\nLibrary',
                    style: theme.textTheme.displayLarge?.copyWith(
                      height: 1.1,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Explore the foundational texts of our faith.\nOrganized by volume for purposeful study.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Search bar — editorial style (no bottom line, filled)
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search verses or keywords...',
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.outline,
                        ),
                        prefixIcon:
                            const Icon(Icons.search, color: AppTheme.outline),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Book sections
          for (final book in ScriptureBook.values)
            if (bookGroups.containsKey(book)) ...[
              _buildBookHeader(context, book, bookGroups[book]!),
              _buildScriptureList(context, bookGroups[book]!),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],

          // Bottom padding for nav bar
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildBookHeader(
      BuildContext context, ScriptureBook book, List<Scripture> scriptures) {
    final theme = Theme.of(context);
    // Calculate mastery percentage for this book
    final masteredCount = scriptures.where((s) {
      final mastery = ref.watch(scriptureMasteryProvider(s.id));
      return mastery.level.index >= MasteryLevel.mastered.index;
    }).length;
    final pct = scriptures.isEmpty
        ? 0
        : (masteredCount * 100 / scriptures.length).round();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Container(
              width: 4,
              height: 28,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Text(
                book.displayName,
                style: theme.textTheme.headlineMedium,
              ),
            ),
            Text(
              '$pct% Mastered',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppTheme.secondary,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScriptureList(BuildContext context, List<Scripture> scriptures) {
    final theme = Theme.of(context);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final scripture = scriptures[index];
            final mastery = ref.watch(scriptureMasteryProvider(scripture.id));
            final level = mastery.level;
            final progress = mastery.subProgress;

            return GestureDetector(
              onTap: () => context.push('/scripture/${scripture.id}'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: level == MasteryLevel.newScripture
                      ? theme.colorScheme.surfaceContainerLow
                      : theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  boxShadow: AppTheme.editorialShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reference + mastery chip
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            scripture.reference,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        _masteryChip(context, level),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Key phrase
                    Text(
                      scripture.keyPhrase,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppTheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    // Progress bar
                    Row(
                      children: [
                        Text(
                          'MASTERY PROGRESS',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.secondary,
                            letterSpacing: 2,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${progress.round()}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.secondary,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        minHeight: 6,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(
                          level.index >= MasteryLevel.mastered.index
                              ? AppTheme.tertiary
                              : AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: scriptures.length,
        ),
      ),
    );
  }

  Widget _masteryChip(BuildContext context, MasteryLevel level) {
    final theme = Theme.of(context);
    final (label, color, icon) = switch (level) {
      MasteryLevel.newScripture => (
          'Queued',
          AppTheme.secondary,
          Icons.schedule
        ),
      MasteryLevel.learning => (
          'Learning',
          AppTheme.primary,
          Icons.auto_stories
        ),
      MasteryLevel.familiar => (
          'Familiar',
          AppTheme.primaryContainer,
          Icons.auto_stories
        ),
      MasteryLevel.memorized => (
          'Memorized',
          AppTheme.secondary,
          Icons.psychology
        ),
      MasteryLevel.mastered => ('Mastered', AppTheme.tertiary, Icons.stars),
      MasteryLevel.eternal => ('Eternal', AppTheme.tertiary, Icons.stars),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
