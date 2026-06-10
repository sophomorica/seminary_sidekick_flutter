import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/scriptures_data.dart';
import '../../models/group_play_state.dart';
import '../../models/group_player.dart';
import '../../models/group_room.dart';
import '../../models/group_sb_config.dart';
import '../../models/group_sb_finish.dart';
import '../../models/scripture.dart';
import '../../providers/group_play_provider.dart';
import '../../services/haptic_service.dart';
import '../../theme/app_theme.dart';
import 'widgets/reconnecting_banner.dart';
import 'widgets/sb_finish_banner.dart';
import 'widgets/sb_host_progress_dashboard.dart';
import 'widgets/sb_race_board.dart';

/// Live Word-Builder race screen.
///
/// Host view: scoreboard / progress dashboard, no race board.
/// Player view: race board for the current scripture; on completion, the
/// finish banner; in Set-of-N, the next scripture auto-loads.
///
/// Round-by-Round: scripture advances when host taps "Next Scripture".
/// Set-of-N: each player advances independently on their own device. Host
/// only ever taps "End Game".
class GroupScriptureBuilderScreen extends ConsumerStatefulWidget {
  final String code;

  const GroupScriptureBuilderScreen({super.key, required this.code});

  @override
  ConsumerState<GroupScriptureBuilderScreen> createState() =>
      _GroupScriptureBuilderScreenState();
}

