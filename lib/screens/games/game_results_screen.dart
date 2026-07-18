import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../providers/progress_provider.dart';
import '../../services/audio_service.dart';
import '../../services/haptic_service.dart';
import '../../services/score_story_engine.dart';
import '../../theme/app_theme.dart';
import '../../widgets/mastery_avatar.dart';
import '../../widgets/score_meter.dart';

class GameResultsScreen extends ConsumerStatefulWidget {
  final GameType gameType;
  final DifficultyLevel difficulty;
  final int correctMatches;
  final int incorrectAttempts;
  final int totalPairs;
  final Duration completionTime;
  final int starRating; // 1-3 — kept for callers; UI no longer reads it
  /// True when the session first reaches holistic Mastered (SB path).
  /// Banner copy is `Master {difficulty.label}!` for the round's difficulty.
  final bool isNewMastery;

  /// Per-scripture avatar badge stage (Scripture Builder passes this from the
  /// session scripture's mastery level after this round). When null, falls
  /// back to the app-wide stage from [UserStats.avatarStage].
  final AvatarStage? avatarStageAfter;
  /// Rebuilds the same game session so "Try Again" can relaunch immediately.
  /// Games reach this screen via [Navigator.pushReplacement], so a plain pop
  /// cannot restart — callers must supply the original game screen.
  final WidgetBuilder tryAgainBuilder;

  const GameResultsScreen({
    super.key,
    required this.gameType,
    required this.difficulty,
    required this.correctMatches,
    required this.incorrectAttempts,
    required this.totalPairs,
    required this.completionTime,
    required this.starRating,
    required this.tryAgainBuilder,
    this.isNewMastery = false,
    this.avatarStageAfter,
  });

  @override
  ConsumerState<GameResultsScreen> createState() => _GameResultsScreenState();
}

