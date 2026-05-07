import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// Compact "X of N answered" indicator with a progress bar.
///
/// Used on the host's projector view so the host can decide when to advance
/// the question. Players don't see this — they only need to know the local
/// "you / not-yet" state.
class AnswersReceivedIndicator extends StatelessWidget {
  final int answeredCount;
  final int totalPlayers;

  const AnswersReceivedIndicator({
    super.key,
    required this.answeredCount,
    required this.totalPlayers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = totalPlayers <= 0 ? 0.0 : answeredCount / totalPlayers;
    final isComplete = totalPlayers > 0 && answeredCount >= totalPlayers;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isComplete
              ? AppTheme.success.withValues(alpha: 0.4)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isComplete ? Icons.check_circle : Icons.people,
                size: 18,
                color: isComplete
                    ? AppTheme.success
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                isComplete
                    ? 'Everyone answered!'
                    : '$answeredCount of $totalPlayers answered',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isComplete
                      ? AppTheme.success
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor:
                  theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? AppTheme.success : AppTheme.tertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
