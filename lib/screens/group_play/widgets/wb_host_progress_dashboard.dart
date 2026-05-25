import 'package:flutter/material.dart';

import '../../../models/group_player.dart';
import '../../../models/group_wb_config.dart';
import '../../../models/group_wb_finish.dart';
import '../../../theme/app_theme.dart';

/// Host's view during a Word Builder race.
///
/// Round-by-Round: shows each player's status for the current scripture
/// (racing / finished — time + mistakes / DNF). When all live players have
/// finished, the parent screen's "Next Scripture" button lights up.
///
/// Set-of-N: shows each player's running progress through the set
/// ("Sarah: 7 of 10") plus a horizontal progress bar.
class WbHostProgressDashboard extends StatelessWidget {
  final GroupWbPlayMode mode;
  final List<GroupPlayer> players;
  final List<GroupWbFinish> finishes;

  /// Current scripture index — only used in Round-by-Round mode to filter
  /// finishes down to this round.
  final int currentScriptureIndex;

  /// Total scriptures in the set.
  final int totalScriptures;

  /// The host's own player id, so we can pin it to the bottom (or omit it).
  final String? hostPlayerId;

  const WbHostProgressDashboard({
    super.key,
    required this.mode,
    required this.players,
    required this.finishes,
    required this.currentScriptureIndex,
    required this.totalScriptures,
    this.hostPlayerId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Hosts watch the room rather than playing, so suppress the host row.
    final racers = players
        .where((p) => !p.isHost && p.id != hostPlayerId)
        .toList(growable: false);

    if (racers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Text(
            'No racers in the room yet.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          mode == GroupWbPlayMode.roundByRound
              ? 'ROUND ${currentScriptureIndex + 1} OF $totalScriptures'
              : 'CLASS PROGRESS',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        for (final p in racers)
          _Row(
            player: p,
            mode: mode,
            finishesForPlayer: finishes
                .where((f) => f.playerId == p.id)
                .toList(growable: false),
            currentScriptureIndex: currentScriptureIndex,
            totalScriptures: totalScriptures,
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final GroupPlayer player;
  final GroupWbPlayMode mode;
  final List<GroupWbFinish> finishesForPlayer;
  final int currentScriptureIndex;
  final int totalScriptures;

  const _Row({
    required this.player,
    required this.mode,
    required this.finishesForPlayer,
    required this.currentScriptureIndex,
    required this.totalScriptures,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.secondary.withValues(alpha: 0.15),
            child: const Icon(
              Icons.person,
              size: 16,
              color: AppTheme.secondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.nickname,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                _statusWidget(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusWidget(ThemeData theme) {
    if (mode == GroupWbPlayMode.roundByRound) {
      final round = finishesForPlayer.firstWhere(
        (f) => f.scriptureIndex == currentScriptureIndex,
        orElse: () => GroupWbFinish(
          id: '',
          roomId: '',
          playerId: '',
          scriptureIndex: -1,
          elapsedMs: 0,
          mistakeCount: 0,
          completedAt: DateTime.now(),
        ),
      );
      if (round.scriptureIndex == -1) {
        return Row(
          children: [
            const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 6),
            Text(
              'Racing…',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      }
      final sec = (round.elapsedMs / 1000).toStringAsFixed(1);
      final label = round.isDnf
          ? 'DNF'
          : '${sec}s · ${round.mistakeCount} ${round.mistakeCount == 1 ? "mistake" : "mistakes"}';
      return Row(
        children: [
          Icon(
            round.isDnf ? Icons.timer_off : Icons.check_circle,
            size: 14,
            color: round.isDnf ? AppTheme.error : AppTheme.success,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: round.isDnf ? AppTheme.error : AppTheme.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    // Set-of-N: count finishes for this player + progress bar
    final finishedCount = finishesForPlayer.length;
    final progress =
        totalScriptures == 0 ? 0.0 : finishedCount / totalScriptures;
    final isDone = finishedCount >= totalScriptures && totalScriptures > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isDone ? Icons.flag : Icons.timeline,
              size: 14,
              color: isDone
                  ? AppTheme.success
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              '$finishedCount of $totalScriptures',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDone
                    ? AppTheme.success
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 3,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDone ? AppTheme.success : AppTheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
