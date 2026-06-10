import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// Slim banner shown while any group-play realtime channel is down and
/// auto-retrying (see `GroupPlayService.reconnecting`).
///
/// Purely informational — the service resubscribes with exponential backoff
/// and refetches whatever was missed, so there's no action for the user to
/// take. Keep it calm: no red, no alarm icon. Classroom wifi blips are
/// routine and self-healing.
class ReconnectingBanner extends StatelessWidget {
  const ReconnectingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: 8,
      ),
      color: AppTheme.gold.withValues(alpha: 0.16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'Connection hiccup — reconnecting…',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
