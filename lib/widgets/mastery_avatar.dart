import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../theme/app_theme.dart';

/// Display-only mastery avatar. Renders a placeholder circle until PNGs land.
class MasteryAvatar extends StatefulWidget {
  final AvatarStage stage;
  final double size;

  /// 0 = idle, positive = hop, negative = flinch intensity cue from parent.
  final MasteryAvatarMotion motion;

  /// When non-null and different from [stage], plays a morph into [stage].
  final AvatarStage? morphFrom;

  final VoidCallback? onMorphComplete;

  const MasteryAvatar({
    super.key,
    required this.stage,
    this.size = 88,
    this.motion = MasteryAvatarMotion.idle,
    this.morphFrom,
    this.onMorphComplete,
  });

  @override
  State<MasteryAvatar> createState() => MasteryAvatarState();
}

enum MasteryAvatarMotion { idle, hop, flinch }

class MasteryAvatarState extends State<MasteryAvatar>
    with TickerProviderStateMixin {
  late AnimationController _hopController;
  late AnimationController _flinchController;
  late AnimationController _morphController;

  AvatarStage? _displayStage;
  AvatarStage? _pendingStage;
  bool _morphing = false;

  @override
  void initState() {
    super.initState();
    _displayStage = widget.stage;
    _hopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _flinchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (widget.morphFrom != null && widget.morphFrom != widget.stage) {
      _displayStage = widget.morphFrom;
      _pendingStage = widget.stage;
      WidgetsBinding.instance.addPostFrameCallback((_) => _runMorphCascade());
    }
  }

  @override
  void didUpdateWidget(MasteryAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.motion != oldWidget.motion) {
      switch (widget.motion) {
        case MasteryAvatarMotion.hop:
          _hopController.forward(from: 0);
        case MasteryAvatarMotion.flinch:
          _flinchController.forward(from: 0);
        case MasteryAvatarMotion.idle:
          break;
      }
    }
    if (widget.stage != oldWidget.stage ||
        widget.morphFrom != oldWidget.morphFrom) {
      if (widget.morphFrom != null &&
          widget.morphFrom != widget.stage &&
          !_morphing) {
        _displayStage = widget.morphFrom;
        _pendingStage = widget.stage;
        _runMorphCascade();
      } else if (!_morphing) {
        _displayStage = widget.stage;
      }
    }
  }

  Future<void> _runMorphCascade() async {
    if (_pendingStage == null || _displayStage == null) return;
    _morphing = true;

    var current = _displayStage!;
    final target = _pendingStage!;
    final startIndex = current.index;
    final endIndex = target.index;

    if (endIndex <= startIndex) {
      setState(() {
        _displayStage = target;
        _pendingStage = null;
        _morphing = false;
      });
      widget.onMorphComplete?.call();
      return;
    }

    for (var i = startIndex; i < endIndex; i++) {
      if (!mounted) return;
      await _morphController.forward(from: 0);
      if (!mounted) return;
      setState(() {
        _displayStage = AvatarStage.values[i + 1];
      });
      // Brief settle between cascading morphs.
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }

    if (!mounted) return;
    setState(() {
      _pendingStage = null;
      _morphing = false;
    });
    widget.onMorphComplete?.call();
  }

  /// Jump straight to the final stage (tap-to-skip).
  void skipTo(AvatarStage stage) {
    _morphController.stop();
    setState(() {
      _displayStage = stage;
      _pendingStage = null;
      _morphing = false;
    });
  }

  @override
  void dispose() {
    _hopController.dispose();
    _flinchController.dispose();
    _morphController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = _displayStage ?? widget.stage;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _hopController,
        _flinchController,
        _morphController,
      ]),
      builder: (context, child) {
        final hopT = Curves.easeOut.transform(_hopController.value);
        final hopY = -10.0 * (hopT < 0.5 ? hopT * 2 : (1 - hopT) * 2);

        final flinchT = _flinchController.value;
        final flinchAngle =
            0.12 * (flinchT < 0.5 ? flinchT * 2 : (1 - flinchT) * 2) *
                (flinchT < 0.5 ? 1 : -1);

        // Morph: scale-down+rotate out (0–0.45) → overshoot scale in (0.45–1).
        double scale = 1.0;
        double morphAngle = 0.0;
        double ringProgress = 0.0;
        if (_morphing) {
          final t = _morphController.value;
          if (t < 0.45) {
            final p = t / 0.45;
            scale = 1.0 - 0.85 * Curves.easeIn.transform(p);
            morphAngle = 0.6 * p;
          } else {
            final p = (t - 0.45) / 0.55;
            // Overshoot: go to 1.15 then settle to 1.0
            scale = 0.15 + 1.0 * Curves.elasticOut.transform(p);
            morphAngle = 0;
            ringProgress = Curves.easeOut.transform(p);
          }
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: Offset(0, hopY),
              child: Transform.rotate(
                angle: flinchAngle + morphAngle,
                child: Transform.scale(
                  scale: scale.clamp(0.05, 1.3),
                  child: SizedBox(
                    width: widget.size + 16,
                    height: widget.size + 16,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (ringProgress > 0)
                          CustomPaint(
                            size: Size(widget.size + 16, widget.size + 16),
                            painter: _ExpandingRingPainter(
                              progress: ringProgress,
                              color: AppTheme.success.withValues(alpha: 0.45),
                            ),
                          ),
                        Container(
                          width: widget.size,
                          height: widget.size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.surfaceContainerHighest,
                            border: Border.all(
                              color: colorScheme.outline.withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                stage.icon,
                                size: widget.size * 0.38,
                                color: colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              stage.label,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              stage.stageOfLabel,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ExpandingRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ExpandingRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;
    final paint = Paint()
      ..color = color.withValues(alpha: (1 - progress) * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, maxR * (0.55 + 0.45 * progress), paint);
  }

  @override
  bool shouldRepaint(_ExpandingRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
