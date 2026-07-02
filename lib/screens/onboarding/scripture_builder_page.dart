import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../theme/app_theme.dart';

class ScriptureBuilderPage extends StatelessWidget {
  const ScriptureBuilderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hero icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sort_by_alpha,
              size: 48,
              color: AppTheme.secondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            'Scripture Builder',
            style: theme.textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Your path to mastery',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          // 4 tiers visual
          _TierRow(
            color: Color(MasteryLevel.learning.color),
            icon: Icons.touch_app,
            tier: 'Beginner',
            detail: 'Tap 3-word chunks in order',
            earns: 'Learning',
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _TierRow(
            color: Color(MasteryLevel.familiar.color),
            icon: Icons.shuffle,
            tier: 'Intermediate',
            detail: 'Smaller chunks + distractors',
            earns: 'Familiar',
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _TierRow(
            color: Color(MasteryLevel.memorized.color),
            icon: Icons.keyboard,
            tier: 'Advanced',
            detail: 'Type it — first-letter hints',
            earns: 'Memorized',
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _TierRow(
            color: Color(MasteryLevel.mastered.color),
            icon: Icons.visibility_off,
            tier: 'Master',
            detail: 'Type blind — one mistake resets all',
            earns: 'Mastered',
          ),
        ],
      ),
    );
  }
}

class _TierRow extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String tier;
  final String detail;
  final String earns;

  const _TierRow({
    required this.color,
    required this.icon,
    required this.tier,
    required this.detail,
    required this.earns,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCard : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm + 2,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tier,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(detail, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusRound),
            ),
            child: Text(
              earns,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
