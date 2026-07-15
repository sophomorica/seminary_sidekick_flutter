import 'package:flutter/material.dart';

import '../services/haptic_service.dart';
import '../services/score_story_engine.dart';
import '../theme/app_theme.dart';
import 'score_meter.dart';

/// Fast (~2s) ScoreMeter story for Group Play quiz — reuses [ScoreMeter].
///
/// No mastery avatar. Tap anywhere to skip to the final score.
class CompressedScoreStory extends StatefulWidget {
  final ScoreStory story;
  final HapticService haptics;
  final VoidCallback? onComplete;
  final double meterSize;

  /// Total pacing budget for the auto-play sequence (not including skip).
  final Duration budget;

  const CompressedScoreStory({
    super.key,
    required this.story,
    required this.haptics,
    this.onComplete,
    this.meterSize = 180,
    this.budget = const Duration(milliseconds: 2000),
  });

  @override
  State<CompressedScoreStory> createState() => _CompressedScoreStoryState();
}

class _CompressedScoreStoryState extends State<CompressedScoreStory>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;

  int _revealed = 0;
  int _displayScore = 0;
  double _meterValue = 0;
  Duration _meterAnim = const Duration(milliseconds: 280);
  ScoreEvent? _chip;
  bool _showGrade = false;
  bool _done = false;
  bool _skipped = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final events = widget.story.events;
    if (events.isEmpty) {
      _finish();
      return;
    }

    // Split budget across events + a short final beat.
    final perEventMs =
        (widget.budget.inMilliseconds * 0.7 / events.length).round().clamp(200, 500);
    final chipMs = (perEventMs * 0.25).round().clamp(60, 120);
    final arcMs = (perEventMs - chipMs).clamp(120, 400);

    var running = 0;
    for (var i = 0; i < events.length; i++) {
      if (!mounted || _skipped) return;
      final event = events[i];
      setState(() => _chip = event);
      await Future<void>.delayed(Duration(milliseconds: chipMs));
      if (!mounted || _skipped) return;

      running =
          (running + event.points).clamp(0, ScoreStoryEngine.maxScore);
      if (event.isMiss) {
        widget.haptics.heavy();
        _shakeController.forward(from: 0);
      } else {
        widget.haptics.light();
      }

      setState(() {
        _meterAnim = Duration(milliseconds: arcMs);
        _displayScore = running;
        _meterValue = running / ScoreStoryEngine.maxScore;
      });
      await Future<void>.delayed(Duration(milliseconds: arcMs));
      if (!mounted || _skipped) return;

      setState(() {
        _chip = null;
        _revealed = i + 1;
      });
    }

    if (!mounted || _skipped) return;
    widget.haptics.medium();
    setState(() {
      _displayScore = widget.story.finalScore;
      _meterValue = widget.story.finalScore / ScoreStoryEngine.maxScore;
      _showGrade = true;
      _revealed = events.length;
    });
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted || _skipped) return;
    _finish();
  }

  void _finish() {
    if (_done) return;
    setState(() {
      _done = true;
      _chip = null;
      _showGrade = true;
      _displayScore = widget.story.finalScore;
      _meterValue = widget.story.finalScore / ScoreStoryEngine.maxScore;
      _revealed = widget.story.events.length;
    });
    widget.onComplete?.call();
  }

  void _skip() {
    if (_done || _skipped) return;
    _skipped = true;
    _shakeController.stop();
    _finish();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final revealed = widget.story.events.take(_revealed).toList();
    final shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -6), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 1),
    ]).animate(_shakeController);

    return GestureDetector(
      key: const Key('group-score-story-skip'),
      behavior: HitTestBehavior.opaque,
      onTap: _skip,
      child: Column(
        children: [
          Text(
            'Your round',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(shake.value, 0),
                child: child,
              );
            },
            child: Column(
              children: [
                SizedBox(
                  height: 28,
                  child: AnimatedOpacity(
                    opacity: _chip == null ? 0 : 1,
                    duration: const Duration(milliseconds: 100),
                    child: _chip == null
                        ? const SizedBox.shrink()
                        : _MiniChip(event: _chip!),
                  ),
                ),
                ScoreMeter(
                  value: _meterValue,
                  displayScore: _displayScore,
                  gradeLabel: _showGrade ? widget.story.grade.label : null,
                  size: widget.meterSize,
                  animationDuration: _meterAnim,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...revealed.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    e.icon,
                    size: 16,
                    color: e.isMiss
                        ? AppTheme.error
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    e.signedPoints,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: e.isMiss ? AppTheme.error : null,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final ScoreEvent event;

  const _MiniChip({required this.event});

  @override
  Widget build(BuildContext context) {
    final color = event.isMiss ? AppTheme.error : AppTheme.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        '${event.label} ${event.signedPoints}',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
