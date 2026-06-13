import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/subscription_provider.dart';
import '../theme/app_theme.dart';

/// Full-screen upgrade experience showing the Seminary Sidekick value
/// proposition and plan options.
class UpgradeScreen extends ConsumerWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: subscription.isPremium
            ? _AlreadyPremiumView(subscription: subscription)
            : _UpgradeView(
                subscription: subscription,
                isDark: isDark,
                ref: ref,
              ),
      ),
    );
  }
}

// ─── Already Premium ────────────────────────────────────────────────────────

class _AlreadyPremiumView extends StatelessWidget {
  final SubscriptionState subscription;
  const _AlreadyPremiumView({required this.subscription});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    AppTheme.premiumGradientStart,
                    AppTheme.premiumGradientEnd,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.premiumGold.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'You\'re a Sidekick Member',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              subscription.activePlan != null
                  ? '${subscription.activePlan!.label} plan'
                  : 'Premium active',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.premiumGold,
                  ),
            ),
            if (subscription.expiresAt != null) ...[
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                'Renews ${_formatDate(subscription.expiresAt!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: AppTheme.spacingXl),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ─── Upgrade View ───────────────────────────────────────────────────────────

class _UpgradeView extends StatefulWidget {
  final SubscriptionState subscription;
  final bool isDark;
  final WidgetRef ref;

  const _UpgradeView({
    required this.subscription,
    required this.isDark,
    required this.ref,
  });

  @override
  State<_UpgradeView> createState() => _UpgradeViewState();
}

class _UpgradeViewState extends State<_UpgradeView> {
  PremiumPlan _selectedPlan = PremiumPlan.yearly;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Close button
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
            child: Column(
              children: [
                const SizedBox(height: AppTheme.spacingSm),

                // Premium icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.premiumGradientStart,
                        AppTheme.premiumGradientEnd,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.premiumGold.withValues(alpha: 0.25),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 36,
                  ),
                ),

                const SizedBox(height: AppTheme.spacingLg),

                // Headline
                Text(
                  'Meet Your\nSeminary Sidekick',
                  style: Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppTheme.spacingSm),

                Text(
                  'Go from memorization to true understanding',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppTheme.spacingXl),

                // Features list
                _FeatureItem(
                  icon: Icons.psychology,
                  title: 'AI Study Companion',
                  description:
                      'A personal tutor that knows your progress and helps you understand, not just memorize.',
                  isDark: widget.isDark,
                ),
                _FeatureItem(
                  icon: Icons.edit_note,
                  title: 'Scripture Journal',
                  description:
                      'Guided reflection prompts that deepen your connection to each passage.',
                  isDark: widget.isDark,
                ),
                _FeatureItem(
                  icon: Icons.track_changes,
                  title: 'Smart Goals & Reminders',
                  description:
                      'Personalized study plans that fit your schedule and pace.',
                  isDark: widget.isDark,
                ),
                _FeatureItem(
                  icon: Icons.hub,
                  title: 'Deep Study Tools',
                  description:
                      'Cross-references, historical context, and doctrinal connections.',
                  isDark: widget.isDark,
                ),

                const SizedBox(height: AppTheme.spacingXl),

                // Plan selection
                _PlanCard(
                  plan: PremiumPlan.yearly,
                  priceLabel: widget.subscription.priceFor(PremiumPlan.yearly),
                  isSelected: _selectedPlan == PremiumPlan.yearly,
                  isDark: widget.isDark,
                  onTap: () => setState(() => _selectedPlan = PremiumPlan.yearly),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                _PlanCard(
                  plan: PremiumPlan.monthly,
                  priceLabel: widget.subscription.priceFor(PremiumPlan.monthly),
                  isSelected: _selectedPlan == PremiumPlan.monthly,
                  isDark: widget.isDark,
                  onTap: () => setState(() => _selectedPlan = PremiumPlan.monthly),
                ),

                const SizedBox(height: AppTheme.spacingLg),

                // Subscribe button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.subscription.isLoading
                        ? null
                        : () => _handlePurchase(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.premiumGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: widget.subscription.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Start Free Trial',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(color: Colors.white),
                          ),
                  ),
                ),

                const SizedBox(height: AppTheme.spacingSm),

                // Restore purchases
                TextButton(
                  onPressed: () {
                    widget.ref
                        .read(subscriptionProvider.notifier)
                        .restorePurchases();
                  },
                  child: Text(
                    'Restore Purchases',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          decoration: TextDecoration.underline,
                        ),
                  ),
                ),

                // Error message
                if (widget.subscription.error != null) ...[
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    widget.subscription.error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.error,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: AppTheme.spacingMd),

                // Legal fine print
                Text(
                  'Cancel anytime. Payment charged through your App Store account.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppTheme.spacingXl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handlePurchase(BuildContext context) async {
    final success = await widget.ref
        .read(subscriptionProvider.notifier)
        .purchasePlan(_selectedPlan);

    if (success && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

// ─── Feature Item ───────────────────────────────────────────────────────────

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isDark;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.premiumGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, color: AppTheme.premiumGold, size: 22),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Plan Card ──────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final PremiumPlan plan;

  /// Resolved price to display — the live localized store price when
  /// RevenueCat offerings have loaded, otherwise the hardcoded fallback.
  final String priceLabel;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.priceLabel,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isSelected ? AppTheme.premiumGold : Colors.grey.withValues(alpha: 0.3);
    final bgColor = isSelected
        ? AppTheme.premiumGold.withValues(alpha: isDark ? 0.12 : 0.06)
        : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.premiumGold : Colors.grey,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.premiumGold,
                        ),
                      ),
                    )
                  : null,
            ),

            const SizedBox(width: AppTheme.spacingMd),

            // Plan details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan.label,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      if (plan.savings != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.premiumGold,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusRound),
                          ),
                          child: Text(
                            plan.savings!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${plan.pricePerMonth}/month',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Price
            Text(
              priceLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppTheme.premiumGold : null,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
