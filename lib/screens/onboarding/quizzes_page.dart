import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class PracticeQuizzesPage extends StatelessWidget {
  const PracticeQuizzesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg, vertical: AppTheme.spacingLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hero icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.quiz,
              size: 48,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            'Practice Along\nthe Way',
            style: theme.textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Two supplementary quizzes help sharpen your recognition '
            'and comprehension — but Scripture Builder is where mastery is earned. '
            'Each round ends on the same score meter and word grade as Builder.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          const _QuizCard(
            icon: Icons.swap_horiz,
            color: AppTheme.secondary,
            title: 'Scripture Match',
            description:
                'Match key phrases to their references — then see your grade on the meter.',
          ),
          const SizedBox(height: AppTheme.spacingSm),
          const _QuizCard(
            icon: Icons.quiz,
            color: AppTheme.accent,
            title: 'Quick Quiz',
            description:
                'Multiple choice on passages and references — finish with a word grade.',
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            'Find them in the Practice tab — they\'re a great warm-up!',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingXl),
          // Subtle premium Sidekick mention
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.premiumGold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: AppTheme.premiumGold.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: AppTheme.premiumGold,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seminary Sidekick AI',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppTheme.premiumGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Unlock deeper understanding with AI-powered insights and personal reflection.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.7),
                        ),
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

class _QuizCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _QuizCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCard : Colors.white;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(description, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
