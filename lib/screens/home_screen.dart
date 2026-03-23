import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/enums.dart';
import '../providers/scripture_provider.dart';
import '../providers/progress_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/scripture_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allScriptures = ref.watch(scripturesProvider);
    final stats = ref.watch(userStatsProvider);

    // Get scriptures that need review
    final needsReviewScriptures = allScriptures.where((scripture) {
      // Check if any game type needs review
      for (final gameType in GameType.values) {
        final progress = ref.watch(
          progressByScriptureProvider(
            (scripture.id, gameType),
          ),
        );
        if (progress?.needsReview ?? false) {
          return true;
        }
      }
      return false;
    }).toList();

    // Fallback to random scriptures if none need review
    final continueLearningScriptures = needsReviewScriptures.isEmpty
        ? (allScriptures..shuffle()).take(3).toList()
        : needsReviewScriptures.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seminary Sidekick'),
        elevation: 0,
        backgroundColor: AppTheme.surface,
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
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
                    value: stats.totalMastered.toString(),
                    icon: Icons.check_circle,
                    color: AppTheme.secondary,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Need Review',
                    value: stats.needsReview.toString(),
                    icon: Icons.refresh,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Streak',
                    value: stats.currentStreak.toString(),
                    icon: Icons.local_fire_department,
                    color: Colors.orange,
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
                childAspectRatio: 1.1,
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

            // Continue Learning section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Continue Learning',
                style: Theme.of(context).textTheme.headlineSmall,
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
