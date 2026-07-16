import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../navigation/fullscreen.dart';
import '../../models/enums.dart';
import '../../models/scripture.dart';
import '../../models/scripture_mastery.dart';
import '../../providers/scripture_mastery_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/mastery_badge.dart';
import '../../widgets/premium_teaser.dart';
import '../games/scripture_builder/scripture_builder_screen.dart';

/// Displays the mastery level with a clear linear path driven by Scripture Builder
/// progression, a prominent CTA to launch Scripture Builder, and a checklist of
/// requirements for the next level.
class HolisticMasterySection extends ConsumerWidget {
  final String scriptureId;
  final Scripture scripture;

  const HolisticMasterySection({
    super.key,
    required this.scriptureId,
    required this.scripture,
  });

  /// Determine the next Scripture Builder difficulty to launch based on current mastery.
  DifficultyLevel _nextSbDifficulty(ScriptureMastery mastery) {
    final sbDifficulty = mastery.highestDifficultyPerGame[GameType.scriptureBuilder];
    if (sbDifficulty == null) return DifficultyLevel.beginner;
    switch (sbDifficulty) {
      case DifficultyLevel.beginner:
        return DifficultyLevel.intermediate;
      case DifficultyLevel.intermediate:
        return DifficultyLevel.advanced;
      case DifficultyLevel.advanced:
        return DifficultyLevel.master;
      case DifficultyLevel.master:
        return DifficultyLevel.master; // Keep practicing Master
    }
  }

  /// Get a user-facing label for the CTA button.
  String _ctaLabel(ScriptureMastery mastery) {
    if (mastery.level == MasteryLevel.newScripture) {
      return 'Start Mastery';
    }
    if (mastery.level == MasteryLevel.mastered ||
        mastery.level == MasteryLevel.eternal) {
      return 'Practice Master';
    }
    if (mastery.needsReview) {
      return 'Review Now';
    }
    return 'Continue Journey';
  }

  /// Get a subtitle describing what the CTA does.
  String _ctaSubtitle(
      ScriptureMastery mastery, DifficultyLevel nextDifficulty) {
    return 'Scripture Builder — ${nextDifficulty.descriptionForGame(GameType.scriptureBuilder)}';
  }

