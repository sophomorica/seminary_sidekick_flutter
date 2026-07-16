import 'package:flutter/material.dart';

import '../models/enums.dart';

/// Display-only mastery avatar badge. Renders a placeholder circle with the
/// stage icon + labels until the stage PNGs land (see
/// `assets/images/avatar_stage*.txt`).
///
/// Static by design: the results screen reveals it (fade + zoom) after the
/// score meter finishes — the badge itself does not animate.
class MasteryAvatar extends StatelessWidget {
  final AvatarStage stage;
  final double size;

  const MasteryAvatar({
    super.key,
    required this.stage,
    this.size = 88,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.surfaceContainerHighest,
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: Icon(
            stage.icon,
            size: size * 0.38,
            color: colorScheme.primary,
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
  }
}
