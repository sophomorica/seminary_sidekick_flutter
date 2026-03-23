import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/scripture.dart';
import '../models/enums.dart';
import '../providers/progress_provider.dart';
import '../theme/app_theme.dart';
import 'mastery_badge.dart';

class ScriptureCard extends ConsumerWidget {
  final Scripture scripture;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const ScriptureCard({
    super.key,
    required this.scripture,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get highest mastery level across all game types
    MasteryLevel highestMastery = MasteryLevel.newScripture;
    for (final gameType in GameType.values) {
      final mastery = ref.watch(
        masteryLevelProvider((scripture.id, gameType)),
      );
      if (_getMasteryRank(mastery) > _getMasteryRank(highestMastery)) {
        highestMastery = mastery;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: padding ?? const EdgeInsets.symmetric(vertical: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reference and mastery badge row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scripture.reference,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          scripture.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  MasteryBadge.compact(masteryLevel: highestMastery),
                ],
              ),
              const SizedBox(height: 12),

              // Key phrase preview
              Text(
                scripture.keyPhrase,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Word count indicator
              Text(
                '${scripture.wordCount} words',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getMasteryRank(MasteryLevel level) {
    switch (level) {
      case MasteryLevel.newScripture:
        return 0;
      case MasteryLevel.learning:
        return 1;
      case MasteryLevel.familiar:
        return 2;
      case MasteryLevel.memorized:
        return 3;
      case MasteryLevel.mastered:
        return 4;
    }
  }
}
