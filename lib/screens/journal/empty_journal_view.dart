import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/journal_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_teaser.dart';
import 'journal_list_view.dart';

// ─── Empty State ────────────────────────────────────────────────────────────
/// Sacred Editorial empty state with warm, inviting design.

class EmptyJournalView extends ConsumerWidget {
  const EmptyJournalView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prompts = ref.watch(currentReflectionPromptsProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.15),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'Begin Your Reflection',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Capture your insights and spiritual experiences as you study the scriptures.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                    height: 1.6,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXl),
            if (prompts.isNotEmpty) ...[
              Text(
                'Start with a reflection prompt from your Seminary Sidekick:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.sidekickColor(context)
                          .withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              ReflectionPromptCard(
                prompt: prompts.first,
                onReflect: () {
                  ref
                      .read(journalProvider.notifier)
                      .createEntry(prompt: prompts.first);
                },
              ),
            ] else
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(journalProvider.notifier).createEntry();
                },
                icon: const Icon(Icons.add),
                label: const Text('Start Writing'),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Free User View ─────────────────────────────────────────────────────────
/// Premium upgrade teaser for non-premium users with Sacred Editorial aesthetic.

class FreeUserJournalView extends StatelessWidget {
  const FreeUserJournalView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.sidekickColor(context)
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.book,
                size: 40,
                color: AppTheme.sidekickColor(context),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            Text(
              'Seminary Sidekick Journal',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Capture your insights with AI-powered reflection prompts, scripture tagging, and personalized journal entries.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.65),
                    height: 1.6,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXl),
            const PremiumTeaser(
              headline: 'Unlock your journal',
              body:
                  'Premium members get AI reflection prompts and scripture-tagged journaling.',
              icon: Icons.book,
            ),
          ],
        ),
      ),
    );
  }
}
