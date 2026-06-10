import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/group_answer.dart';
import '../../models/group_play_state.dart';
import '../../models/group_player.dart';
import '../../models/group_room.dart';
import '../../models/group_sb_config.dart';
import '../../models/group_sb_finish.dart';
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
    // Hold the confetti until the podium's gold column rises into place —
    // the burst should hit as the winner appears, not on a bare screen.
    Future.delayed(PodiumView.goldRevealDelay, () {
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
    final isHost = ref.watch(isGroupHostProvider);
    final myUserId = ref.read(groupPlayServiceProvider).currentUserId;

    final isSb = state.room?.scope.mode == GroupGameMode.scriptureBuilder &&
        state.sbConfig != null;
    final rankedRows = isSb
        ? _rankSbPlayers(
            players: state.players,
            sbConfig: state.sbConfig!,
            finishes: state.sbFinishes,
          )
        : _rankQuizPlayers(
            players: state.players,
            answers: state.answers,
          );
    final leaderboard = rankedRows.map((r) => r.player).toList();

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
                      _Header(state: state, isSb: isSb, leaderboard: leaderboard),
                      const SizedBox(height: AppTheme.spacingLg),
                      PodiumView(
                        topThree: leaderboard.take(3).toList(),
                        myUserId: myUserId,
                      ),
                      const SizedBox(height: AppTheme.spacingXl),
                      const _SectionLabel('FULL LEADERBOARD'),
                      const SizedBox(height: AppTheme.spacingSm),
                      ...List.generate(rankedRows.length, (i) {
                        final row = rankedRows[i];
                        return _LeaderboardRow(
                          rank: i + 1,
                          player: row.player,
                          detail: row.detail,
                          score: row.score,
                          isMe: row.player.userId == myUserId,
                        );
                      }),
                      const SizedBox(height: AppTheme.spacingMd),
                      OutlinedButton.icon(
                        onPressed: () => _handleShare(state, rankedRows),
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

  /// Build the ranked-row list for a quiz-mode results screen — same as the
  /// existing leaderboard but in a single pass that also produces the
  /// per-row stat string.
  List<_RankedRow> _rankQuizPlayers({
    required List<GroupPlayer> players,
    required List<GroupAnswer> answers,
  }) {
    final sorted = [...players]..sort((a, b) => b.score.compareTo(a.score));
    return [
      for (final p in sorted)
        _RankedRow(
          player: p,
          score: '${p.score}',
          detail: _quizDetail(p.id, answers),
        ),
    ];
  }

  String _quizDetail(String playerId, List<GroupAnswer> answers) {
    final mine = answers.where((a) => a.playerId == playerId).toList();
    if (mine.isEmpty) return 'No answers';
    final correct = mine.where((a) => a.isCorrect).length;
    final totalMs =
        mine.map((a) => a.responseTimeMs).fold<int>(0, (a, b) => a + b);
    final accuracyPct = (correct / mine.length * 100).round();
    final avgSec = (totalMs / mine.length / 1000).toStringAsFixed(1);
    return '$accuracyPct% accuracy · ${avgSec}s avg';
  }

  /// Rank players for a Scripture Builder race. Excludes the host (who watched
  /// rather than raced) and players who didn't submit a single finish.
  ///
  /// Round-by-Round → cumulative round wins (faster finish wins each round);
  /// tiebreaker is cumulative elapsed time, ascending. Per-row score shows
  /// `Nw` (N round wins).
  ///
  /// Set-of-N → total elapsed time ascending, fewer mistakes as tiebreaker.
  /// Players who didn't finish every scripture rank below those who did.
  /// DNFs and missing scriptures both count as last for that scripture.
  List<_RankedRow> _rankSbPlayers({
    required List<GroupPlayer> players,
    required GroupSbConfig sbConfig,
    required List<GroupSbFinish> finishes,
  }) {
    final racers =
        players.where((p) => !p.isHost).toList(growable: false);

    if (sbConfig.playMode == GroupSbPlayMode.roundByRound) {
      // Count round wins per player. For each scripture index, the player
      // whose finish has the earliest `completedAt` and isn't a DNF wins.
      final wins = <String, int>{for (final p in racers) p.id: 0};
      final totalMs = <String, int>{for (final p in racers) p.id: 0};
      final totalMistakes = <String, int>{for (final p in racers) p.id: 0};
      final finishesPerPlayer = <String, int>{for (final p in racers) p.id: 0};
      for (var i = 0; i < sbConfig.scriptureIds.length; i++) {
        final round = finishes
            .where((f) => f.scriptureIndex == i && !f.isDnf)
            .toList()
          ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
        if (round.isNotEmpty) {
          wins[round.first.playerId] =
              (wins[round.first.playerId] ?? 0) + 1;
        }
      }
      for (final f in finishes) {
        if (!racers.any((p) => p.id == f.playerId)) continue;
        if (f.isDnf) {
          totalMistakes[f.playerId] =
              (totalMistakes[f.playerId] ?? 0) + 0; // DNF counted separately
          continue;
        }
        totalMs[f.playerId] = (totalMs[f.playerId] ?? 0) + f.elapsedMs;
        totalMistakes[f.playerId] =
            (totalMistakes[f.playerId] ?? 0) + f.mistakeCount;
        finishesPerPlayer[f.playerId] =
            (finishesPerPlayer[f.playerId] ?? 0) + 1;
      }
      final sorted = [...racers]..sort((a, b) {
          final wDiff = (wins[b.id] ?? 0).compareTo(wins[a.id] ?? 0);
          if (wDiff != 0) return wDiff;
          // tiebreaker: total time ascending
          return (totalMs[a.id] ?? 0).compareTo(totalMs[b.id] ?? 0);
        });
      return [
        for (final p in sorted)
          _RankedRow(
            player: p,
            score: '${wins[p.id] ?? 0}w',
            detail: _roundByRoundDetail(
              winCount: wins[p.id] ?? 0,
              totalMs: totalMs[p.id] ?? 0,
              finished: finishesPerPlayer[p.id] ?? 0,
              total: sbConfig.scriptureIds.length,
            ),
          ),
      ];
    }

    // Set-of-N: rank by total elapsed time across the set, ascending.
    // Mistakes is the tiebreaker. Players who finished fewer scriptures
    // (or DNF'd any) rank below those who finished all of them.
    final totalMs = <String, int>{for (final p in racers) p.id: 0};
    final totalMistakes = <String, int>{for (final p in racers) p.id: 0};
    final cleanFinishes = <String, int>{for (final p in racers) p.id: 0};
    final hasDnf = <String, bool>{for (final p in racers) p.id: false};
    for (final f in finishes) {
      if (!racers.any((p) => p.id == f.playerId)) continue;
      if (f.isDnf) {
        hasDnf[f.playerId] = true;
        continue;
      }
      totalMs[f.playerId] = (totalMs[f.playerId] ?? 0) + f.elapsedMs;
      totalMistakes[f.playerId] =
          (totalMistakes[f.playerId] ?? 0) + f.mistakeCount;
      cleanFinishes[f.playerId] = (cleanFinishes[f.playerId] ?? 0) + 1;
    }
    final n = sbConfig.scriptureIds.length;
    final sorted = [...racers]..sort((a, b) {
        // Completed-the-set rank above incomplete.
        final aDone = (cleanFinishes[a.id] ?? 0) >= n && !(hasDnf[a.id] ?? false);
        final bDone = (cleanFinishes[b.id] ?? 0) >= n && !(hasDnf[b.id] ?? false);
        if (aDone != bDone) return aDone ? -1 : 1;
        if (aDone) {
          final tDiff = (totalMs[a.id] ?? 0).compareTo(totalMs[b.id] ?? 0);
          if (tDiff != 0) return tDiff;
          return (totalMistakes[a.id] ?? 0)
              .compareTo(totalMistakes[b.id] ?? 0);
        }
        // Among incomplete: more scriptures finished is better.
        final cDiff = (cleanFinishes[b.id] ?? 0)
            .compareTo(cleanFinishes[a.id] ?? 0);
        if (cDiff != 0) return cDiff;
        return (totalMs[a.id] ?? 0).compareTo(totalMs[b.id] ?? 0);
      });
    return [
      for (final p in sorted)
        _RankedRow(
          player: p,
          score:
              '${((totalMs[p.id] ?? 0) / 1000).toStringAsFixed(1)}s',
          detail: _setOfNDetail(
            totalMs: totalMs[p.id] ?? 0,
            mistakes: totalMistakes[p.id] ?? 0,
            finished: cleanFinishes[p.id] ?? 0,
            total: n,
            hasDnf: hasDnf[p.id] ?? false,
          ),
        ),
    ];
  }

  String _roundByRoundDetail({
    required int winCount,
    required int totalMs,
    required int finished,
    required int total,
  }) {
    final sec = (totalMs / 1000).toStringAsFixed(1);
    return finished == 0
        ? 'No completions'
        : '$winCount ${winCount == 1 ? "round win" : "round wins"} · ${sec}s total';
  }

  String _setOfNDetail({
    required int totalMs,
    required int mistakes,
    required int finished,
    required int total,
    required bool hasDnf,
  }) {
    if (finished == 0 && !hasDnf) return 'No completions';
    final sec = (totalMs / 1000).toStringAsFixed(1);
    final base = finished >= total && !hasDnf
        ? 'Finished in ${sec}s'
        : 'Finished $finished of $total · ${sec}s';
    final mistakesPart = mistakes == 0
        ? 'clean'
        : '$mistakes ${mistakes == 1 ? "mistake" : "mistakes"}';
    return '$base · $mistakesPart';
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
    List<_RankedRow> rows,
  ) async {
    final isSb = state.room?.scope.mode == GroupGameMode.scriptureBuilder;
    final title = isSb
        ? 'Seminary Sidekick — Group Scripture Builder Race'
        : 'Seminary Sidekick — Group Quiz Results';
    final buf = StringBuffer()
      ..writeln(title)
      ..writeln('Code: ${state.room?.code ?? widget.code}')
      ..writeln();
    final medals = ['🥇', '🥈', '🥉'];
    for (var i = 0; i < rows.length && i < 3; i++) {
      buf.writeln('${medals[i]} ${rows[i].player.nickname} — ${rows[i].score}');
    }
    if (rows.length > 3) {
      buf.writeln();
      for (var i = 3; i < rows.length; i++) {
        buf.writeln(
            '${i + 1}. ${rows[i].player.nickname} — ${rows[i].score}');
      }
    }
    buf
      ..writeln()
      ..writeln('Play scripture mastery games together — Seminary Sidekick.');

    await Share.share(buf.toString(), subject: title);
  }
}

/// Pre-computed leaderboard row: the player, the metric to display in the
/// score column (already formatted), and the secondary line.
class _RankedRow {
  final GroupPlayer player;
  final String score;
  final String detail;

  const _RankedRow({
    required this.player,
    required this.score,
    required this.detail,
  });
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final GroupPlayState state;
  final bool isSb;
  final List<GroupPlayer> leaderboard;

  const _Header({
    required this.state,
    required this.isSb,
    required this.leaderboard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final me = state.me;
    final myRank = me == null
        ? null
        : (leaderboard.indexWhere((p) => p.id == me.id) + 1);

    final headline = switch (myRank) {
      0 || null => 'Great game!',
      1 => 'You won! 🎉',
      2 => 'So close — 2nd place!',
      3 => 'Bronze finish!',
      _ => 'Great game!',
    };

    // Different sub-line text per mode. SB hosts don't compete so they get
    // a neutral line.
    String? subLine;
    if (isSb) {
      if (state.isHost) {
        subLine = 'Race complete.';
      } else if (me != null) {
        final myFinishes =
            state.sbFinishes.where((f) => f.playerId == me.id).toList();
        if (myFinishes.isEmpty) {
          subLine = 'No finishes recorded.';
        } else {
          final totalMs = myFinishes
              .where((f) => !f.isDnf)
              .fold<int>(0, (acc, f) => acc + f.elapsedMs);
          subLine =
              'Your total time: ${(totalMs / 1000).toStringAsFixed(1)}s';
        }
      }
    } else if (me != null) {
      subLine = 'Your score: ${me.score} pts';
    }

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
        if (subLine != null) ...[
          const SizedBox(height: 4),
          Text(
            subLine,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Leaderboard row ─────────────────────────────────────────────────────────

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final GroupPlayer player;
  final String detail;
  final String score;
  final bool isMe;

  const _LeaderboardRow({
    required this.rank,
    required this.player,
    required this.detail,
    required this.score,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Text(
            score,
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