class _GroupScriptureBuilderScreenState
    extends ConsumerState<GroupScriptureBuilderScreen> {
  late final ConfettiController _confettiController;

  // Set-of-N: which scripture the local player is currently on. Advances
  // independently of `room.currentQuestionIndex` (which only matters in
  // Round-by-Round mode).
  int _myLocalIndex = 0;

  // Round-by-Round: snapshot of currentQuestionIndex so we can detect when
  // the host has advanced and reset the local board.
  int? _trackedHostIndex;

  // Per-scripture timer for the optional perScriptureTimeoutSeconds DNF.
  Timer? _timeoutTimer;
  DateTime? _scriptureStartedAt;
  bool _firedLocalFinishConfetti = false;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(milliseconds: 700));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Auto-nav to results when the room ends.
    ref.listen<GroupPlayPhase>(groupPlayPhaseProvider, (prev, next) {
      if (next == GroupPlayPhase.viewingResults && mounted) {
        context.go('/group-play/results/${widget.code}');
      } else if (next == GroupPlayPhase.idle && mounted) {
        context.go('/');
      }
    });

    final state = ref.watch(groupPlayProvider);
    final room = state.room;
    final me = state.me;
    final sbConfig = state.sbConfig;

    if (room == null || me == null || sbConfig == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Round-by-Round: detect host advancing so we can reset the local board.
    if (sbConfig.playMode == GroupSbPlayMode.roundByRound) {
      final hostIdx = room.currentQuestionIndex;
      if (_trackedHostIndex != hostIdx) {
        _trackedHostIndex = hostIdx;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _firedLocalFinishConfetti = false;
            _scriptureStartedAt = DateTime.now();
          });
          _restartTimeoutTimer(sbConfig);
        });
      }
    } else {
      // Set-of-N: keep the local index in sync with `sbFinishes` so a refresh
      // (e.g. coming back to the screen after a backgrounded race) shows the
      // next scripture instead of the one we just finished.
      final myFinishCount =
          state.sbFinishes.where((f) => f.playerId == me.id).length;
      if (myFinishCount > _myLocalIndex &&
          myFinishCount < sbConfig.scriptureIds.length) {
        _myLocalIndex = myFinishCount;
      }
      if (_scriptureStartedAt == null) {
        _scriptureStartedAt = DateTime.now();
        _restartTimeoutTimer(sbConfig);
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _confirmExit,
        ),
        title: _AppBarTitle(
          state: state,
          sbConfig: sbConfig,
          localScriptureIndex: _localIndexForPlayer(
            state: state,
            sbConfig: sbConfig,
            room: room,
            me: me,
          ),
        ),
        toolbarHeight: 64,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                if (state.isReconnecting) const ReconnectingBanner(),
                Expanded(
                  child: state.isHost
                      ? _HostView(
                          state: state,
                          sbConfig: sbConfig,
                          onAdvance: _handleAdvance,
                          onEnd: _handleEnd,
                        )
                      : _PlayerView(
                          state: state,
                          sbConfig: sbConfig,
                          myLocalIndex: _localIndexForPlayer(
                            state: state,
                            sbConfig: sbConfig,
                            room: room,
                            me: me,
                          ),
                          onFinish: _handleLocalFinish,
                          firedConfetti: _firedLocalFinishConfetti,
                        ),
                ),
              ],
            ),
          ),
          // Confetti when the local player finishes (NOT on every player's
          // finish — a 30-person class would overlap badly).
          Align(
            alignment: Alignment.topCenter,
            child: IgnorePointer(
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: math.pi / 2,
                blastDirectionality: BlastDirectionality.explosive,
                maxBlastForce: 14,
                minBlastForce: 6,
                emissionFrequency: 0.04,
                numberOfParticles: 14,
                gravity: 0.25,
                shouldLoop: false,
                colors: const [
                  AppTheme.primary,
                  AppTheme.secondary,
                  AppTheme.tertiary,
                  Color(0xFFFFD54F),
                  Color(0xFF81C784),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  int _localIndexForPlayer({
    required GroupPlayState state,
    required GroupSbConfig sbConfig,
    required GroupRoom room,
    required GroupPlayer me,
  }) {
    if (sbConfig.playMode == GroupSbPlayMode.roundByRound) {
      return room.currentQuestionIndex
          .clamp(0, math.max(0, sbConfig.scriptureIds.length - 1));
    }
    return _myLocalIndex
        .clamp(0, math.max(0, sbConfig.scriptureIds.length - 1));
  }

  void _restartTimeoutTimer(GroupSbConfig sbConfig) {
    _timeoutTimer?.cancel();
    final timeout = sbConfig.perScriptureTimeoutSeconds;
    if (timeout == null) return;
    _timeoutTimer = Timer(Duration(seconds: timeout), () {
      if (!mounted) return;
      _handleLocalFinish(elapsedMs: timeout * 1000, mistakeCount: GroupSbFinish.dnfMistakeCount);
    });
  }

  Future<void> _handleLocalFinish({
    required int elapsedMs,
    required int mistakeCount,
  }) async {
    final state = ref.read(groupPlayProvider);
    final sbConfig = state.sbConfig;
    final room = state.room;
    final me = state.me;
    if (state.isHost || sbConfig == null || room == null || me == null) return;

    final scriptureIndex = _localIndexForPlayer(
      state: state,
      sbConfig: sbConfig,
      room: room,
      me: me,
    );

    _timeoutTimer?.cancel();

    // Local feedback (heavy haptic + confetti) once per scripture.
    if (!_firedLocalFinishConfetti) {
      _firedLocalFinishConfetti = true;
      ref.read(hapticProvider).heavy();
      if (mistakeCount != GroupSbFinish.dnfMistakeCount) {
        _confettiController.play();
      }
    }

    await ref.read(groupPlayProvider.notifier).submitSbFinish(
          scriptureIndex: scriptureIndex,
          elapsedMs: elapsedMs,
          mistakeCount: mistakeCount,
        );

    if (!mounted) return;

    // Set-of-N: advance to the next scripture locally; if we just finished
    // the last one, sit on the finish banner and wait for the room to end.
    if (sbConfig.playMode == GroupSbPlayMode.setOfN) {
      final nextIndex = scriptureIndex + 1;
      if (nextIndex < sbConfig.scriptureIds.length) {
        // Wait a beat so the banner / confetti are visible before re-load.
        Future.delayed(const Duration(milliseconds: 900), () {
          if (!mounted) return;
          setState(() {
            _myLocalIndex = nextIndex;
            _firedLocalFinishConfetti = false;
            _scriptureStartedAt = DateTime.now();
          });
          _restartTimeoutTimer(sbConfig);
        });
      }
    }
    // Round-by-Round: nothing else to do client-side. Host advances the room.
  }

  Future<void> _handleAdvance() async {
    final state = ref.read(groupPlayProvider);
    final sbConfig = state.sbConfig;
    final room = state.room;
    if (sbConfig == null || room == null) return;
    final isLast = room.currentQuestionIndex >=
        sbConfig.scriptureIds.length - 1;
    ref.read(hapticProvider).medium();
    if (isLast) {
      await ref.read(groupPlayProvider.notifier).hostEndGame();
    } else {
      await ref.read(groupPlayProvider.notifier).hostAdvanceScripture();
    }
  }

  Future<void> _handleEnd() async {
    ref.read(hapticProvider).medium();
    await ref.read(groupPlayProvider.notifier).hostEndGame();
  }

  void _confirmExit() {
    final isHost = ref.read(isGroupHostProvider);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isHost ? 'End the game?' : 'Leave the race?'),
        content: Text(
          isHost
              ? 'Players will be sent back home and the room will close.'
              : "You can't rejoin once you leave.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Going'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(groupPlayProvider.notifier).leave();
              if (mounted) context.go('/');
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: Text(isHost ? 'End Room' : 'Leave'),
          ),
        ],
      ),
    );
  }
}

