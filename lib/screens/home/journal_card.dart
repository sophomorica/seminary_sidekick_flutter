import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../navigation/fullscreen.dart';
import '../../providers/journal_provider.dart';
import '../../providers/sidekick_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/haptic_service.dart';
import '../../theme/app_theme.dart';
import '../journal/journal_screen.dart';

/// Always-present journal card on the Home screen (TASK-066).
///
/// This is the journal's primary, persistent entry point in the app.
/// Premium users see today's reflection prompt (when the Sidekick has one)
/// plus a pick-up-where-you-left-off line for their latest entry.
/// Free users see the same card as a premium teaser — always visible,
/// never rate-limited or dismissible, because it's a stable Home surface
/// (marketing the journal beats hiding it).
class JournalCard extends ConsumerWidget {
  const JournalCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    return isPremium
        ? const _PremiumJournalCard()
        : const _LockedJournalCard();
  }
}

// ─── Premium: prompt + continue writing ─────────────────────────────────────

class _PremiumJournalCard extends ConsumerWidget {
  const _PremiumJournalCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prompts = ref.watch(reflectionPromptsProvider);
    final entries = ref.watch(journalEntriesProvider);

    final prompt = prompts.isNotEmpty ? prompts.first : null;
    final latest = entries.isNotEmpty ? entries.first : null;

    return _JournalCardShell(
      onTap: () {
        ref.read(hapticProvider).light();
        context.push('/journal');
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today's prompt (italic serif) or evergreen invitation.
          Text(
            prompt ?? 'What did you notice in your study today?',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: 'Merriweather',
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
          ),
          if (latest != null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Row(
              children: [
                Icon(
                  Icons.history_edu,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Last entry: ${latest.title.isNotEmpty ? latest.title : latest.preview}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppTheme.spacingMd),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ref.read(hapticProvider).light();
                pushFullscreen(
                  context,
                  JournalScreen(initialPrompt: prompt),
                );
              },
              icon: const Icon(Icons.edit_note, size: 20),
              label: Text(
                prompt != null ? 'Reflect on this' : 'Write in your journal',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.premiumGold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Free: locked teaser (always present, not dismissible) ──────────────────

class _LockedJournalCard extends ConsumerWidget {
  const _LockedJournalCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _JournalCardShell(
      trailing: Icon(
        Icons.lock_outline,
        size: 18,
        color: AppTheme.sidekickColor(context),
      ),
      onTap: () {
        ref.read(hapticProvider).light();
        pushUpgrade(context);
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Record what you learn — with a Sidekick that asks the right questions.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: 'Merriweather',
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Daily reflection prompts, voice-to-text, and insights saved from your Sidekick chats.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(hapticProvider).light();
                pushUpgrade(context);
              },
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: Text(
                'Unlock with Premium',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.sidekickColor(context),
                    ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.sidekickColor(context),
                side: BorderSide(
                  color: AppTheme.sidekickColor(context).withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared shell (gold journal framing) ────────────────────────────────────

class _JournalCardShell extends StatelessWidget {
  final Widget body;
  final Widget? trailing;
  final VoidCallback onTap;

  const _JournalCardShell({
    required this.body,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppTheme.sidekickColor(context).withValues(alpha: 0.14),
                    AppTheme.sidekickColor(context).withValues(alpha: 0.06),
                  ]
                : [
                    AppTheme.premiumGoldLight.withValues(alpha: 0.55),
                    AppTheme.premiumGoldLight.withValues(alpha: 0.25),
                  ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(
            color: AppTheme.sidekickColor(context).withValues(alpha: 0.35),
            width: 0.5,
          ),
          boxShadow: AppTheme.editorialShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  size: 20,
                  color: AppTheme.sidekickColor(context),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    'ACQUIRING SPIRITUAL KNOWLEDGE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.sidekickColor(context),
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            body,
          ],
        ),
      ),
    );
  }
}
