import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/enums.dart';
import '../providers/goals_provider.dart';
import '../providers/scripture_provider.dart';
import '../providers/scripture_mastery_provider.dart';
import '../providers/spaced_repetition_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../providers/sidekick_provider.dart';
import '../widgets/premium_teaser.dart';
import '../widgets/scripture_card.dart';
import 'journal_screen.dart';
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

            const SizedBox(height: 20),

            // Premium teaser — shown after user has made progress
            if (ref.watch(canShowUpgradePromptProvider) &&
                (stats.mastered + stats.memorized) > 0)
              const PremiumTeaser(
                headline: 'Go deeper with your Sidekick',
                body:
                    'Get AI-powered insights, reflection prompts, and personalized goals for every scripture you study.',
                icon: Icons.auto_awesome,
              ),

            // Gentle reminder from Sidekick (premium)
            if (ref.watch(isPremiumProvider)) ...[
              _ReminderBanner(),
              _SuggestedGoalCard(),
              _ActiveGoalsSection(),
              _TimelineInsightCard(),
              _ReflectNowCard(),
            ],

            // "Got a minute?" quick session prompts (premium engagement)
            if (ref.watch(isPremiumProvider))
              _QuickSessionsSection(),

            // Nearly mastered nudges — available to all users
            _NearlyMasteredNudges(),

            const SizedBox(height: 12),

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

// ─── Premium: Gentle Reminder Banner ──────────────────────────────────────

class _ReminderBanner extends ConsumerWidget {
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
        color: AppTheme.premiumGoldLight.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              const Icon(Icons.notifications_none,
                  color: AppTheme.premiumGold, size: 22),
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

class _SuggestedGoalCard extends ConsumerWidget {
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
          side: const BorderSide(color: AppTheme.premiumGold, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: AppTheme.premiumGold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Your Sidekick suggests',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.premiumGold,
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

class _ActiveGoalsSection extends ConsumerWidget {
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
              const Icon(Icons.flag_outlined,
                  color: AppTheme.primary, size: 20),
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
                        ? AppTheme.premiumGold
                        : AppTheme.primary,
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.check, size: 16, color: Colors.transparent),
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
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.auto_awesome,
                    size: 14, color: AppTheme.premiumGold),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Premium: Timeline Insight Card ───────────────────────────────────────

class _TimelineInsightCard extends ConsumerWidget {
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

class _ReflectNowCard extends ConsumerWidget {
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
            color: AppTheme.premiumGold.withValues(alpha: 0.3),
          ),
        ),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => JournalScreen(initialPrompt: prompt),
              ),
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
                    color: AppTheme.premiumGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(Icons.edit_note,
                      color: AppTheme.premiumGold, size: 20),
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
                                  color: AppTheme.premiumGold,
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
                const Icon(Icons.arrow_forward_ios,
                    size: 14, color: AppTheme.premiumGold),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Engagement: "Got a Minute?" Quick Sessions (TASK-040) ───────────────────

class _QuickSessionsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prompts = ref.watch(quickSessionPromptsProvider);
    if (prompts.isEmpty) return const SizedBox.shrink();

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
              const Icon(Icons.bolt, color: AppTheme.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Got a minute?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...prompts.take(3).map((prompt) => _QuickSessionTile(prompt: prompt)),
        ],
      ),
    );
  }
}

class _QuickSessionTile extends ConsumerWidget {
  final QuickSessionPrompt prompt;

  const _QuickSessionTile({required this.prompt});

  IconData _iconForAction(String actionType) {
    switch (actionType) {
      case 'wordBuilder':
        return Icons.sort_by_alpha;
      case 'review':
        return Icons.refresh;
      case 'reflect':
        return Icons.edit_note;
      case 'quiz':
        return Icons.quiz;
      default:
        return Icons.play_arrow;
    }
  }

  Color _colorForAction(String actionType) {
    switch (actionType) {
      case 'wordBuilder':
        return AppTheme.primary;
      case 'review':
        return AppTheme.warning;
      case 'reflect':
        return AppTheme.premiumGold;
      case 'quiz':
        return AppTheme.secondary;
      default:
        return AppTheme.accent;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _colorForAction(prompt.actionType);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () {
          if (prompt.actionType == 'reflect') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => JournalScreen(initialPrompt: prompt.subtitle),
              ),
            );
          } else if (prompt.scriptureId != null) {
            context.push('/scripture/${prompt.scriptureId}');
          }
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  _iconForAction(prompt.actionType),
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prompt.title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      prompt.subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: color.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Engagement: Nearly Mastered Nudges (TASK-040) ───────────────────────────

class _NearlyMasteredNudges extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearlyMastered = ref.watch(nearlyMasteredScripturesProvider);
    if (nearlyMastered.isEmpty) return const SizedBox.shrink();

    // Show up to 2 nudge cards
    final toShow = nearlyMastered.take(2).toList();

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
              const Icon(Icons.trending_up, color: AppTheme.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Almost there',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...toShow.map((info) => _NearlyMasteredTile(info: info)),
        ],
      ),
    );
  }
}

class _NearlyMasteredTile extends StatelessWidget {
  final NearlyMasteredInfo info;

  const _NearlyMasteredTile({required this.info});

  @override
  Widget build(BuildContext context) {
    final color = Color(info.level.color);
    final progressPct = (info.subProgress * 100).toInt();

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () {
          context.push('/scripture/${info.id}');
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Progress ring
              SizedBox(
                width: 36,
                height: 36,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: info.subProgress,
                      strokeWidth: 3,
                      backgroundColor: color.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                    Icon(info.level.icon, size: 16, color: color),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.reference,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$progressPct% to ${_nextLevelLabel(info.level)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: color,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: color.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  String _nextLevelLabel(MasteryLevel level) {
    switch (level) {
      case MasteryLevel.newScripture:
        return 'Learning';
      case MasteryLevel.learning:
        return 'Familiar';
      case MasteryLevel.familiar:
        return 'Memorized';
      case MasteryLevel.memorized:
        return 'Mastered';
      case MasteryLevel.mastered:
        return 'Eternal';
      case MasteryLevel.eternal:
        return 'Eternal';
    }
  }
}
