import 'package:flutter/material.dart';

import '../../../models/group_player.dart';
import '../../../theme/app_theme.dart';

/// Three-column podium for the top finishers.
///
/// Layout: 2nd on the left (medium block), 1st in the middle (tallest, crown),
/// 3rd on the right (shortest). Missing positions render as empty placeholders
/// so a 1- or 2-player game still looks intentional.
class PodiumView extends StatelessWidget {
  final List<GroupPlayer> topThree;
  final String? myUserId;

  const PodiumView({
    super.key,
    required this.topThree,
    required this.myUserId,
  });

  GroupPlayer? _at(int rank) =>
      rank <= topThree.length ? topThree[rank - 1] : null;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _PodiumColumn(
              rank: 2,
              player: _at(2),
              myUserId: myUserId,
              height: 120,
              color: AppTheme.secondary,
              onColor: AppTheme.onSecondary,
            ),
          ),
          Expanded(
            child: _PodiumColumn(
              rank: 1,
              player: _at(1),
              myUserId: myUserId,
              height: 170,
              color: AppTheme.tertiary,
              onColor: AppTheme.onTertiary,
            ),
          ),
          Expanded(
            child: _PodiumColumn(
              rank: 3,
              player: _at(3),
              myUserId: myUserId,
              height: 90,
              color: AppTheme.primary,
              onColor: AppTheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final int rank;
  final GroupPlayer? player;
  final String? myUserId;
  final double height;
  final Color color;
  final Color onColor;

  const _PodiumColumn({
    required this.rank,
    required this.player,
    required this.myUserId,
    required this.height,
    required this.color,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMe = player != null && player!.userId == myUserId;
    final medal = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      _ => '🥉',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (rank == 1)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(
                Icons.emoji_events,
                color: AppTheme.gold,
                size: 32,
              ),
            ),
          if (player != null) ...[
            CircleAvatar(
              radius: rank == 1 ? 28 : 22,
              backgroundColor: color.withValues(alpha: 0.18),
              child: Text(
                medal,
                style: TextStyle(fontSize: rank == 1 ? 28 : 22),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              player!.nickname + (isMe ? ' (you)' : ''),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${player!.score}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '—',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: player == null ? color.withValues(alpha: 0.15) : color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusMd),
              ),
              boxShadow: player != null ? AppTheme.editorialShadow : null,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: player == null
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                      : onColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
