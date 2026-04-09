import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/scripture.dart';
import '../../providers/activity_provider.dart';
import '../../providers/scripture_provider.dart';
import '../../providers/scripture_mastery_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/progress_ring.dart';
import 'activity_tile.dart';
import 'goals_timeline_section.dart';
import 'stats_grid.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(holisticStatsProvider);
    final allScriptures = ref.watch(scripturesProvider);
    final recentActivities = ref.watch(recentActivitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Progress'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall progress ring
            Center(
              child: Column(
                children: [
                  ProgressRing(
                    value: stats.totalScriptures > 0
                        ? stats.mastered / stats.totalScriptures
                        : 0.0,
                    size: 200,
                    color: Color(MasteryLevel.mastered.color),
                    label: '${stats.mastered}/${stats.totalScriptures}',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Scriptures Mastered',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (stats.overallAccuracy > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${stats.overallAccuracy.toStringAsFixed(0)}% overall accuracy',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Stats row
            StatsGrid(stats: stats),
            const SizedBox(height: 32),

            // Goals & Timeline (premium)
            if (ref.watch(isPremiumProvider)) ...[
              const GoalsTimelineSection(),
              const SizedBox(height: 32),
            ],

            // Mastery by book section
            Text(
              'Mastery by Book',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            ..._buildMasteryByBook(context, ref, allScriptures),
            const SizedBox(height: 32),

            // Recent activity section
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            if (recentActivities.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No activity yet. Start practicing to see your progress!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                ),
              )
            else
              ...recentActivities.map(
                (activity) => ActivityTile(activity: activity),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMasteryByBook(
    BuildContext context,
    WidgetRef ref,
    List<Scripture> allScriptures,
  ) {
    return ScriptureBook.values.map((book) {
      final bookScriptures =
          allScriptures.where((s) => s.book == book).toList();

      // Count mastered scriptures in this book using holistic mastery
      int masteredCount = 0;
      int memorizedCount = 0;
      int familiarCount = 0;

      for (final scripture in bookScriptures) {
        final mastery = ref.watch(scriptureMasteryProvider(scripture.id));
        switch (mastery.level) {
          case MasteryLevel.eternal:
          case MasteryLevel.mastered:
            masteredCount++;
          case MasteryLevel.memorized:
            memorizedCount++;
          case MasteryLevel.familiar:
            familiarCount++;
          default:
            break;
        }
      }

      final total = bookScriptures.length;
      final progressPercent = total > 0 ? (masteredCount / total) * 100 : 0.0;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      book.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      '$masteredCount / $total mastered',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressPercent / 100,
                    minHeight: 6,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getColorForProgress(progressPercent),
                    ),
                  ),
                ),
                if (memorizedCount > 0 || familiarCount > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${memorizedCount > 0 ? '$memorizedCount memorized' : ''}${memorizedCount > 0 && familiarCount > 0 ? ', ' : ''}${familiarCount > 0 ? '$familiarCount familiar' : ''}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Color _getColorForProgress(double percentage) {
    if (percentage >= 85) return AppTheme.secondary;
    if (percentage >= 60) return AppTheme.primary;
    return AppTheme.accent;
  }
}
