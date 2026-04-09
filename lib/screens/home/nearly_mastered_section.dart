import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/enums.dart';
import '../../providers/sidekick_provider.dart';
import '../../theme/app_theme.dart';

// ─── Engagement: Nearly Mastered Nudges (TASK-040) ───────────────────────────

class NearlyMasteredNudges extends ConsumerWidget {
  const NearlyMasteredNudges({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearlyMastered = ref.watch(nearlyMasteredScripturesProvider);
    if (nearlyMastered.isEmpty) return const SizedBox.shrink();

    // Show up to 2 nudge cards
    final toShow = nearlyMastered.take(2).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up,
                  color: AppTheme.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Almost there',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...toShow.map((info) => _NearlyMasteredTile(info: info)),
        ],
      ),
    );
  }
}

class _NearlyMasteredTile extends StatelessWidget {
  final NearlyMasteredInfo info;

  const _NearlyMasteredTile({required this.info});

  @override
  Widget build(BuildContext context) {
    final color = Color(info.level.color);
    final progressPct = (info.subProgress * 100).toInt();

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () {
          context.push('/scripture/${info.id}');
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Progress ring
              SizedBox(
                width: 36,
                height: 36,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: info.subProgress,
                      strokeWidth: 3,
                      backgroundColor: color.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                    Icon(info.level.icon, size: 16, color: color),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.reference,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$progressPct% to ${_nextLevelLabel(info.level)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: color,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: color.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  String _nextLevelLabel(MasteryLevel level) {
    switch (level) {
      case MasteryLevel.newScripture:
        return 'Learning';
      case MasteryLevel.learning:
        return 'Familiar';
      case MasteryLevel.familiar:
        return 'Memorized';
      case MasteryLevel.memorized:
        return 'Mastered';
      case MasteryLevel.mastered:
        return 'Eternal';
      case MasteryLevel.eternal:
        return 'Eternal';
    }
  }
}
