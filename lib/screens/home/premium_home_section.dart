import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../navigation/fullscreen.dart';
import '../../providers/goals_provider.dart';
import '../../providers/sidekick_provider.dart';
import '../../theme/app_theme.dart';
import '../journal/journal_screen.dart';

// ─── Premium: Gentle Reminder Banner ──────────────────────────────────────

class ReminderBanner extends ConsumerWidget {
  const ReminderBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminder = ref.watch(activeReminderProvider);
    if (reminder == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Card(
        color: AppTheme.sidekickTint(context, 0.15),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(Icons.notifications_none,
                  color: AppTheme.sidekickColor(context), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  reminder,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  ref.read(goalsProvider.notifier).dismissReminder();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Premium: Suggested Goal Card ─────────────────────────────────────────

class SuggestedGoalCard extends ConsumerWidget {
  const SuggestedGoalCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestion = ref.watch(pendingSuggestionProvider);
    if (suggestion == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: BorderSide(color: AppTheme.sidekickColor(context), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome,
                      color: AppTheme.sidekickColor(context), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Your Sidekick suggests',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.sidekickColor(context),
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                suggestion.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (suggestion.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  suggestion.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      ref.read(goalsProvider.notifier).dismissSuggestion();
                    },
                    child: const Text('Not now'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(goalsProvider.notifier).acceptSuggestion();
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Accept goal'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Premium: Active Goals Section ────────────────────────────────────────

class ActiveGoalsSection extends ConsumerWidget {
  const ActiveGoalsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGoals = ref.watch(activeGoalsProvider);
    if (activeGoals.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined,
                  color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Your Goals',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...activeGoals.take(3).map((goal) => _GoalTile(goal: goal)),
          if (activeGoals.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${activeGoals.length - 3} more goals',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.accent,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GoalTile extends ConsumerWidget {
  final Goal goal;

  const _GoalTile({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Checkmark circle
            GestureDetector(
              onTap: () {
                ref.read(goalsProvider.notifier).completeGoal(goal.id);
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: goal.isSidekickSuggestion
                        ? AppTheme.sidekickColor(context)
                        : Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.check,
                    size: 16, color: Colors.transparent),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (goal.isSidekickSuggestion)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.auto_awesome,
                    size: 14, color: AppTheme.sidekickColor(context)),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Premium: Timeline Insight Card ───────────────────────────────────────

class TimelineInsightCard extends ConsumerWidget {
  const TimelineInsightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projection = ref.watch(masteryProjectionProvider);
    if (projection == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(Icons.timeline,
                    color: AppTheme.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  projection,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Premium: Reflect Now Card ──────────────────────────────────────────────

class ReflectNowCard extends ConsumerWidget {
  const ReflectNowCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prompts = ref.watch(reflectionPromptsProvider);
    if (prompts.isEmpty) return const SizedBox.shrink();

    // Show the first prompt as a quick "Reflect Now" action
    final prompt = prompts.first;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: BorderSide(
            color: AppTheme.sidekickColor(context).withValues(alpha: 0.3),
          ),
        ),
        child: InkWell(
          onTap: () {
            pushFullscreen(
              context,
              JournalScreen(initialPrompt: prompt),
            );
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.sidekickTint(context),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(Icons.edit_note,
                      color: AppTheme.sidekickColor(context), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reflect Now',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.sidekickColor(context),
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        prompt,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios,
                    size: 14, color: AppTheme.sidekickColor(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
