import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Fixed-size selection control shared by filter chips, count pills, and
/// difficulty pills. Selected = hero gradient (light) / lifted blue (Midnight);
/// unselected = quiet surface; disabled = further dimmed. No layout shift.
class SelectionPill extends StatelessWidget {
  static const double height = 44;
  static const double _radius = AppTheme.radiusMd;

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const SelectionPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showSelected = selected && enabled;
    final Color borderColor;
    final Color labelColor;
    if (!enabled) {
      borderColor = colorScheme.outlineVariant.withValues(alpha: 0.5);
      labelColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.38);
    } else if (showSelected) {
      borderColor = Colors.transparent;
      labelColor = colorScheme.onPrimary;
    } else {
      borderColor = colorScheme.outlineVariant;
      labelColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.8);
    }

    return Semantics(
      button: true,
      selected: showSelected,
      enabled: enabled,
      label: label,
      child: SizedBox(
        height: height,
        child: Container(
          decoration: BoxDecoration(
            gradient: showSelected
                ? AppTheme.selectedChipGradient(context)
                : null,
            color: showSelected ? null : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: borderColor),
            boxShadow: showSelected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : const [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? onTap : null,
              borderRadius: BorderRadius.circular(_radius),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: labelColor,
                          fontWeight:
                              showSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
