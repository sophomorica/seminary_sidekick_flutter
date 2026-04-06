import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/scripture.dart';
import '../providers/scripture_mastery_provider.dart';
import '../providers/spaced_repetition_provider.dart';
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
    final mastery = ref.watch(scriptureMasteryProvider(scripture.id));
    final isDue = ref.watch(isScriptureDueProvider(scripture.id));
    final srData = ref.watch(spacedRepetitionDataProvider(scripture.id));

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
                  MasteryBadge.compact(
                    masteryLevel: mastery.level,
                    needsReview: mastery.needsReview,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Key phrase preview
              Text(
                scripture.keyPhrase,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                      height: 1.4,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Word count and review due indicator
              Row(
                children: [
                  Text(
                    '${scripture.wordCount} words',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  if (isDue && srData != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.refresh,
                            size: 12,
                            color: AppTheme.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            srData.daysOverdue > 0
                                ? '${srData.daysOverdue}d overdue'
                                : 'Review today',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppTheme.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
