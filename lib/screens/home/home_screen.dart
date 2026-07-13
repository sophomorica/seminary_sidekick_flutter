import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/enums.dart';
import '../../models/sidekick_response.dart';
import '../../providers/resume_target_provider.dart';
import '../../providers/scripture_mastery_provider.dart';
import '../../providers/sidekick_provider.dart';
import '../../providers/spaced_repetition_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/user_preferences_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/scripture_reference_resolver.dart';
import '../../widgets/game_setup_sheet.dart';
import '../../widgets/group_play_card.dart';
import 'journal_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Time-of-day greeting.
  static String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  /// Friendly relative-time label for "X days/hours ago".
  static String _timeAgoLabel(DateTime then) {
    final delta = DateTime.now().difference(then);
    if (delta.inMinutes < 1) return 'Just now';
    if (delta.inHours < 1) return '${delta.inMinutes}m ago';
    if (delta.inHours < 24) return '${delta.inHours}h ago';
    if (delta.inDays == 1) return 'Yesterday';
    if (delta.inDays < 7) return '${delta.inDays} days ago';
    return '${(delta.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    final sidekickResponse = ref.watch(sidekickResponseProvider);
    final greetingName = ref.watch(greetingNameProvider);
    final resumeTarget = ref.watch(resumeTargetProvider);
    final stats = ref.watch(holisticStatsProvider);
    ref.watch(dueCountProvider); // warm cache for badges elsewhere

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 16.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Dynamic Greeting ─────────────────────────────────────
              if (isPremium && sidekickResponse?.dailyPrompt != null) ...[
                Text(
                  sidekickResponse!.dailyPrompt!,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ] else ...[
                Text(
                  _timeGreeting(),
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                Text(
                  greetingName,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],

              const SizedBox(height: AppTheme.spacingXl),

              // ─── Resume card OR all-caught-up nudge ───────────────────
              if (resumeTarget != null) ...[
                _ResumeEyebrow(isReviewNudge: resumeTarget.isReviewNudge),
                const SizedBox(height: AppTheme.spacingSm),
                _buildResumeCard(context, ref, resumeTarget),
                const SizedBox(height: AppTheme.spacingXl),
              ] else if (stats.attempted > 0) ...[
                _buildAllCaughtUpCard(context),
                const SizedBox(height: AppTheme.spacingXl),
              ],

              // ─── Let's play — one-tap into any game ───────────────────
              const _HomeEyebrow("Let's play"),
              const SizedBox(height: AppTheme.spacingSm),
              Row(
                children: [
                  Expanded(
                    child: _buildGameChip(
                      context,
                      label: 'Builder',
                      icon: Icons.construction,
                      color: Theme.of(context).colorScheme.primary,
                      onTap: () => showGameSetupSheet(
                        context,
                        gameType: GameType.scriptureBuilder,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: _buildGameChip(
                      context,
                      label: 'Match',
                      icon: Icons.layers,
                      color: AppTheme.secondary,
                      onTap: () => showGameSetupSheet(
                        context,
                        gameType: GameType.matching,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: _buildGameChip(
                      context,
                      label: 'Quiz',
                      icon: Icons.quiz,
                      color: AppTheme.accent,
                      onTap: () => showGameSetupSheet(
                        context,
                        gameType: GameType.quiz,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              // Group Play — the one entry point. Host or join in one card.
              const GroupPlayCard(showNewFlag: true),
              const SizedBox(height: AppTheme.spacingXl),

              // ─── Let's learn — browse the library ─────────────────────
              const _HomeEyebrow("Let's learn"),
              const SizedBox(height: AppTheme.spacingSm),
              _buildBrowseTile(context),
              const SizedBox(height: AppTheme.spacingXl),

              // ─── Let's reflect — journal, always present (TASK-066) ───
              const _HomeEyebrow("Let's reflect"),
              const SizedBox(height: AppTheme.spacingSm),
              const JournalCard(),

              // ─── Premium Quick Win — demoted below primary CTAs ───────
              if (isPremium && sidekickResponse?.quickWin != null) ...[
                const SizedBox(height: AppTheme.spacingXl),
                _buildQuickWinCard(
                  context,
                  sidekickResponse!.quickWin!,
                  onTap: () => _handleQuickWinTap(
                    context,
                    sidekickResponse.quickWin!,
                  ),
                ),
              ],

              const SizedBox(height: 120.0),
            ],
          ),
        ),
      ),
    );
  }

  /// Resume card — the "Pick up where you left off" hero.
  ///
  /// Surfaces the most relevant non-mastered scripture (needs-review first,
  /// then most-recently-practiced).
  Widget _buildResumeCard(
    BuildContext context,
    WidgetRef ref,
    ResumeTarget target,
  ) {
    final scripture = target.scripture;
    final mastery = ref.watch(scriptureMasteryProvider(scripture.id));
    final bookColor = AppTheme.bookColor(scripture.book.displayName);

    return GestureDetector(
      onTap: () => context.push('/scripture/${scripture.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
          boxShadow: AppTheme.editorialShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Book-color stripe
                Container(width: 5.0, color: bookColor),
                // Body
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingMd,
                      AppTheme.spacingMd,
                      AppTheme.spacingMd,
                      AppTheme.spacingMd,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Volume / book label
                        Row(
                          children: [
                            Text(
                              scripture.book.displayName.toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: bookColor,
                                    letterSpacing: 0.8,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            if (target.lastPracticed != null) ...[
                              Text(
                                '  ·  ',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                              Text(
                                _timeAgoLabel(target.lastPracticed!)
                                    .toUpperCase(),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      letterSpacing: 0.8,
                                    ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6.0),
                        // Reference
                        Text(
                          scripture.reference,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontFamily: 'Merriweather',
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 6.0),
                        // Key phrase
                        Text(
                          '"${scripture.keyPhrase}"',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                fontFamily: 'Merriweather',
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                height: 1.5,
                              ),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        // Mastery pips + level label
                        Row(
                          children: [
                            _MasteryPips(level: mastery.level),
                            const SizedBox(width: AppTheme.spacingSm),
                            Expanded(
                              child: Text(
                                // Eyebrow above the card already says "Time for
                                // a refresher" on review nudges, so the inner
                                // row always shows mastery progress instead.
                                _masteryHintFor(mastery.level, false),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      letterSpacing: 0.3,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        // Continue button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                context.push('/scripture/${scripture.id}'),
                            icon: const Icon(Icons.play_arrow_rounded,
                                size: 18.0),
                            label: Text(
                              target.isReviewNudge
                                  ? 'Refresh this scripture'
                                  : 'Continue practice',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusRound),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// "All caught up" celebration shown when the user has practiced something
  /// but every touched scripture has reached Mastered or Eternal.
  Widget _buildAllCaughtUpCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.5,
        ),
        boxShadow: AppTheme.editorialShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44.0,
            height: 44.0,
            decoration: BoxDecoration(
              color: AppTheme.premiumGoldLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusRound),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: AppTheme.premiumGold,
              size: 24.0,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Everything you've started is mastered.",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFamily: 'Merriweather',
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'Pick a new scripture or jump into a quick practice round.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Navigates to the scripture named in a Quick Win suggestion.
  ///
  /// Uses the explicit [QuickWin.scriptureId] when valid; otherwise parses the
  /// suggestion text (e.g. "Review Alma 39:9") for a tappable reference.
  static void _handleQuickWinTap(BuildContext context, QuickWin quickWin) {
    final scriptureId = resolveScriptureId(
      scriptureId: quickWin.scriptureId,
      suggestionText: quickWin.suggestion,
    );
    if (scriptureId != null) {
      context.push('/scripture/$scriptureId');
    }
  }

  /// Quick Win card — AI-generated nudge from the Sidekick. Premium-only.
  ///
  /// Uses the brand accent blue (#5B8ABF) — the same color already used for
  /// tappable scripture references in chat. Reads as "smart / Sidekick" and
  /// stays visually distinct from the rust + sage tiles directly above.
  Widget _buildQuickWinCard(
    BuildContext context,
    QuickWin quickWin, {
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: AppTheme.accent.withValues(alpha: 0.32),
          width: 0.5,
        ),
        boxShadow: AppTheme.editorialShadow,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.explore,
                color: AppTheme.accent,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Text(
                  "TODAY'S QUICK WIN",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.accent,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            quickWin.suggestion,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  fontFamily: 'Merriweather',
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Tap below to continue your practice with this scripture.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
              child: Text(
                'Practice Now',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A compact one-tap game chip. Opens the unified [GameSetupSheet] so a kid
  /// can start a game from Home without going through the Practice Hub.
  Widget _buildGameChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 0.5,
            ),
            boxShadow: AppTheme.editorialShadow,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8.0),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Browse all scriptures" tile — entry to the library / study path.
  Widget _buildBrowseTile(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        onTap: () => context.go('/library'),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 0.5,
            ),
            boxShadow: AppTheme.editorialShadow,
          ),
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(
                  Icons.menu_book,
                  color: AppTheme.secondary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Browse all scriptures',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontFamily: 'Merriweather',
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      'Study the text and build mastery',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              Icon(
                Icons.chevron_right,
                size: 22,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Short hint string for the resume card mastery row.
  String _masteryHintFor(MasteryLevel level, bool isReviewNudge) {
    if (isReviewNudge) {
      return 'Time for a refresher';
    }
    switch (level) {
      case MasteryLevel.newScripture:
        return 'Just getting started';
      case MasteryLevel.learning:
        return 'Learning · pushing for Familiar';
      case MasteryLevel.familiar:
        return 'Familiar · pushing for Memorized';
      case MasteryLevel.memorized:
        return 'Memorized · pushing for Mastered';
      case MasteryLevel.mastered:
      case MasteryLevel.eternal:
        return ''; // never reached — filtered upstream
    }
  }
}

/// Small uppercase eyebrow above the resume card.
class _ResumeEyebrow extends StatelessWidget {
  final bool isReviewNudge;
  const _ResumeEyebrow({required this.isReviewNudge});

  @override
  Widget build(BuildContext context) {
    return Text(
      isReviewNudge
          ? 'Time for a refresher'
          : 'Pick up where you left off',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

/// Section eyebrow used above the Home "Let's play" / "Let's learn" groups.
class _HomeEyebrow extends StatelessWidget {
  final String label;
  const _HomeEyebrow(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontFamily: 'Merriweather',
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
          ),
    );
  }
}

/// Six-dot mastery path indicator.
///
/// Shows the user's position on the linear mastery path:
///   newScripture → learning → familiar → memorized → mastered → eternal
/// Filled dots: levels already reached.
/// Highlighted dot: the next level to push for.
class _MasteryPips extends StatelessWidget {
  final MasteryLevel level;
  const _MasteryPips({required this.level});

  @override
  Widget build(BuildContext context) {
    const total = 6;
    final reached = level.index; // 0..5 — number of filled pips
    final next = reached < total ? reached : -1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final Color color;
        if (i < reached) {
          color = AppTheme.secondary;
        } else if (i == next) {
          color = Theme.of(context).colorScheme.primary;
        } else {
          color = Theme.of(context).colorScheme.surfaceContainerHighest;
        }
        return Padding(
          padding: const EdgeInsets.only(right: 4.0),
          child: Container(
            width: 8.0,
            height: 8.0,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppTheme.radiusRound),
            ),
          ),
        );
      }),
    );
  }
}
