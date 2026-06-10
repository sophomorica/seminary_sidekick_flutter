import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../models/group_answer.dart';
import '../../../models/group_question.dart';
import '../../../theme/app_theme.dart';

/// "How the class answered" bars for the between-question standings view —
/// the Kahoot reveal moment. One row per choice: bar width animates in
/// proportionally to vote share, the correct choice fills success-green with
/// a check, the rest stay muted.
///
/// Shown to everyone (host and players) once the question closes. Renders a
/// quiet "No answers yet" row set when nobody answered, so a slow round
/// still looks intentional.
class AnswerDistribution extends StatelessWidget {
  final GroupQuestion question;

  /// Answers submitted for this question only (pre-filtered by the caller).
  final List<GroupAnswer> answers;

  const AnswerDistribution({
    super.key,
    required this.question,
    required this.answers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final counts = List<int>.filled(question.options.length, 0);
    for (final a in answers) {
      if (a.selectedChoice >= 0 && a.selectedChoice < counts.length) {
        counts[a.selectedChoice]++;
      }
    }
    final total = counts.fold<int>(0, (sum, c) => sum + c);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'HOW THE CLASS ANSWERED',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        for (var i = 0; i < question.options.length; i++)
          _ChoiceBar(
            label: question.options[i],
            count: counts[i],
            fraction: total == 0 ? 0.0 : counts[i] / total,
            isCorrect: i == question.correctIndex,
            index: i,
          ),
      ],
    );
  }
}

class _ChoiceBar extends StatelessWidget {
  final String label;
  final int count;
  final double fraction;
  final bool isCorrect;
  final int index;

  const _ChoiceBar({
    required this.label,
    required this.count,
    required this.fraction,
    required this.isCorrect,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final fillColor = isCorrect
        ? AppTheme.success.withValues(alpha: isDark ? 0.40 : 0.28)
        : theme.colorScheme.onSurfaceVariant
            .withValues(alpha: isDark ? 0.22 : 0.14);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      height: 40,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Stack(
          children: [
            // Track
            Positioned.fill(
              child: Container(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.45),
              ),
            ),
            // Animated fill — eases out to its vote share.
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value.clamp(0.0, 1.0),
                  child: Container(color: fillColor),
                ),
              ),
            ),
            // Label + count overlay
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    if (isCorrect) ...[
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppTheme.success,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isCorrect ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$count',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isCorrect
                            ? AppTheme.success
                            : theme.colorScheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 250.ms, delay: (90 * index).ms)
        .slideX(begin: -0.04, curve: Curves.easeOut);
  }
}
