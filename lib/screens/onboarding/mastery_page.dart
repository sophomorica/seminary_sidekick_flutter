import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../services/score_story_engine.dart';
import '../../theme/app_theme.dart';

class MasteredPage extends StatelessWidget {
  const MasteredPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final masteredColor = Color(MasteryLevel.mastered.color);
    final eternalColor = Color(MasteryLevel.eternal.color);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingMd,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Trophy icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: masteredColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.workspace_premium,
              size: 48,
              color: masteredColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            'Prove You Know It',
            style: theme.textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
              ),
              children: [
                const TextSpan(
                  text:
                      'Complete all four Scripture Builder tiers to reach Memorized. '
                      'Then prove it with ',
                ),
                TextSpan(
                  text: '3 consecutive perfect runs',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: masteredColor,
                  ),
                ),
                const TextSpan(text: ' at Master difficulty to earn '),
                TextSpan(
                  text: 'Mastered',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: masteredColor,
                  ),
                ),
                const TextSpan(text: ' status.'),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          // Visual: three perfect-run pips (not results stars)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 40,
                  color: masteredColor,
                ),
              );
            }),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            '3 perfect Master runs = Mastered',
            style: theme.textTheme.titleMedium?.copyWith(
              color: masteredColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),
          // Results meter + word grades
          _InfoCard(
            icon: Icons.speed,
            iconColor: AppTheme.success,
            title: 'Your score meter',
            body:
                'After Scripture Builder, Match, or Quick Quiz, a score meter '
                'grades the round — '
                '${ScoreGrade.masterful.label}, ${ScoreGrade.strong.label}, '
                '${ScoreGrade.gettingThere.label}, or '
                '${ScoreGrade.keepPracticing.label}.',
          ),
          const SizedBox(height: AppTheme.spacingMd),
          // Avatar journey
          _InfoCard(
            icon: AvatarStage.quickToObserve.icon,
            iconColor: theme.colorScheme.primary,
            title: 'Your mastery avatar',
            body:
                'As you Master more scriptures, your avatar grows along the journey:',
            child: Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingSm),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: AvatarStage.values.map((stage) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          stage.icon,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 72,
                        child: Text(
                          stage.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),
          // Eternal mention
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: eternalColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: eternalColor.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: eternalColor, size: 28),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Eternal',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: eternalColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Stay Mastered for 6 months and it becomes permanent — '
                        'engraven upon your heart.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final Widget? child;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCard : theme.colorScheme.surface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}
