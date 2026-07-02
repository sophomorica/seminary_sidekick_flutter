import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/goals_provider.dart';
import '../../theme/app_theme.dart';

class GoalsTimelineSection extends ConsumerWidget {
  const GoalsTimelineSection({super.key});

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
            Icon(Icons.flag_outlined,
                color: Theme.of(context).colorScheme.primary, size: 22),
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
          ...completedGoals
              .take(5)
              .map((goal) => _CompletedGoalTile(goal: goal)),
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
                          : Theme.of(context).colorScheme.primary,
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