class _GameResultsScreenState extends ConsumerState<GameResultsScreen>
    with TickerProviderStateMixin {
  late final ScoreStory _story;
  late ConfettiController _confettiController;
  late AnimationController _shakeController;
  late AnimationController _finalPopController;
  late AnimationController _avatarRevealController;

  int _revealedEventCount = 0;
  int _displayScore = 0;
  double _meterValue = 0;
  Duration _meterAnimDuration = const Duration(milliseconds: 640);
  ScoreEvent? _activeChip;
  bool _blankScore = false;
  bool _showGrade = false;
  bool _sequenceDone = false;
  bool _showMasteryBanner = false;
  bool _skipped = false;
  bool _showAvatar = false;
  late AvatarStage _finalStage;

  bool get _shouldCelebrate =>
      _story.isMasterful || widget.isNewMastery;

  @override
  void initState() {
    super.initState();

    _story = ScoreStoryEngine.build(
      gameType: widget.gameType,
      difficulty: widget.difficulty,
      correctMatches: widget.correctMatches,
      incorrectAttempts: widget.incorrectAttempts,
      totalPairs: widget.totalPairs,
      completionTime: widget.completionTime,
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _finalPopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _avatarRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    // Badge stage: per-scripture from the caller (Scripture Builder — the
    // avatar reflects THIS scripture's journey), else app-wide fallback.
    // Hidden during the run; revealed (fade + zoom) after the final score.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _finalStage = widget.avatarStageAfter ??
          ref.read(userStatsProvider).avatarStage;
      setState(() {});
      _runSequence();
    });

    _finalStage = AvatarStage.quickToObserve;
  }

  Future<void> _runSequence() async {
    var running = 0;
    for (var i = 0; i < _story.events.length; i++) {
      if (!mounted || _skipped) return;
      final event = _story.events[i];
      setState(() {
        _activeChip = event;
      });

      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (!mounted || _skipped) return;

      running = (running + event.points).clamp(0, ScoreStoryEngine.maxScore);
      final duration = event.isMiss
          ? const Duration(milliseconds: 330)
          : const Duration(milliseconds: 640);

      if (event.isMiss) {
        ref.read(hapticProvider).heavy();
        _shakeController.forward(from: 0);
      } else {
        ref.read(hapticProvider).light();
      }

      setState(() {
        _meterAnimDuration = duration;
        _displayScore = running;
        _meterValue = running / ScoreStoryEngine.maxScore;
      });

      await Future<void>.delayed(duration);
      if (!mounted || _skipped) return;

      setState(() {
        _activeChip = null;
        _revealedEventCount = i + 1;
      });

      await Future<void>.delayed(const Duration(milliseconds: 120));
    }

    if (!mounted || _skipped) return;

    // Dramatic pause — blank the number.
    setState(() {
      _blankScore = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 750));
    if (!mounted || _skipped) return;

    ref.read(hapticProvider).medium();
    setState(() {
      _blankScore = false;
      _displayScore = _story.finalScore;
      _meterValue = _story.finalScore / ScoreStoryEngine.maxScore;
      _showGrade = true;
    });
    await _finalPopController.forward(from: 0);
    if (!mounted || _skipped) return;

    // Badge reveal after the final-score pop: fade in with a small
    // zoom-overshoot, then settle to normal size.
    if (widget.isNewMastery) {
      ref.read(audioProvider.notifier).play(SoundEffect.levelup);
    }
    setState(() {
      _showAvatar = true;
    });
    await _avatarRevealController.forward(from: 0);

    if (!mounted || _skipped) return;
    _finishSequence();
  }

  void _finishSequence() {
    setState(() {
      _sequenceDone = true;
      _showMasteryBanner = widget.isNewMastery;
    });
    if (_shouldCelebrate) {
      _confettiController.play();
    }
  }

  void _skipToEnd() {
    if (_sequenceDone || _skipped) return;
    _skipped = true;
    _shakeController.stop();
    _finalPopController.stop();
    _avatarRevealController.value = 1;
    setState(() {
      _activeChip = null;
      _blankScore = false;
      _revealedEventCount = _story.events.length;
      _displayScore = _story.finalScore;
      _meterValue = _story.finalScore / ScoreStoryEngine.maxScore;
      _showGrade = true;
      _showAvatar = true;
      _sequenceDone = true;
      _showMasteryBanner = widget.isNewMastery;
    });
    if (_shouldCelebrate) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _shakeController.dispose();
    _finalPopController.dispose();
    _avatarRevealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final revealed = _story.events.take(_revealedEventCount).toList();

    final popScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.85, end: 1.18)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.18, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_finalPopController);

    final shakeOffset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -5, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.linear,
    ));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      key: const Key('score-story-skip'),
                      behavior: HitTestBehavior.opaque,
                      onTap: _skipToEnd,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            AnimatedBuilder(
                              animation: Listenable.merge([
                                _shakeController,
                                _finalPopController,
                              ]),
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(shakeOffset.value, 0),
                                  child: Transform.scale(
                                    scale: _showGrade &&
                                            _finalPopController.isAnimating
                                        ? popScale.value
                                        : 1.0,
                                    child: child,
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  // Event chip above meter
                                  SizedBox(
                                    height: 36,
                                    child: AnimatedOpacity(
                                      opacity: _activeChip == null ? 0 : 1,
                                      duration:
                                          const Duration(milliseconds: 180),
                                      child: _activeChip == null
                                          ? const SizedBox.shrink()
                                          : _EventChip(event: _activeChip!),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ScoreMeter(
                                    value: _meterValue,
                                    displayScore: _displayScore,
                                    gradeLabel: _showGrade
                                        ? _story.grade.label
                                        : null,
                                    blankScore: _blankScore,
                                    animationDuration: _meterAnimDuration,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Badge appears after the meter finishes: fade in
                            // with a small zoom-overshoot, settle to 1.0.
                            AnimatedBuilder(
                              animation: _avatarRevealController,
                              builder: (context, child) {
                                final t = _avatarRevealController.value;
                                final scale = TweenSequence<double>([
                                  TweenSequenceItem(
                                    tween: Tween(begin: 0.7, end: 1.08).chain(
                                        CurveTween(curve: Curves.easeOut)),
                                    weight: 65,
                                  ),
                                  TweenSequenceItem(
                                    tween: Tween(begin: 1.08, end: 1.0).chain(
                                        CurveTween(curve: Curves.easeInOut)),
                                    weight: 35,
                                  ),
                                ]).transform(t);
                                return Opacity(
                                  opacity: _showAvatar
                                      ? Curves.easeOut.transform(t)
                                      : 0.0,
                                  child: Transform.scale(
                                    scale: scale,
                                    child: child,
                                  ),
                                );
                              },
                              child: MasteryAvatar(stage: _finalStage),
                            ),
                            const SizedBox(height: 20),
                            // Receipt list
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    for (var i = 0; i < revealed.length; i++) ...[
                                      if (i > 0) const Divider(height: 16),
                                      _ReceiptRow(event: revealed[i]),
                                    ],
                                    if (revealed.isEmpty)
                                      Text(
                                        'Your score story is unfolding…',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                    if (_sequenceDone) ...[
                                      if (revealed.isNotEmpty)
                                        const Divider(height: 16),
                                      _StatRow(
                                        icon: Icons.check_circle_outline,
                                        iconColor: AppTheme.success,
                                        label: 'Correct',
                                        value:
                                            '${widget.correctMatches}/${widget.totalPairs}',
                                      ),
                                      const Divider(height: 16),
                                      _StatRow(
                                        icon: Icons.timer_outlined,
                                        iconColor: AppTheme.secondary,
                                        label: 'Time',
                                        value: _formatDuration(
                                            widget.completionTime),
                                      ),
                                      const Divider(height: 16),
                                      _StatRow(
                                        icon: Icons.speed,
                                        iconColor: colorScheme.primary,
                                        label: 'Difficulty',
                                        value: widget.difficulty.label,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: widget.tryAgainBuilder),
                        );
                      },
                      icon: const Icon(Icons.replay),
                      label: const Text('Try Again'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.home_outlined),
                      label: const Text('Back to Practice'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_shouldCelebrate && _sequenceDone)
            Align(
              alignment: Alignment.topCenter,
              child: IgnorePointer(
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: pi / 2,
                  blastDirectionality: BlastDirectionality.explosive,
                  maxBlastForce: 20,
                  minBlastForce: 8,
                  emissionFrequency: 0.05,
                  numberOfParticles: 25,
                  gravity: 0.2,
                  shouldLoop: false,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    AppTheme.secondary,
                    AppTheme.accent,
                    AppTheme.gold,
                    AppTheme.warning,
                    AppTheme.success,
                  ],
                ),
              ),
            ),

          if (_showMasteryBanner)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        color: colorScheme.onPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Master ${widget.difficulty.label}!',
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _EventChip extends StatelessWidget {
  final ScoreEvent event;

  const _EventChip({required this.event});

  @override
  Widget build(BuildContext context) {
    final color = event.isMiss ? AppTheme.error : AppTheme.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(event.icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '${event.label} ${event.signedPoints}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final ScoreEvent event;

  const _ReceiptRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final color =
        event.isMiss ? AppTheme.error : Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(event.icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            event.label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          event.signedPoints,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
