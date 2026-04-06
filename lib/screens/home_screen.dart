import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/enums.dart';
import '../providers/scripture_provider.dart';
import '../providers/scripture_mastery_provider.dart';
import '../providers/spaced_repetition_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/scripture_card.dart';
import 'onboarding_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allScriptures = ref.watch(scripturesProvider);
    final stats = ref.watch(holisticStatsProvider);

    // Smart review queue powered by spaced repetition (SR overdue first,
    // then mastery-decay needsReview, then almost-leveling-up scriptures)
    final smartQueue = ref.watch(smartReviewQueueProvider);
    final dueCount = ref.watch(dueCountProvider);

    // Fall back to random scriptures if queue is empty (brand new user)
    final continueLearningScriptures = smartQueue.isNotEmpty
        ? smartQueue.take(5).toList()
        : (List.of(allScriptures)..shuffle()).take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seminary Sidekick'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'How mastery works',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const OnboardingScreen(isRevisit: true),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: Theme.of(context).brightness == Brightness.dark
                ? 'Switch to light mode'
                : 'Switch to dark mode',
            onPressed: () {
              ref.read(themeProvider.notifier).toggle(
                    Theme.of(context).brightness,
                  );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Master your scriptures',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Continue your spiritual journey through daily practice',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Quick stats section
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _StatCard(
                    label: 'Mastered',
                    value: stats.mastered.toString(),
                    icon: Icons.workspace_premium,
                    color: Color(MasteryLevel.mastered.color),
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Memorized',
                    value: stats.memorized.toString(),
                    icon: Icons.check_circle,
                    color: AppTheme.secondary,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Need Review',
                    value: stats.needsReview.toString(),
                    icon: Icons.schedule,
                    color: AppTheme.warning,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Scripture Collections section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Scripture Collections',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
                children: ScriptureBook.values.map((book) {
                  final bookScriptures = ref.watch(
                    scripturesByBookProvider(book),
                  );

                  return _BookCard(
                    book: book,
                    passageCount: bookScriptures.length,
                    onTap: () {
                      context.push('/scriptures/${book.name}');
                    },
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 32),

            // Continue Learning section (powered by spaced repetition)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Continue Learning',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        if (dueCount > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '$dueCount scripture${dueCount == 1 ? '' : 's'} due for review',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.warning,
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (dueCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule,
                              size: 14, color: AppTheme.warning),
                          const SizedBox(width: 4),
                          Text(
                            '$dueCount',
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppTheme.warning,
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: continueLearningScriptures.length,
                itemBuilder: (context, index) {
                  final scripture = continueLearningScriptures[index];
                  return ScriptureCard(
                    scripture: scripture,
                    onTap: () {
                      context.push('/scripture/${scripture.id}');
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final ScriptureBook book;
  final int passageCount;
  final VoidCallback onTap;

  const _BookCard({
    required this.book,
    required this.passageCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getIconForBook(book),
                size: 32,
                color: AppTheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                book.displayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '$passageCount passages',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForBook(ScriptureBook book) {
    switch (book) {
      case ScriptureBook.oldTestament:
        return Icons.book;
      case ScriptureBook.newTestament:
        return Icons.favorite;
      case ScriptureBook.bookOfMormon:
        return Icons.star;
      case ScriptureBook.doctrineAndCovenants:
        return Icons.lightbulb;
    }
  }
}
