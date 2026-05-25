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
                        color: AppTheme.primary,
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
                const _SectionDivider(label: 'Or start fresh'),
                const SizedBox(height: AppTheme.spacingMd),
              ] else if (stats.attempted > 0) ...[
                _buildAllCaughtUpCard(context),
                const SizedBox(height: AppTheme.spacingXl),
              ],

              // ─── "Let's Learn / Let's Play" tiles ─────────────────────
              _buildImageNavigationCard(
                context,
                title: "Let's Learn",
                description: 'Study scripture and build mastery.',
                overlayColor: AppTheme.secondary,
                icon: Icons.menu_book,
                imagePath: 'assets/images/browse_scriptures.jpg',
                onTap: () => context.go('/library'),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _buildImageNavigationCard(
                context,
                title: "Let's Play",
                description: 'Quizzes, scripture match, and Scripture Builder.',
                overlayColor: AppTheme.primary,
                icon: Icons.extension,
                imagePath: 'assets/images/practice_games.jpg',
                onTap: () => context.go('/practice'),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              // Group Play entry — host or join with friends.
              // Tapping defaults to Join (the most common student flow:
              // "my friend just sent me a code"). Hosts go through the
              // Practice Hub's Group Play card instead.
              _buildPlayWithFriendsTile(context),

              // ─── Premium Quick Win — demoted below primary CTAs ───────
              if (isPremium && sidekickResponse?.quickWin != null) ...[
                const SizedBox(height: AppTheme.spacingXl),
                _buildQuickWinCard(
                  context,
                  sidekickResponse!.quickWin!,
                  onTap: () {
                    if (sidekickResponse.quickWin!.scriptureId != null) {
                      context.push(
                        '/scripture/${sidekickResponse.quickWin!.scriptureId}',
                      );
                    }
                  },
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
                                _masteryHintFor(mastery.level,
                                    target.isReviewNudge),
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
                Icons.smart_toy,
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

  /// Image-overlay navigation card for the two primary "Let's Learn / Let's Play" tiles.
  Widget _buildImageNavigationCard(
    BuildContext context, {
    required String title,
    required String description,
    required Color overlayColor,
    required IconData icon,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 168, // reduced from 240 so resume card has visual primacy
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33221A17),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
            Container(color: overlayColor.withValues(alpha: 0.80)),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontFamily: 'Merriweather',
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                              letterSpacing: 0.2,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Play with Friends" tile — entry to Group Play.
  ///
  /// Defaults to the Join screen because the most common student flow is
  /// "my friend texted me a code." Hosts launch new rooms from the Practice
  /// Hub's Group Play card, which has both Host and Join buttons.
  ///
  /// Uses a gradient (not an image) so we don't need a new asset to ship —
  /// the kid-attractive icon + warm gradient carries the visual weight.
  Widget _buildPlayWithFriendsTile(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/group-play/join'),
      child: Container(
        height: 168,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.tertiary, AppTheme.secondary],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33221A17),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.groups, color: Colors.white, size: 28),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'NEW',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            fontSize: 10,
                          ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Play with Friends',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontFamily: 'Merriweather',
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Join a class quiz with a 4-letter code.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 0.2,
                        ),
                  ),
                ],
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

/// "Or start fresh" / similar quiet section divider.
class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
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
          color = AppTheme.primary;
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