// ─── App bar title ─────────────────────────────────────────────────────────

class _AppBarTitle extends StatelessWidget {
  final GroupPlayState state;
  final GroupSbConfig sbConfig;

  /// Scripture index the local viewer should see referenced — for the host
  /// this tracks `room.currentQuestionIndex`; for players in Set-of-N it
  /// tracks their own local position, which can be ahead of the host.
  final int localScriptureIndex;

  const _AppBarTitle({
    required this.state,
    required this.sbConfig,
    required this.localScriptureIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = sbConfig.scriptureIds.length;
    final isRound = sbConfig.playMode == GroupSbPlayMode.roundByRound;
    final scripture = _resolveScripture(sbConfig.scriptureIds, localScriptureIndex);
    final subtitle = isRound
        ? 'Round ${localScriptureIndex + 1} of $total'
        : 'Scripture ${localScriptureIndex + 1} of $total · Scripture Builder';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          scripture?.reference ?? 'Scripture Builder Race',
          style: theme.textTheme.titleMedium?.copyWith(
            fontFamily: 'Merriweather',
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          subtitle,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ─── Host view ─────────────────────────────────────────────────────────────

class _HostView extends StatelessWidget {
  final GroupPlayState state;
  final GroupSbConfig sbConfig;
  final Future<void> Function() onAdvance;
  final Future<void> Function() onEnd;

  const _HostView({
    required this.state,
    required this.sbConfig,
    required this.onAdvance,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final room = state.room!;
    final sbFinishes = state.sbFinishes;
    final racers = state.players
        .where((p) => !p.isHost)
        .toList(growable: false);

    final isRound = sbConfig.playMode == GroupSbPlayMode.roundByRound;
    final scriptureIndex = room.currentQuestionIndex;
    final scripture = _resolveScripture(
      sbConfig.scriptureIds,
      isRound ? scriptureIndex : 0,
    );

    // Round-by-Round "everyone finished" check
    final finishedThisRound = sbFinishes
        .where((f) => f.scriptureIndex == scriptureIndex)
        .map((f) => f.playerId)
        .toSet();
    final allFinished = racers.isNotEmpty &&
        racers.every((p) => finishedThisRound.contains(p.id));

    final isLast = scriptureIndex >= sbConfig.scriptureIds.length - 1;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLg,
              vertical: AppTheme.spacingMd,
            ),
            children: [
              if (scripture != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scripture.reference,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        scripture.keyPhrase,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),
              ],
              SbHostProgressDashboard(
                mode: sbConfig.playMode,
                players: state.players,
                finishes: sbFinishes,
                currentScriptureIndex: scriptureIndex,
                totalScriptures: sbConfig.scriptureIds.length,
                hostPlayerId: state.me?.id,
              ),
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
          child: isRound
              ? Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEnd,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                          ),
                        ),
                        icon: const Icon(Icons.stop_circle_outlined),
                        label: const Text('End'),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: onAdvance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: allFinished
                              ? AppTheme.primary
                              : AppTheme.primary.withValues(alpha: 0.65),
                          foregroundColor: AppTheme.onPrimary,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          elevation: 0,
                        ),
                        icon: Icon(
                            isLast ? Icons.flag : Icons.arrow_forward),
                        label: Text(
                          isLast
                              ? 'Finish Game'
                              : (allFinished
                                  ? 'Next Scripture'
                                  : 'Skip Ahead'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onEnd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.tertiary,
                      foregroundColor: AppTheme.onTertiary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.flag),
                    label: const Text(
                      'End Game',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── Player view ───────────────────────────────────────────────────────────

class _PlayerView extends ConsumerWidget {
  final GroupPlayState state;
  final GroupSbConfig sbConfig;
  final int myLocalIndex;
  final Future<void> Function({required int elapsedMs, required int mistakeCount})
      onFinish;
  final bool firedConfetti;

  const _PlayerView({
    required this.state,
    required this.sbConfig,
    required this.myLocalIndex,
    required this.onFinish,
    required this.firedConfetti,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = state.me!;
    final scripture = _resolveScripture(
      sbConfig.scriptureIds,
      myLocalIndex,
    );

    if (scripture == null) {
      return const Center(child: Text('Out of scriptures.'));
    }

    // Did I already finish this scripture?
    final myFinishForThis = state.sbFinishes.firstWhereOrNull(
      (f) => f.playerId == me.id && f.scriptureIndex == myLocalIndex,
    );

    if (myFinishForThis != null) {
      return _FinishedView(
        state: state,
        sbConfig: sbConfig,
        myFinish: myFinishForThis,
        scriptureIndex: myLocalIndex,
      );
    }

    final distractors = sbConfig.chunkDifficulty.hasDistractors
        ? distractorPoolFor(
            scopeIds: sbConfig.scriptureIds,
            excludeId: scripture.id,
          )
        : const <Scripture>[];

    return Column(
      children: [
        _RaceStatusStrip(state: state, myLocalIndex: myLocalIndex, sbConfig: sbConfig),
        Expanded(
          child: SbRaceBoard(
            // Reset the board when the local scripture index changes.
            key: ValueKey('sb-race-${scripture.id}-$myLocalIndex'),
            scripture: scripture,
            chunkDifficulty: sbConfig.chunkDifficulty,
            distractorPool: distractors,
            onFinish: (elapsedMs, mistakeCount) =>
                onFinish(elapsedMs: elapsedMs, mistakeCount: mistakeCount),
          ),
        ),
      ],
    );
  }
}

class _RaceStatusStrip extends StatelessWidget {
  final GroupPlayState state;
  final int myLocalIndex;
  final GroupSbConfig sbConfig;

  const _RaceStatusStrip({
    required this.state,
    required this.myLocalIndex,
    required this.sbConfig,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final me = state.me;
    if (me == null) return const SizedBox.shrink();

    final isRound = sbConfig.playMode == GroupSbPlayMode.roundByRound;

    // For round-by-round: how many people have already finished this round?
    // For set-of-N: how many scriptures has the leader finished?
    String detail;
    if (isRound) {
      final finishedCount = state.sbFinishes
          .where((f) => f.scriptureIndex == myLocalIndex)
          .map((f) => f.playerId)
          .toSet()
          .length;
      final racerCount = state.players.where((p) => !p.isHost).length;
      detail = finishedCount == 0
          ? 'You + ${math.max(0, racerCount - 1)} racing'
          : '$finishedCount finished · ${math.max(0, racerCount - finishedCount)} still racing';
    } else {
      // Set-of-N: show set position
      detail = 'Scripture ${myLocalIndex + 1} of ${sbConfig.scriptureIds.length}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      color: AppTheme.primary.withValues(alpha: 0.06),
      child: Row(
        children: [
          Icon(
            isRound ? Icons.flag_circle : Icons.timeline,
            size: 16,
            color: AppTheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              detail,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinishedView extends StatelessWidget {
  final GroupPlayState state;
  final GroupSbConfig sbConfig;
  final GroupSbFinish myFinish;
  final int scriptureIndex;

  const _FinishedView({
    required this.state,
    required this.sbConfig,
    required this.myFinish,
    required this.scriptureIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRound = sbConfig.playMode == GroupSbPlayMode.roundByRound;

    // Compute rank-in-this-round if applicable.
    int? rankInRound;
    if (isRound) {
      final finishesThisRound = state.sbFinishes
          .where((f) => f.scriptureIndex == scriptureIndex)
          .toList()
        ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
      final idx = finishesThisRound.indexWhere((f) => f.id == myFinish.id);
      if (idx >= 0) rankInRound = idx + 1;
    }

    // Set-of-N: am I done with the entire set?
    final me = state.me;
    final myFinishCount = me == null
        ? 0
        : state.sbFinishes.where((f) => f.playerId == me.id).length;
    final isSetDone = !isRound &&
        myFinishCount >= sbConfig.scriptureIds.length;

    final waitingCopy = isRound
        ? 'Waiting for the host to advance…'
        : (isSetDone
            ? 'Finished the set! Waiting for the host to end the game.'
            : 'Loading the next scripture…');

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingLg,
          vertical: AppTheme.spacingXl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SbFinishBanner(
              elapsedMs: myFinish.elapsedMs,
              mistakeCount: myFinish.mistakeCount,
              isDnf: myFinish.isDnf,
              rankInRound: rankInRound,
              prominent: true,
              label: isSetDone
                  ? 'Set complete!'
                  : (myFinish.isDnf ? 'Out of time' : 'You finished!'),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    waitingCopy,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────

Scripture? _resolveScripture(List<String> ids, int index) {
  if (index < 0 || index >= ids.length) return null;
  final id = ids[index];
  for (final s in allScriptures) {
    if (s.id == id) return s;
  }
  return null;
}
