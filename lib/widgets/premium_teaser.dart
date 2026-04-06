import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/subscription_provider.dart';
import '../screens/upgrade_screen.dart';
import '../theme/app_theme.dart';

/// A compact, dismissible card that teases premium features at natural moments.
///
/// Use this after mastery wins, on scripture detail, or wherever a gentle
/// nudge feels appropriate. Respects the rate-limiting in [SubscriptionState].
///
/// Example usage:
/// ```dart
/// if (ref.watch(canShowUpgradePromptProvider)) {
///   PremiumTeaser(
///     headline: 'Want to go deeper?',
///     body: 'Your Seminary Sidekick can help you understand and apply this passage.',
///     context: PremiumTeaserContext.scriptureDetail,
///   );
/// }
/// ```
class PremiumTeaser extends ConsumerWidget {
  /// Short attention-grabbing headline.
  final String headline;

  /// One-line description of the value.
  final String body;

  /// Icon to display (defaults to auto_awesome).
  final IconData icon;

  /// Called when dismissed — provider handles rate limiting automatically.
  final VoidCallback? onDismissed;

  const PremiumTeaser({
    super.key,
    required this.headline,
    required this.body,
    this.icon = Icons.auto_awesome,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    if (isPremium) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: GestureDetector(
        onTap: () => _openUpgrade(context),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppTheme.premiumGold.withValues(alpha: 0.12),
                      AppTheme.premiumGold.withValues(alpha: 0.06),
                    ]
                  : [
                      AppTheme.premiumGoldLight.withValues(alpha: 0.5),
                      AppTheme.premiumGoldLight.withValues(alpha: 0.25),
                    ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: AppTheme.premiumGold.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.premiumGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(icon, color: AppTheme.premiumGold, size: 20),
              ),

              const SizedBox(width: AppTheme.spacingMd),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      headline,
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.premiumGold,
                              ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppTheme.spacingSm),

              // Dismiss button
              GestureDetector(
                onTap: () {
                  ref
                      .read(subscriptionProvider.notifier)
                      .dismissUpgradePrompt();
                  onDismissed?.call();
                },
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openUpgrade(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UpgradeScreen()),
    );
  }
}

/// A subtle inline text link for premium features — even less intrusive
/// than [PremiumTeaser]. Use inside existing UI sections.
///
/// Example: "Ask your Sidekick about this verse →"
class PremiumInlineLink extends ConsumerWidget {
  final String text;
  final IconData? icon;

  const PremiumInlineLink({
    super.key,
    required this.text,
    this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    if (isPremium) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const UpgradeScreen()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppTheme.premiumGold),
              const SizedBox(width: 6),
            ],
            Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.premiumGold,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_forward_ios,
              size: 10,
              color: AppTheme.premiumGold,
            ),
          ],
        ),
      ),
    );
  }
}

/// A premium feature gate — shows content for premium users, or a teaser
/// for free users.
class PremiumGate extends ConsumerWidget {
  /// The premium-only widget to show.
  final Widget premiumChild;

  /// Teaser headline for free users.
  final String teaserHeadline;

  /// Teaser body for free users.
  final String teaserBody;

  const PremiumGate({
    super.key,
    required this.premiumChild,
    required this.teaserHeadline,
    required this.teaserBody,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);

    if (isPremium) return premiumChild;

    return PremiumTeaser(
      headline: teaserHeadline,
      body: teaserBody,
    );
  }
}
