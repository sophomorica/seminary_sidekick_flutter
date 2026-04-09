import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/journal_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_teaser.dart';
import 'journal_list_view.dart';

// ─── Empty State ────────────────────────────────────────────────────────────

class EmptyJournalView extends ConsumerWidget {
  const EmptyJournalView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prompts = ref.watch(currentReflectionPromptsProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Your journal is empty',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Capture your thoughts, insights, and reflections as you study.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (prompts.isNotEmpty) ...[
              Text(
                'Start with a prompt from your Sidekick:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.premiumGold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
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

class FreeUserJournalView extends StatelessWidget {
  const FreeUserJournalView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.premiumGold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.book,
                size: 40,
                color: AppTheme.premiumGold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Seminary Sidekick Journal',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Capture your insights with AI-powered reflection prompts, '
              'scripture tagging, and personalized journal entries.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
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
