import 'package:flutter/material.dart';

import '../models/enums.dart';

/// Displays a mastery level badge in various sizes.
///
/// - [MasteryBadge.compact]: Small colored dot (for list items).
/// - [MasteryBadge.expanded]: Dot + label chip (for detail views).
/// - [MasteryBadge.withProgress]: Dot + label + sub-progress bar (for detail views).
class MasteryBadge extends StatelessWidget {
  final MasteryLevel masteryLevel;
  final bool expanded;
  final bool showProgress;
  final double subProgress;
  final bool needsReview;

  /// Compact version showing just a dot.
  const MasteryBadge.compact({
    super.key,
    required this.masteryLevel,
    this.needsReview = false,
  })  : expanded = false,
        showProgress = false,
        subProgress = 0.0;

  /// Expanded version showing dot and label.
  const MasteryBadge.expanded({
    super.key,
    required this.masteryLevel,
    this.needsReview = false,
  })  : expanded = true,
        showProgress = false,
        subProgress = 0.0;

  /// Full version with dot, label, and sub-progress bar.
  const MasteryBadge.withProgress({
    super.key,
    required this.masteryLevel,
    required this.subProgress,
    this.needsReview = false,
  })  : expanded = true,
        showProgress = true;

  @override
  Widget build(BuildContext context) {
    final color = Color(masteryLevel.color);
    // Dim when needs review
    final displayColor = needsReview ? color.withValues(alpha: 0.5) : color;

    if (!expanded) {
      // Compact: colored dot with optional clock overlay
      return Tooltip(
        message: needsReview
            ? '${masteryLevel.label} — needs review'
            : masteryLevel.label,
        child: SizedBox(
          width: 16,
          height: 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: displayColor,
                  shape: BoxShape.circle,
                ),
              ),
              if (needsReview)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.schedule,
                      size: 7,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Expanded / withProgress
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: displayColor.withValues(alpha: 0.1),
            border: Border.all(color: displayColor, width: 1.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                masteryLevel.icon,
                size: 14,
                color: displayColor,
              ),
              const SizedBox(width: 6),
              Text(
                masteryLevel.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: displayColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (needsReview) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.schedule,
                  size: 12,
                  color: displayColor,
                ),
              ],
            ],
          ),
        ),
        if (showProgress && masteryLevel != MasteryLevel.eternal) ...[
          const SizedBox(height: 8),
          _SubProgressBar(
            progress: subProgress,
            color: _nextLevelColor(masteryLevel),
          ),
        ],
      ],
    );
  }

  /// Color of the NEXT level for the sub-progress bar.
  Color _nextLevelColor(MasteryLevel current) {
    switch (current) {
      case MasteryLevel.newScripture:
        return Color(MasteryLevel.learning.color);
      case MasteryLevel.learning:
        return Color(MasteryLevel.familiar.color);
      case MasteryLevel.familiar:
        return Color(MasteryLevel.memorized.color);
      case MasteryLevel.memorized:
        return Color(MasteryLevel.mastered.color);
      case MasteryLevel.mastered:
        return Color(MasteryLevel.eternal.color);
      case MasteryLevel.eternal:
        return Color(MasteryLevel.eternal.color);
    }
  }
}

/// A thin animated progress bar showing progress toward the next mastery level.
class _SubProgressBar extends StatelessWidget {
  final double progress;
  final Color color;

  const _SubProgressBar({
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 6,
            width: 120,
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${(progress * 100).toInt()}% to next level',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
                fontSize: 10,
              ),
        ),
      ],
    );
  }
}
