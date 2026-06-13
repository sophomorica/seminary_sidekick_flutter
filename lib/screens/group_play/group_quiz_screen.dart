import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/group_answer.dart';
import '../../models/group_play_state.dart';
import '../../models/group_player.dart';
import '../../models/group_question.dart';
import '../../models/group_room.dart';
import '../../providers/group_play_provider.dart';
import '../../services/audio_service.dart';
import '../../services/haptic_service.dart';
import '../../theme/app_theme.dart';
import 'widgets/answer_distribution.dart';
import 'widgets/answers_received_indicator.dart';
import 'widgets/group_question_card.dart';
import 'widgets/live_leaderboard.dart';
import 'widgets/reconnecting_banner.dart';

/// Live multiplayer quiz screen.
///
/// Layout switches between two local phases per question:
///   - `question`: question card with answer buttons (player) or live counter
///     + countdown (host).
///   - `leaderboard`: top-5 with rank deltas (everyone). Host has the
///     "Next Question" / "Finish" advancing button.
///
/// Phase transitions:
///   - room.currentQuestionIndex changes (via stream) → reset to `question`,
///     restart timer, snapshot ranks.
///   - timer expires → switch to `leaderboard`.
///   - phase==viewingResults (room ended) → navigate to results screen.
///
/// V1 simplifications (intentionally):
///   - No per-player disconnect detection. We rely on the room watcher.
///   - No rejoin-after-disconnect.
///   - No early "all answered → advance" — host always controls cadence.
class GroupQuizScreen extends ConsumerStatefulWidget {
  final String code;

  const GroupQuizScreen({super.key, required this.code});

  @override
  ConsumerState<GroupQuizScreen> createState() => _GroupQuizScreenState();
}

enum _LocalPhase { question, leaderboard }

class _GroupQuizScreenState extends ConsumerState<GroupQuizScreen> {
  Timer? _ticker;
  int _remainingSeconds = 20;
  DateTime? _questionStartedAt;
  int? _trackedQuestionIndex;
  _LocalPhase _phase = _LocalPhase.question;

  /// playerId → rank (1-based) snapshotted at the start of this question.
  Map<String, int> _previousRanks = const {};

  late final ConfettiController _confettiController;
  bool _firedFeedbackForCurrentQuestion = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Auto-navigate to results when the room ends.
    ref.listen<GroupPlayPhase>(groupPlayPhaseProvider, (prev, next) {
      if (next == GroupPlayPhase.viewingResults && mounted) {
        context.go('/group-play/results/${widget.code}');
      } else if (next == GroupPlayPhase.idle && mounted) {
        // Room was reset (we left or got kicked) — pop back home.
        context.go('/');
      }
    });

    final state = ref.watch(groupPlayProvider);
    final room = state.room;
    final me = state.me;

    if (room == null || me == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Detect question-index transitions to reset per-question UI state.
    final currentIndex = room.currentQuestionIndex;
    if (_trackedQuestionIndex != currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _onQuestionChanged(state),
      );
    }

