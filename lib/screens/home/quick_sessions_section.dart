import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../navigation/fullscreen.dart';
import '../../providers/sidekick_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/scripture_reference_resolver.dart';
import '../journal/journal_screen.dart';

// ─── Engagement: "Got a Minute?" Quick Sessions (TASK-040) ───────────────────

class QuickSessionsSection extends ConsumerWidget {
  const QuickSessionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prompts = ref.watch(quickSessionPromptsProvider);
    if (prompts.isEmpty) return const SizedBox.shrink();

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
              const Icon(Icons.bolt, color: AppTheme.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Got a minute?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...prompts.take(3).map((prompt) => _QuickSessionTile(prompt: prompt)),
        ],
      ),
    );
  }
}

class _QuickSessionTile extends ConsumerWidget {
  final QuickSessionPrompt prompt;

  const _QuickSessionTile({required this.prompt});

  IconData _iconForAction(String actionType) {
    switch (actionType) {
      case 'scriptureBuilder':
        return Icons.sort_by_alpha;
      case 'review':
        return Icons.refresh;
      case 'reflect':
        return Icons.edit_note;
      case 'quiz':
        return Icons.quiz;
      default:
        return Icons.play_arrow;
    }
  }

  Color _colorForAction(BuildContext context, String actionType) {
    switch (actionType) {
      case 'scriptureBuilder':
        return Theme.of(context).colorScheme.primary;
      case 'review':
        return AppTheme.warning;
      case 'reflect':
        return AppTheme.sidekickColor(context);
      case 'quiz':
        return AppTheme.secondary;
      default:
        return AppTheme.accent;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _colorForAction(context, prompt.actionType);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () {
          if (prompt.actionType == 'reflect') {
            pushFullscreen(
              context,
              JournalScreen(initialPrompt: prompt.subtitle),
            );
          } else {
            final scriptureId = resolveScriptureId(
              scriptureId: prompt.scriptureId,
              suggestionText: prompt.subtitle,
            );
            if (scriptureId != null) {
              context.push('/scripture/$scriptureId');
            }
          }
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  _iconForAction(prompt.actionType),
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prompt.title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      prompt.subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
}
