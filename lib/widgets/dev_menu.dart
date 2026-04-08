import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../providers/dev_mode_provider.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_theme.dart';

/// Opens the Dev Menu bottom sheet.
///
/// Only call this in debug mode (guarded by [AppConfig.isDevModeActive]).
void showDevMenu(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
    ),
    builder: (_) => const _DevMenuSheet(),
  );
}

class _DevMenuSheet extends ConsumerWidget {
  const _DevMenuSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final override = ref.watch(devModeOverrideProvider);
    final realTier = ref.watch(subscriptionProvider).tier;
    final effectivelyPremium = ref.watch(isPremiumProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(Icons.bug_report, size: 20, color: AppTheme.accent),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text('Dev Menu', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),

            // Status bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingSm,
              ),
              decoration: BoxDecoration(
                color: effectivelyPremium
                    ? AppTheme.premiumGold.withValues(alpha: 0.1)
                    : AppTheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text(
                'Effective: ${effectivelyPremium ? "Premium" : "Free"}  ·  '
                'Real subscription: ${realTier.name}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Subscription Override',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppTheme.spacingSm),

            // Options
            _OptionTile(
              label: 'AppConfig default (forcePremium: ${AppConfig.forcePremium})',
              subtitle: 'Uses the static flag in app_config.dart',
              isSelected: override == null,
              onTap: () => ref.read(devModeOverrideProvider.notifier).useDefault(),
            ),
            _OptionTile(
              label: 'Force Premium',
              subtitle: 'Test all premium features, AI, journal, goals',
              isSelected: override == true,
              onTap: () => ref.read(devModeOverrideProvider.notifier).forcePremium(),
            ),
            _OptionTile(
              label: 'Force Free',
              subtitle: 'Test teasers, upgrade prompts, gated content',
              isSelected: override == false,
              onTap: () => ref.read(devModeOverrideProvider.notifier).forceFree(),
            ),

            const SizedBox(height: AppTheme.spacingSm),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacingSm,
          horizontal: AppTheme.spacingSm / 2,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppTheme.accent : Theme.of(context).hintColor,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