    // Fire haptic + confetti once per question after the player answers.
    final myAnswerForCurrent = _findMyAnswer(state);
    if (myAnswerForCurrent != null && !_firedFeedbackForCurrentQuestion) {
      _firedFeedbackForCurrentQuestion = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (myAnswerForCurrent.isCorrect) {
          ref.read(hapticProvider).medium();
          _confettiController.play();
        } else {
          ref.read(hapticProvider).light();
        }
      });
    }

    final question = state.currentQuestion;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _confirmExit,
        ),
        title: Text(
          'Question ${currentIndex + 1} of ${state.questions.length}',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _CountdownChip(seconds: _remainingSeconds),
          ),
        ],
      ),
      body: question == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    if (state.isReconnecting) const ReconnectingBanner(),
                    _ProgressBar(
                      current: currentIndex + 1,
                      total: state.questions.length,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: _phase == _LocalPhase.leaderboard
                            ? _LeaderboardView(
                                state: state,
                                previousRanks: _previousRanks,
                                isLastQuestion: currentIndex >=
                                    state.questions.length - 1,
                                onAdvance: _handleAdvance,
                              )
                            : _QuestionView(
                                state: state,
                                question: question,
                                room: room,
                                me: me,
                                myAnswer: myAnswerForCurrent,
                                onTapAnswer: _handleAnswer,
                                onHostAdvance: _handleAdvance,
                                onHostShowLeaderboard:
                                    _handleHostShowLeaderboard,
                              ),
                      ),
                    ),
                  ],
                ),
                // Confetti overlay for correct answers
                Align(
                  alignment: Alignment.topCenter,
                  child: IgnorePointer(
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirection: math.pi / 2, // straight down
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

  // ─── State transitions ───────────────────────────────────────────────────

  void _onQuestionChanged(GroupPlayState state) {
    if (!mounted) return;
    final room = state.room;
    if (room == null) return;

    // Capture rank snapshot from the leaderboard BEFORE this question's
    // points have been factored in. Since the question just started, scores
    // haven't moved yet — `state.leaderboard` reflects the right ranks.
    final players = state.leaderboard;
    final snapshot = <String, int>{
      for (var i = 0; i < players.length; i++) players[i].id: i + 1,
    };

    final timeoutSeconds = room.scope.questionTimeoutSeconds;

    setState(() {
      _trackedQuestionIndex = room.currentQuestionIndex;
      _previousRanks = snapshot;
      _phase = _LocalPhase.question;
      _questionStartedAt = DateTime.now();
      _remainingSeconds = timeoutSeconds;
      _firedFeedbackForCurrentQuestion = false;
    });

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _remainingSeconds = math.max(0, _remainingSeconds - 1);
      });
      // Soft woodblock tick over the final 5 seconds to build urgency.
      if (_remainingSeconds >= 1 && _remainingSeconds <= 5) {
        ref.read(audioProvider.notifier).play(SoundEffect.countdownTick);
      }
      if (_remainingSeconds <= 0) {
        t.cancel();
        // Auto-flip to leaderboard so everyone sees the standings.
        if (mounted && _phase == _LocalPhase.question) {
          setState(() => _phase = _LocalPhase.leaderboard);
        }
      }
    });
  }

  GroupAnswer? _findMyAnswer(GroupPlayState state) {
    final me = state.me;
    final room = state.room;
    if (me == null || room == null) return null;
    return state.answers.firstWhereOrNull(
      (a) =>
          a.playerId == me.id &&
          a.questionIndex == room.currentQuestionIndex,
    );
  }

  // ─── Handlers ────────────────────────────────────────────────────────────

  Future<void> _handleAnswer(int choice) async {
    final state = ref.read(groupPlayProvider);
    if (state.currentQuestionAnswered) return;
    if (_questionStartedAt == null) return;

    final elapsed = DateTime.now().difference(_questionStartedAt!);
    ref.read(hapticProvider).selection();
    await ref.read(groupPlayProvider.notifier).submitAnswer(
          selectedChoice: choice,
          elapsed: elapsed,
        );
  }

  void _handleHostShowLeaderboard() {
    setState(() => _phase = _LocalPhase.leaderboard);
  }

  Future<void> _handleAdvance() async {
    final state = ref.read(groupPlayProvider);
    final room = state.room;
    if (room == null) return;

    final isLast = room.currentQuestionIndex >= state.questions.length - 1;
    ref.read(hapticProvider).medium();

    if (isLast) {
      await ref.read(groupPlayProvider.notifier).hostEndGame();
      // Phase listener in build() handles navigation to results.
    } else {
      await ref.read(groupPlayProvider.notifier).hostAdvanceQuestion();
    }
  }

  void _confirmExit() {
    final isHost = ref.read(isGroupHostProvider);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isHost ? 'End the game?' : 'Leave the game?'),
        content: Text(
          isHost
              ? 'Players will be sent back home and the room will close.'
              : "You can't rejoin once you leave.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Playing'),
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

// ─── Question View ───────────────────────────────────────────────────────────

class _QuestionView extends StatelessWidget {
  final GroupPlayState state;
  final GroupQuestion question;
  final GroupRoom room;
  final GroupPlayer me;
  final GroupAnswer? myAnswer;
  final ValueChanged<int> onTapAnswer;
  final Future<void> Function() onHostAdvance;
  final VoidCallback onHostShowLeaderboard;

  const _QuestionView({
    required this.state,
    required this.question,
    required this.room,
    required this.me,
    required this.myAnswer,
    required this.onTapAnswer,
    required this.onHostAdvance,
    required this.onHostShowLeaderboard,
  });

  @override
  Widget build(BuildContext context) {
    final isHost = state.isHost;
    final answersForCurrent = state.answers
        .where((a) => a.questionIndex == room.currentQuestionIndex)
        .toList();
    final answeredPlayerIds =
        answersForCurrent.map((a) => a.playerId).toSet();
    final answeredCount = answeredPlayerIds.length;
    final totalPlayers = state.players.length;

    final hasAnswered = state.currentQuestionAnswered || myAnswer != null;
    final revealAnswer = isHost ? false : hasAnswered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Host: live answer counter ───
        if (isHost) ...[
          AnswersReceivedIndicator(
            answeredCount: answeredCount,
            totalPlayers: totalPlayers,
          ),
          const SizedBox(height: AppTheme.spacingLg),
        ],

        // ─── Question card ───
        GroupQuestionCard(
          question: question,
          selectedChoice: state.mySelectedChoice ?? myAnswer?.selectedChoice,
          revealAnswer: revealAnswer,
          interactive: !isHost,
          onAnswer: isHost ? null : onTapAnswer,
        ),

        const SizedBox(height: AppTheme.spacingLg),

        // ─── Player feedback banner after answering ───
        if (!isHost && myAnswer != null)
          _PlayerFeedbackBanner(answer: myAnswer!),

        // ─── Player waiting copy ───
        if (!isHost && myAnswer == null && !state.currentQuestionAnswered)
          const _WaitingPrompt(
            text: 'Tap the answer you think is correct.',
          ),

        if (!isHost && hasAnswered)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingMd),
            child: _WaitingPrompt(
              text: answeredCount >= totalPlayers
                  ? 'Everyone answered. Waiting for host…'
                  : 'Locked in. Waiting for the rest of the room…',
            ),
          ),

        // ─── Host controls ───
        if (isHost) ...[
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onHostShowLeaderboard,
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: AppTheme.tertiary.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  icon: const Icon(Icons.leaderboard, size: 18),
                  // "Show" is redundant once the chart icon is there, and the
                  // longer label doesn't fit the 1:2 flex column on phones —
                  // it wrapped onto three lines mid-word. One word fits.
                  label: const Text(
                    'Leaderboard',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onHostAdvance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.onPrimary,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: Text(
                    room.currentQuestionIndex >=
                            state.questions.length - 1
                        ? 'Finish Game'
                        : 'Next Question',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── Leaderboard View ────────────────────────────────────────────────────────

class _LeaderboardView extends StatelessWidget {
  final GroupPlayState state;
  final Map<String, int> previousRanks;
  final bool isLastQuestion;
  final Future<void> Function() onAdvance;

  const _LeaderboardView({
    required this.state,
    required this.previousRanks,
    required this.isLastQuestion,
    required this.onAdvance,
  });

  @override
  Widget build(BuildContext context) {
    final isHost = state.isHost;
    final me = state.me;
    final room = state.room;
    final question = state.currentQuestion;
    final answersForQuestion = (room == null || question == null)
        ? const <GroupAnswer>[]
        : state.answers
            .where((a) => a.questionIndex == room.currentQuestionIndex)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── The reveal: how the class answered ───
        if (question != null) ...[
          AnswerDistribution(
            question: question,
            answers: answersForQuestion,
          ),
          const SizedBox(height: AppTheme.spacingLg),
        ],
        Text(
          isLastQuestion ? 'Final Standings' : 'Standings',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontFamily: 'Merriweather',
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingLg),
        LiveLeaderboard(
          players: state.leaderboard,
          previousRanks: previousRanks,
          localPlayerId: me?.id,
        ),
        const SizedBox(height: AppTheme.spacingLg),
        if (isHost)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAdvance,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                elevation: 0,
              ),
              icon: Icon(
                isLastQuestion ? Icons.flag : Icons.arrow_forward,
                size: 20,
              ),
              label: Text(
                isLastQuestion ? 'Finish Game' : 'Next Question',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        else
          _WaitingPrompt(
            text: isLastQuestion
                ? 'Wrapping up…'
                : 'Waiting for host to advance…',
          ),
      ],
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int current;
  final int total;

  const _ProgressBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final value = total > 0 ? current / total : 0.0;
    return ClipRRect(
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 4,
        backgroundColor:
            Theme.of(context).colorScheme.surfaceContainerHighest,
        valueColor:
            const AlwaysStoppedAnimation<Color>(AppTheme.tertiary),
      ),
    );
  }
}

class _CountdownChip extends StatelessWidget {
  final int seconds;
  const _CountdownChip({required this.seconds});

  @override
  Widget build(BuildContext context) {
    final isUrgent = seconds <= 5;
    final color = isUrgent ? AppTheme.error : AppTheme.tertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '${seconds}s',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
        ],
      ),
    );
  }
}

class _PlayerFeedbackBanner extends StatelessWidget {
  final GroupAnswer answer;

  const _PlayerFeedbackBanner({required this.answer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCorrect = answer.isCorrect;
    final color = isCorrect ? AppTheme.success : AppTheme.error;
    final label = isCorrect
        ? '+${answer.pointsEarned} pts ✓'
        : 'No points this round';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingPrompt extends StatelessWidget {
  final String text;
  const _WaitingPrompt({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
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
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