  void _launchScriptureBuilder(BuildContext context, DifficultyLevel difficulty) {
    pushFullscreen(
      context,
      ScriptureBuilderScreen(
        difficulty: difficulty,
        scriptures: [scripture],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mastery = ref.watch(scriptureMasteryProvider(scriptureId));
    final nextDifficulty = _nextSbDifficulty(mastery);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mastery Path',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),

        // Main mastery card with badge + stats
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MasteryBadge.withProgress(
                            masteryLevel: mastery.level,
                            subProgress: mastery.subProgress,
                            needsReview: mastery.needsReview,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mastery.level.description,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${mastery.overallAccuracy.toStringAsFixed(0)}%',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Color(mastery.level.color),
                              ),
                        ),
                        Text(
                          'accuracy',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${mastery.totalAttemptsAllGames} attempts',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Needs review banner
                if (mastery.needsReview) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule,
                            size: 16, color: AppTheme.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Last practiced ${mastery.daysSinceLastPractice} days ago — review to maintain mastery',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppTheme.warning),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // ── Prominent CTA: Launch Scripture Builder ──
        const SizedBox(height: AppTheme.spacingMd),
        SizedBox(
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: ElevatedButton(
            onPressed: () => _launchScriptureBuilder(context, nextDifficulty),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: AppTheme.onPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingLg,
                vertical: AppTheme.spacingMd,
              ),
              alignment: Alignment.center,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sort_by_alpha, size: 22),
                    const SizedBox(width: AppTheme.spacingSm),
                    Flexible(
                      child: Text(
                        _ctaLabel(mastery),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  _ctaSubtitle(mastery, nextDifficulty),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onPrimary.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w400,
                      ),
                ),
              ],
            ),
            ),
          ),
        ),

        // ── Scripture Builder Journey timeline (tappable steps) ──
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scripture Builder Journey',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap any step to practice at that difficulty',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                MasteryPathStep(
                  level: MasteryLevel.learning,
                  label: 'Beginner',
                  description: 'Tap 3-word chunks',
                  currentLevel: mastery.level,
                  wasSkipped:
                      mastery.wasDifficultySkipped(DifficultyLevel.beginner),
                  onTap: () =>
                      _launchScriptureBuilder(context, DifficultyLevel.beginner),
                ),
                MasteryPathStep(
                  level: MasteryLevel.familiar,
                  label: 'Intermediate',
                  description: 'Tap 2-word chunks + distractors',
                  currentLevel: mastery.level,
                  wasSkipped: mastery
                      .wasDifficultySkipped(DifficultyLevel.intermediate),
                  onTap: () =>
                      _launchScriptureBuilder(context, DifficultyLevel.intermediate),
                ),
                MasteryPathStep(
                  level: MasteryLevel.memorized,
                  label: 'Advanced',
                  description: 'Typed with first-letter hints',
                  currentLevel: mastery.level,
                  wasSkipped:
                      mastery.wasDifficultySkipped(DifficultyLevel.advanced),
                  onTap: () =>
                      _launchScriptureBuilder(context, DifficultyLevel.advanced),
                ),
                MasteryPathStep(
                  level: MasteryLevel.mastered,
                  label: 'Master',
                  description:
                      '3 perfect runs (${mastery.consecutivePerfectMaster}/3)',
                  currentLevel: mastery.level,
                  isLast: mastery.level != MasteryLevel.mastered &&
                      mastery.level != MasteryLevel.eternal,
                  onTap: () =>
                      _launchScriptureBuilder(context, DifficultyLevel.master),
                ),
                if (mastery.level == MasteryLevel.mastered ||
                    mastery.level == MasteryLevel.eternal)
                  MasteryPathStep(
                    level: MasteryLevel.eternal,
                    label: 'Eternal',
                    description: mastery.daysMastered != null
                        ? '${mastery.daysMastered}/183 days sustained'
                        : '6 months sustained mastery',
                    currentLevel: mastery.level,
                    isLast: true,
                  ),
              ],
            ),
          ),
        ),

        // Requirements checklist for next level
        if (mastery.nextLevelRequirements.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mastery.level == MasteryLevel.mastered &&
                            mastery.needsReview
                        ? 'Maintain Mastery'
                        : 'Next Step',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...mastery.nextLevelRequirements.map((req) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            req.isMet
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            size: 20,
                            color: req.isMet
                                ? AppTheme.success
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.3),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              req.description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: req.isMet
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5)
                                        : null,
                                    decoration: req.isMet
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                            ),
                          ),
                          if (!req.isMet && req.progress > 0)
                            Text(
                              '${(req.progress * 100).toInt()}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppTheme.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],

        // Premium teaser — shown after reaching memorized+ level
        if (!ref.watch(isPremiumProvider) &&
            ref.watch(canShowUpgradePromptProvider) &&
            (mastery.level.index >= MasteryLevel.memorized.index))
          const PremiumTeaser(
            headline: 'You\'re memorizing it — now understand it',
            body:
                'Your Seminary Sidekick helps you find meaning, apply principles, and journal your insights.',
            icon: Icons.psychology,
          ),

        // Per-game difficulty progress (supplementary — only show quiz/matching)
        if (mastery.gameTypesAttempted > 0) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Practice Tools',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scripture Match and Quiz help build recognition',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...GameType.values
                      .where((gt) => gt != GameType.scriptureBuilder)
                      .map((gameType) {
                    final difficulty =
                        mastery.highestDifficultyPerGame[gameType];
                    final hasPlayed = difficulty != null;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            gameType.icon,
                            size: 18,
                            color: hasPlayed
                                ? AppTheme.secondary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.3),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              gameType.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: hasPlayed
                                        ? null
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.4),
                                  ),
                            ),
                          ),
                          Text(
                            hasPlayed ? difficulty.label : 'Not started',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: hasPlayed
                                      ? AppTheme.secondary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.3),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A single step on the linear mastery path visualization.
/// Tappable to launch Scripture Builder at the corresponding difficulty.
class MasteryPathStep extends StatelessWidget {
  final MasteryLevel level;
  final String label;
  final String description;
  final MasteryLevel currentLevel;
  final bool isLast;
  final bool wasSkipped;
  final VoidCallback? onTap;

  const MasteryPathStep({
    super.key,
    required this.level,
    required this.label,
    required this.description,
    required this.currentLevel,
    this.isLast = false,
    this.wasSkipped = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = currentLevel.index >= level.index;
    final isCurrent = currentLevel.index == level.index - 1;
    final color = Color(level.color);
    final dimColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertical timeline
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isCompleted ? color : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          isCompleted ? color : (isCurrent ? color : dimColor),
                      width: isCurrent ? 2.5 : 1.5,
                    ),
                  ),
                  child: isCompleted
                      ? Icon(
                          wasSkipped ? Icons.bolt : Icons.check,
                          size: 12,
                          color: Colors.white,
                        )
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 28,
                    color: isCompleted ? color : dimColor,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Label + description
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: (isCompleted || isCurrent)
                                        ? FontWeight.w600
                                        : null,
                                    color: isCompleted
                                        ? color
                                        : (isCurrent
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.4)),
                                  ),
                        ),
                      ),
                      if (onTap != null)
                        Icon(
                          Icons.play_circle_outline,
                          size: 18,
                          color: isCompleted
                              ? color.withValues(alpha: 0.6)
                              : (isCurrent
                                  ? color
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.25)),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          description,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(
                                            alpha: isCompleted || isCurrent
                                                ? 0.6
                                                : 0.3),
                                  ),
                        ),
                      ),
                      if (wasSkipped && isCompleted)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt, size: 10, color: color),
                              const SizedBox(width: 2),
                              Text(
                                'Skipped',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      fontSize: 9,
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
