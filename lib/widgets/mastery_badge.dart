import 'package:flutter/material.dart';

import '../models/enums.dart';

class MasteryBadge extends StatelessWidget {
  final MasteryLevel masteryLevel;
  final bool expanded;

  const MasteryBadge({
    Key? key,
    required this.masteryLevel,
    this.expanded = false,
  }) : super(key: key);

  /// Compact version showing just a dot
  const MasteryBadge.compact({
    Key? key,
    required this.masteryLevel,
  })  : expanded = false,
        super(key: key);

  /// Expanded version showing dot and label
  const MasteryBadge.expanded({
    Key? key,
    required this.masteryLevel,
  })  : expanded = true,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = Color(masteryLevel.color);

    if (expanded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              masteryLevel.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      );
    }

    // Compact version - just the dot
    return Tooltip(
      message: masteryLevel.label,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
