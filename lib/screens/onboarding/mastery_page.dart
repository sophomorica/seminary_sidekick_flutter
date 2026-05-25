import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../theme/app_theme.dart';

class MasteredPage extends StatelessWidget {
  const MasteredPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final masteredColor = Color(MasteryLevel.mastered.color);
    final eternalColor = Color(MasteryLevel.eternal.color);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
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
          // Visual: 3 stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.star_rounded,
                  size: 44,
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
