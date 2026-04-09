import 'package:flutter/material.dart';

import '../../models/activity.dart';
import '../../theme/app_theme.dart';

class ActivityTile extends StatelessWidget {
  final Activity activity;

  const ActivityTile({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            children: [
              // Activity icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(_icon, color: _iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              // Activity details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activity.scriptureReference,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                    ),
                  ],
                ),
              ),
              // Timestamp
              Text(
                _formatTimestamp(activity.timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _icon {
    switch (activity.type) {
      case ActivityType.gameCompleted:
        return Icons.check_circle_outline;
      case ActivityType.masteryLevelUp:
        return Icons.trending_up;
      case ActivityType.streakMilestone:
        return Icons.local_fire_department;
      case ActivityType.firstAttempt:
        return Icons.flag_outlined;
      case ActivityType.perfectRun:
        return Icons.star;
    }
  }

  Color get _iconColor {
    switch (activity.type) {
      case ActivityType.gameCompleted:
        return AppTheme.secondary;
      case ActivityType.masteryLevelUp:
        return AppTheme.accent;
      case ActivityType.streakMilestone:
        return AppTheme.warning;
      case ActivityType.firstAttempt:
        return AppTheme.primary;
      case ActivityType.perfectRun:
        return AppTheme.gold;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.month}/${timestamp.day}';
  }
}
