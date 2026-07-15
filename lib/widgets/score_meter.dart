import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Half-circle score gauge (no needle). Modelled on [ProgressRing].
///
/// Fill color by fraction: &lt;0.4 error, &lt;0.7 warning, else success.
class ScoreMeter extends StatefulWidget {
  final double value; // 0.0 – 1.0
  final int displayScore;
  final String? gradeLabel;
  final double size;
  final Duration animationDuration;
  final bool blankScore;

  const ScoreMeter({
    super.key,
    required this.value,
    required this.displayScore,
    this.gradeLabel,
    this.size = 220,
    this.animationDuration = const Duration(milliseconds: 640),
    this.blankScore = false,
  });

  static Color fillColorFor(double fraction) {
    if (fraction < 0.4) return AppTheme.error;
    if (fraction < 0.7) return AppTheme.warning;
    return AppTheme.success;
  }

  @override
  State<ScoreMeter> createState() => _ScoreMeterState();
}

class _ScoreMeterState extends State<ScoreMeter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(ScoreMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationDuration != widget.animationDuration) {
      _controller.duration = widget.animationDuration;
    }
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(begin: _animation.value, end: widget.value)
          .animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // Half-circle needs width ≈ 2× height of the arc; keep a square box
    // so the painter can place the arc in the upper half.
    return SizedBox(
      width: widget.size,
      height: widget.size * 0.62,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final fraction = _animation.value.clamp(0.0, 1.0);
          final fill = ScoreMeter.fillColorFor(fraction);
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size * 0.62),
                painter: _ScoreMeterPainter(
                  value: fraction,
                  fillColor: fill,
                  trackColor: colorScheme.outline.withValues(alpha: 0.35),
                ),
              ),
              Positioned(
                bottom: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.blankScore ? '' : '${widget.displayScore}',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: fill,
                      ),
                    ),
                    if (widget.gradeLabel != null &&
                        widget.gradeLabel!.isNotEmpty)
                      Text(
                        widget.gradeLabel!,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ScoreMeterPainter extends CustomPainter {
  final double value;
  final Color fillColor;
  final Color trackColor;

  _ScoreMeterPainter({
    required this.value,
    required this.fillColor,
    required this.trackColor,
  });

  static const double _strokeWidth = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - _strokeWidth / 2);
    final radius = (size.width - _strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Half-circle from left (π) to right (0), sweeping clockwise via -π.
    const startAngle = math.pi;
    const fullSweep = -math.pi;

    canvas.drawArc(rect, startAngle, fullSweep, false, trackPaint);

    final progressPaint = Paint()
      ..color = fillColor
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      rect,
      startAngle,
      fullSweep * value.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ScoreMeterPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.trackColor != trackColor;
  }
}
