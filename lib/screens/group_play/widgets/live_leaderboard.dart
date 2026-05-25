import 'package:flutter/material.dart';

import '../../../models/group_player.dart';
import '../../../theme/app_theme.dart';

/// Top-N leaderboard for the between-question screen.
///
/// `previousRanks` maps `playerId` → 1-based rank from the leaderboard
/// snapshot taken at the start of the question. The widget computes a delta
/// against the current rank and renders ▲N (moved up), ▼N (moved down), or
/// — (unchanged / new player).
class LiveLeaderboard extends StatelessWidget {
  final List<GroupPlayer> players;

  /// 1-based ranks captured before this question's points were applied.
  final Map<String, int> previousRanks;

  /// Highlight the row whose `id` matches.
  final String? localPlayerId;

  /// How many rows to render. Defaults to 5.
  final int maxRows;

  const LiveLeaderboard({
    super.key,
    required this.players,
    required this.previousRanks,
    this.localPlayerId,
    this.maxRows = 5,
  });

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) {
      return const SizedBox.shrink();
    }

    final visible = players.take(maxRows).toList();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'LEADERBOARD',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        for (var i = 0; i < visible.length; i++)
          _LeaderboardRow(
            rank: i + 1,
            player: visible[i],
            previousRank: previousRanks[visible[i].id],
            isMe: visible[i].id == localPlayerId,
          ),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final GroupPlayer player;
  final int? previousRank;
  final bool isMe;

  const _LeaderboardRow({
    required this.rank,
    required this.player,
    required this.previousRank,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final rowFill = isMe
        ? AppTheme.primary.withValues(alpha: 0.10)
        : (isDark
            ? AppTheme.darkSurfaceContainerHigh.withValues(alpha: 0.40)
            : AppTheme.surfaceContainer.withValues(alpha: 0.50));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: rowFill,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: isMe
            ? Border.all(
                color: AppTheme.primary.withValues(alpha: 0.4),
                width: 1,
              )
            : null,
      ),
      child: Row(
        children: [
          // Rank medallion (top 3 get gold/silver/bronze)
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _rankColor(rank).withValues(alpha: 0.18),
            ),
            child: Text(
              '$rank',
              style: theme.textTheme.labelLarge?.copyWith(
                color: _rankColor(rank),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              player.nickname + (isMe ? '  (you)' : ''),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Delta indicator
          _DeltaChip(currentRank: rank, previousRank: previousRank),
          const SizedBox(width: 12),
          // Score
          Text(
            '${player.score}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFD4A843); // gold
      case 2:
        return const Color(0xFFB0B0B0); // silver
      case 3:
        return const Color(0xFFC97A4A); // bronze
      default:
        return AppTheme.secondary;
    }
  }
}

class _DeltaChip extends StatelessWidget {
  final int currentRank;
  final int? previousRank;

  const _DeltaChip({required this.currentRank, required this.previousRank});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (previousRank == null) {
      return Text(
        '—',
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final delta = previousRank! - currentRank;
    if (delta == 0) {
      return Text(
        '—',
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final movedUp = delta > 0;
    final color = movedUp ? AppTheme.success : AppTheme.error;
    final icon = movedUp ? Icons.arrow_upward : Icons.arrow_downward;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          '${delta.abs()}',
          style: theme.textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
