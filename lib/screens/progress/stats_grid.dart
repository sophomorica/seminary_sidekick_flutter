import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../providers/scripture_mastery_provider.dart';
import '../../theme/app_theme.dart';

class StatsGrid extends StatelessWidget {
  final HolisticStats stats;

  const StatsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _StatTile(
          label: 'Attempted',
          value: stats.attempted.toString(),
          icon: Icons.note_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        _StatTile(
          label: 'Memorized',
          value: stats.memorized.toString(),
          icon: Icons.check_circle_outline,
          color: AppTheme.secondary,
        ),
        _StatTile(
          label: 'Mastered',
          value: '${stats.mastered + stats.eternal}',
          icon: Icons.workspace_premium,
          color: Color(MasteryLevel.mastered.color),
        ),
        _StatTile(
          label: stats.eternal > 0 ? 'Eternal' : 'Need Review',
          value: stats.eternal > 0
              ? stats.eternal.toString()
              : stats.needsReview.toString(),
          icon: stats.eternal > 0 ? Icons.auto_awesome : Icons.schedule,
          color: stats.eternal > 0
              ? Color(MasteryLevel.eternal.color)
              : AppTheme.warning,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
