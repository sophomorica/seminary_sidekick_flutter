import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/scripture_provider.dart';
import '../../providers/sidekick_provider.dart';
import '../../theme/app_theme.dart';

// ─── Premium: Scripture Connections (TASK-040) ───────────────────────────────

class ScriptureConnectionsCard extends ConsumerWidget {
  final String currentScriptureId;

  const ScriptureConnectionsCard({
    super.key,
    required this.currentScriptureId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connections = ref.watch(connectionsProvider);
    if (connections.isEmpty) return const SizedBox.shrink();

    // Show the first connection relevant to this scripture (or just the first one)
    final scripture = ref.watch(scriptureByIdProvider(currentScriptureId));
    final relevant = connections.where((c) =>
        c.fromReference == scripture?.reference ||
        c.toReference == scripture?.reference);
    final toShow = relevant.isNotEmpty ? relevant.first : connections.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.link,
                      color: AppTheme.accent.withValues(alpha: 0.7), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Scripture Connection',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${toShow.fromReference}  →  ${toShow.toReference}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                toShow.insight,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
