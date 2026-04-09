import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/sidekick_provider.dart';
import '../../theme/app_theme.dart';

// ─── Premium: Encouragement Card (TASK-040) ──────────────────────────────────

class EncouragementCard extends ConsumerWidget {
  const EncouragementCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final encouragement = ref.watch(encouragementProvider);
    if (encouragement == null || encouragement.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        color: AppTheme.sidekickTint(context, 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: BorderSide(
            color: AppTheme.sidekickColor(context).withValues(alpha: 0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              Icon(Icons.auto_awesome,
                  color: AppTheme.sidekickColor(context), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  encouragement,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
