import 'package:flutter/material.dart';

import '../../../models/group_sb_finish.dart';
import '../../../theme/app_theme.dart';

/// Per-player finish summary: "✓ Finished — 8.2s, 1 mistake".
///
/// Reused by the player-side race screen (your own finish) and the host
/// progress dashboard (per-player rows once each one finishes).
class SbFinishBanner extends StatelessWidget {
  final int elapsedMs;
  final int mistakeCount;
  final bool isDnf;

  /// Optional rank in this round / set, e.g. "1st" / "3rd". Renders as a small
  /// leading badge when provided.
  final int? rankInRound;

  /// Optional label override (e.g. "You" vs nickname).
  final String? label;

  /// When true, render in the larger headline-style for the local player's
  /// own banner. When false, render compact for roster rows.
  final bool prominent;

  const SbFinishBanner({
    super.key,
    required this.elapsedMs,
    required this.mistakeCount,
    this.isDnf = false,
    this.rankInRound,
    this.label,
    this.prominent = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seconds = (elapsedMs / 1000).toStringAsFixed(1);
    final color = isDnf ? AppTheme.error : AppTheme.success;

    final detail = isDnf
        ? 'DNF'
        : (mistakeCount == 0
            ? '${seconds}s · clean'
            : '${seconds}s · $mistakeCount ${mistakeCount == 1 ? "mistake" : "mistakes"}');

    // Same thresholds as the solo Scripture Builder results screen.
    final stars = isDnf ? 0 : GroupSbFinish.starRatingFor(mistakeCount);

    final iconWidget = Icon(
      isDnf ? Icons.timer_off : Icons.check_circle,
      color: color,
      size: prominent ? 28 : 20,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: prominent ? 16 : 12,
        vertical: prominent ? 16 : 10,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          if (rankInRound != null) ...[
            _RankBadge(rank: rankInRound!, color: color),
            const SizedBox(width: 10),
          ],
          iconWidget,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label ?? (isDnf ? 'Timed out' : 'Finished'),
                  style: (prominent
                          ? theme.textTheme.titleLarge
                          : theme.textTheme.titleMedium)
                      ?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  detail,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (!isDnf)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final isFilled = index < stars;
                return Icon(
                  isFilled
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: prominent ? 24 : 16,
                  color: isFilled
                      ? AppTheme.gold
                      : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                );
              }),
            ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  final Color color;
  const _RankBadge({required this.rank, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '$rank',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
