import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity.dart';
import '../models/enums.dart';
import '../models/scripture.dart';
import '../providers/activity_provider.dart';
import '../providers/goals_provider.dart';
import '../providers/scripture_provider.dart';
import '../providers/scripture_mastery_provider.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/progress_ring.dart';

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
            _StatsGrid(stats: stats),
            const SizedBox(height: 32),

            // Goals & Timeline (premium)
            if (ref.watch(isPremiumProvider)) ...[
              _GoalsTimelineSection(),
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
                (activity) => _ActivityTile(activity: activity),
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
      final progressPercent =
          total > 0 ? (masteredCount / total) * 100 : 0.0;

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
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    Text(
                      '$masteredCount / $total mastered',
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
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

class _StatsGrid extends StatelessWidget {
  final HolisticStats stats;

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
          value: stats.attempted.toString(),
          icon: Icons.note_outlined,
          color: AppTheme.primary,
        ),
        _StatTile(
          label: 'Memorized',
          value: stats.memorized.toString(),
          icon: Icons.check_circle_outline,
          color: AppTheme.secondary,
        ),
        _StatTile(
          label: 'Mastered',
          value: '${stats.mastered + stats.eternal}',
          icon: Icons.workspace_premium,
          color: Color(MasteryLevel.mastered.color),
        ),
        _StatTile(
          label: stats.eternal > 0 ? 'Eternal' : 'Need Review',
          value: stats.eternal > 0
              ? stats.eternal.toString()
              : stats.needsReview.toString(),
          icon: stats.eternal > 0 ? Icons.auto_awesome : Icons.schedule,
          color: stats.eternal > 0
              ? Color(MasteryLevel.eternal.color)
              : AppTheme.warning,
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

class _ActivityTile extends StatelessWidget {
  final Activity activity;

  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            children: [
              // Activity icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(_icon, color: _iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              // Activity details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activity.scriptureReference,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                    ),
                  ],
                ),
              ),
              // Timestamp
              Text(
                _formatTimestamp(activity.timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _icon {
    switch (activity.type) {
      case ActivityType.gameCompleted:
        return Icons.check_circle_outline;
      case ActivityType.masteryLevelUp:
        return Icons.trending_up;
      case ActivityType.streakMilestone:
        return Icons.local_fire_department;
      case ActivityType.firstAttempt:
        return Icons.flag_outlined;
      case ActivityType.perfectRun:
        return Icons.star;
    }
  }

  Color get _iconColor {
    switch (activity.type) {
      case ActivityType.gameCompleted:
        return AppTheme.secondary;
      case ActivityType.masteryLevelUp:
        return AppTheme.accent;
      case ActivityType.streakMilestone:
        return AppTheme.warning;
      case ActivityType.firstAttempt:
        return AppTheme.primary;
      case ActivityType.perfectRun:
        return AppTheme.gold;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.month}/${timestamp.day}';
  }
}

// ─── Premium: Goals & Timeline Section ────────────────────────────────────

class _GoalsTimelineSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGoals = ref.watch(activeGoalsProvider);
    final completedGoals = ref.watch(completedGoalsProvider);
    final projection = ref.watch(masteryProjectionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            const Icon(Icons.flag_outlined, color: AppTheme.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'Goals & Timeline',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Mastery projection
        if (projection != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(Icons.timeline,
                        color: AppTheme.accent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mastery Timeline',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: AppTheme.accent,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          projection,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (projection != null) const SizedBox(height: 12),

        // Active goals
        if (activeGoals.isNotEmpty) ...[
          Text(
            'Active Goals',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          ...activeGoals.map((goal) => _ProgressGoalTile(
                goal: goal,
                onComplete: () {
                  ref.read(goalsProvider.notifier).completeGoal(goal.id);
                },
              )),
          const SizedBox(height: 12),
        ],

        // Completed goals (most recent 5)
        if (completedGoals.isNotEmpty) ...[
          Text(
            'Completed',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 8),
          ...completedGoals.take(5).map((goal) => _CompletedGoalTile(goal: goal)),
        ],

        // Empty state
        if (activeGoals.isEmpty && completedGoals.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.flag_outlined,
                      color: AppTheme.premiumGold, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Your Sidekick will suggest goals based on your progress',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ProgressGoalTile extends StatelessWidget {
  final Goal goal;
  final VoidCallback onComplete;

  const _ProgressGoalTile({required this.goal, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              GestureDetector(
                onTap: onComplete,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: goal.isSidekickSuggestion
                          ? AppTheme.premiumGold
                          : AppTheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    if (goal.description.isNotEmpty)
                      Text(
                        goal.description,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (goal.isSidekickSuggestion)
                const Icon(Icons.auto_awesome,
                    size: 14, color: AppTheme.premiumGold),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletedGoalTile extends StatelessWidget {
  final Goal goal;

  const _CompletedGoalTile({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: AppTheme.success, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  goal.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
              ),
              if (goal.completedAt != null)
                Text(
                  _formatDate(goal.completedAt!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}';
  }
}
