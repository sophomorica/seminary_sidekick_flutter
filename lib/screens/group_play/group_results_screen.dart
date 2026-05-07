import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/group_answer.dart';
import '../../models/group_play_state.dart';
import '../../models/group_player.dart';
import '../../providers/group_play_provider.dart';
import '../../theme/app_theme.dart';
import 'widgets/podium_view.dart';

/// Final results screen for a group play session.
///
/// Shows a top-3 podium with confetti, the full leaderboard with per-player
/// stats, a share button, and host actions ("Play Again" / "End Room"). Players
/// see a single "Done" action.
class GroupResultsScreen extends ConsumerStatefulWidget {
  final String code;

  const GroupResultsScreen({super.key, required this.code});

  @override
  ConsumerState<GroupResultsScreen> createState() => _GroupResultsScreenState();
}

class _GroupResultsScreenState extends ConsumerState<GroupResultsScreen> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If a fresh room is created (Play Again), the phase flips back to lobby —
    // hop over to the host lobby so we don't strand the user on results.
    ref.listen<GroupPlayPhase>(groupPlayPhaseProvider, (prev, next) {
      if (next == GroupPlayPhase.inLobby && mounted) {
        context.go('/group-play/host');
      }
    });

    final state = ref.watch(groupPlayProvider);
    final leaderboard = ref.watch(groupPlayLeaderboardProvider);
    final isHost = ref.watch(isGroupHostProvider);
    final myUserId = ref.read(groupPlayServiceProvider).currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingLg,
                      vertical: AppTheme.spacingMd,
                    ),
                    children: [
                      _Header(state: state),
                      const SizedBox(height: AppTheme.spacingLg),
                      PodiumView(
                        topThree: leaderboard.take(3).toList(),
                        myUserId: myUserId,
                      ),
                      const SizedBox(height: AppTheme.spacingXl),
                      const _SectionLabel('FULL LEADERBOARD'),
                      const SizedBox(height: AppTheme.spacingSm),
                      ...List.generate(leaderboard.length, (i) {
                        final player = leaderboard[i];
                        final stats = _computeStats(player.id, state.answers);
                        return _LeaderboardRow(
                          rank: i + 1,
                          player: player,
                          stats: stats,
                          isMe: player.userId == myUserId,
                        );
                      }),
                      const SizedBox(height: AppTheme.spacingMd),
                      OutlinedButton.icon(
                        onPressed: () => _handleShare(state, leaderboard),
                        icon: const Icon(Icons.ios_share),
                        label: const Text('Share Results'),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      // TASK-061: per-question class breakdown lands here.
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingLg,
                    AppTheme.spacingSm,
                    AppTheme.spacingLg,
                    AppTheme.spacingMd,
                  ),
                  child: isHost
                      ? _HostActions(
                          onPlayAgain: () => _handlePlayAgain(state),
                          onEnd: _handleExit,
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: AppTheme.onPrimary,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            onPressed: _handleExit,
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text(
                              'Done',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: IgnorePointer(
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2,
                blastDirectionality: BlastDirectionality.explosive,
                maxBlastForce: 22,
                minBlastForce: 8,
                emissionFrequency: 0.05,
                numberOfParticles: 25,
                gravity: 0.2,
                shouldLoop: false,
                colors: const [
                  AppTheme.primary,
                  AppTheme.secondary,
                  AppTheme.tertiary,
                  AppTheme.gold,
                  Color(0xFF81C784),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _PlayerStats _computeStats(String playerId, List<GroupAnswer> all) {
    final mine = all.where((a) => a.playerId == playerId).toList();
    if (mine.isEmpty) {
      return const _PlayerStats(accuracy: 0, avgMs: 0, answered: 0);
    }
    final correct = mine.where((a) => a.isCorrect).length;
    final totalMs =
        mine.map((a) => a.responseTimeMs).fold<int>(0, (a, b) => a + b);
    return _PlayerStats(
      accuracy: correct / mine.length,
      avgMs: totalMs ~/ mine.length,
      answered: mine.length,
    );
  }

  Future<void> _handlePlayAgain(GroupPlayState state) async {
    final room = state.room;
    final me = state.me;
    if (room == null || me == null) return;
    await ref.read(groupPlayProvider.notifier).hostCreateRoom(
          scope: room.scope,
          hostNickname: me.nickname,
        );
    // Phase listener handles navigation once the new room is ready.
  }

  void _handleExit() {
    ref.read(groupPlayProvider.notifier).resetToIdle();
    context.go('/');
  }

  Future<void> _handleShare(
    GroupPlayState state,
    List<GroupPlayer> leaderboard,
  ) async {
    final buf = StringBuffer()
      ..writeln('Seminary Sidekick — Group Quiz Results')
      ..writeln('Code: ${state.room?.code ?? widget.code}')
      ..writeln();
    final medals = ['🥇', '🥈', '🥉'];
    final top = leaderboard.take(3).toList();
    for (var i = 0; i < top.length; i++) {
      buf.writeln('${medals[i]} ${top[i].nickname} — ${top[i].score} pts');
    }
    if (leaderboard.length > 3) {
      buf.writeln();
      for (var i = 3; i < leaderboard.length; i++) {
        buf.writeln(
            '${i + 1}. ${leaderboard[i].nickname} — ${leaderboard[i].score} pts');
      }
    }
    buf
      ..writeln()
      ..writeln('Play scripture mastery games together — Seminary Sidekick.');

    await Share.share(buf.toString(), subject: 'Group Quiz Results');
  }
}

class _PlayerStats {
  final double accuracy;
  final int avgMs;
  final int answered;

  const _PlayerStats({
    required this.accuracy,
    required this.avgMs,
    required this.answered,
  });
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final GroupPlayState state;

  const _Header({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final me = state.me;
    final leaderboard = state.leaderboard;
    final myRank = me == null
        ? null
        : leaderboard.indexWhere((p) => p.id == me.id) + 1;

    final headline = switch (myRank) {
      1 => 'You won! 🎉',
      2 => 'So close — 2nd place!',
      3 => 'Bronze finish!',
      _ => 'Great game!',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          headline,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontFamily: 'Merriweather',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        if (me != null)
          Text(
            'Your score: ${me.score} pts',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

// ─── Leaderboard row ─────────────────────────────────────────────────────────

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final GroupPlayer player;
  final _PlayerStats stats;
  final bool isMe;

  const _LeaderboardRow({
    required this.rank,
    required this.player,
    required this.stats,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accuracyPct = (stats.accuracy * 100).round();
    final avgSec = (stats.avgMs / 1000).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: isMe
            ? AppTheme.primary.withValues(alpha: 0.10)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: isMe
            ? Border.all(
                color: AppTheme.primary.withValues(alpha: 0.5),
                width: 1.5,
              )
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: isMe ? AppTheme.primary : theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.nickname + (isMe ? ' (you)' : ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: isMe ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stats.answered == 0
                      ? 'No answers'
                      : '$accuracyPct% accuracy · ${avgSec}s avg',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Text(
            '${player.score}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: isMe ? AppTheme.primary : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Host action row ─────────────────────────────────────────────────────────

class _HostActions extends StatelessWidget {
  final VoidCallback onPlayAgain;
  final VoidCallback onEnd;

  const _HostActions({required this.onPlayAgain, required this.onEnd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onEnd,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            icon: const Icon(Icons.close),
            label: const Text(
              'End',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: onPlayAgain,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tertiary,
              foregroundColor: AppTheme.onTertiary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.replay),
            label: const Text(
              'Play Again',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.5,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}
