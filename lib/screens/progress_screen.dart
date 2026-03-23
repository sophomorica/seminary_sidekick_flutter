import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/scripture.dart';
import '../providers/scripture_provider.dart';
import '../providers/progress_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/progress_ring.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(userStatsProvider);
    final allScriptures = ref.watch(scripturesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Progress'),
        elevation: 0,
        backgroundColor: AppTheme.surface,
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
                    value: stats.overallAccuracy / 100,
                    size: 200,
                    color: AppTheme.primary,
                    label: '${stats.overallAccuracy.toStringAsFixed(0)}%',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Overall Mastery',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Stats row
            _StatsGrid(stats: stats),
            const SizedBox(height: 32),

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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No activity yet. Start practicing to see your progress!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ),
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
      final bookScriptures = allScriptures.where((s) => s.book == book).toList();

      // Calculate book mastery percentage
      double totalAccuracy = 0;
      int count = 0;

      for (final scripture in bookScriptures) {
        for (final gameType in GameType.values) {
          final progress = ref.watch(
            progressByScriptureProvider((scripture.id, gameType)),
          );
          if (progress != null && progress.totalAttempts > 0) {
            totalAccuracy += progress.accuracy;
            count++;
          }
        }
      }

      final masteryPercent =
          count > 0 ? totalAccuracy / count : 0.0;

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
                      '${masteryPercent.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                    value: masteryPercent / 100,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getColorForProgress(masteryPercent),
                    ),
                  ),
                ),
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
    return Colors.orange;
  }
}

class _StatsGrid extends StatelessWidget {
  final UserStats stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _StatTile(
          label: 'Attempted',
          value: stats.totalAttempted.toString(),
          icon: Icons.note_outlined,
          color: Colors.blue,
        ),
        _StatTile(
          label: 'Memorized',
          value: stats.totalMemorized.toString(),
          icon: Icons.check_circle_outline,
          color: AppTheme.secondary,
        ),
        _StatTile(
          label: 'Mastered',
          value: stats.totalMastered.toString(),
          icon: Icons.star_outline,
          color: AppTheme.gold,
        ),
        _StatTile(
          label: 'Need Review',
          value: stats.needsReview.toString(),
          icon: Icons.refresh,
          color: AppTheme.primary,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
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
