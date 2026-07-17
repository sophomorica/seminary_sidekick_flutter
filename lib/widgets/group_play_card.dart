import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/host_usage.dart';
import '../providers/group_play_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/group_play_service.dart';
import '../theme/app_theme.dart';

/// The single entry point to Group Play — used by both Home and the Practice
/// Hub so hosts and joiners always see the same Host + Join card.
///
/// Joining is always free. The subtitle reflects the host's tier (free hosts
/// get up to 6 players; premium hosts get full class rooms). When a free host
/// has already used their weekly slot, Host routes to `/upgrade` and the
/// footer shows Premium + next-week copy.
class GroupPlayCard extends ConsumerWidget {
  /// When true (Home), shows a small "NEW" flag in the corner.
  final bool showNewFlag;

  /// Landscape-tablet Home: icon + copy left, Host/Join right, footnote below.
  final bool bannerLayout;

  const GroupPlayCard({
    super.key,
    this.showNewFlag = false,
    this.bannerLayout = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    // Derive lock in build (not a cached Provider) so a stale usage row from
    // last week unlocks once `now` crosses Monday 00:00 UTC on rebuild.
    final hostingLocked = isPremium
        ? false
        : ref.watch(hostUsageProvider).when(
              data: (usage) => FreeHostWeeklyLimit.isLocked(
                usage: usage,
                nowUtc: DateTime.now().toUtc(),
                isPremium: false,
                weeklyLimit: GroupPlayService.freeHostWeeklyLimit,
              ),
              loading: () => false,
              error: (_, __) => false,
            );

    final Widget hostFooter;
    if (hostingLocked) {
      final footerStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.onPrimary.withValues(alpha: 0.75),
            fontSize: 11.5,
          );
      hostFooter = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Unlimited hosting with Premium', style: footerStyle),
          Text('Next host session available next week', style: footerStyle),
        ],
      );
    } else {
      final hostSubtitle = isPremium
          ? 'Up to 30 players · Save your class roster'
          : 'Up to 6 players free · Premium for class size';
      hostFooter = Text(
        hostSubtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.onPrimary.withValues(alpha: 0.75),
              fontSize: 11.5,
            ),
      );
    }

    final titleRow = Row(
      children: [
        Text(
          'Group Play',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'Merriweather',
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                color: AppTheme.onPrimary,
              ),
        ),
        if (showNewFlag) ...[
          const SizedBox(width: 8.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.onPrimary.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'NEW',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 10,
                  ),
            ),
          ),
        ],
      ],
    );

    final hostButton = ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: hostingLocked
            ? AppTheme.onPrimary.withValues(alpha: 0.55)
            : AppTheme.onPrimary,
        foregroundColor: hostingLocked
            ? AppTheme.primary.withValues(alpha: 0.70)
            : AppTheme.primary,
        padding: EdgeInsets.symmetric(
          vertical: 14.0,
          horizontal: bannerLayout ? 18.0 : 0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.0),
        ),
        elevation: 0,
      ),
      onPressed: () => context.push(
        hostingLocked ? '/upgrade' : '/group-play/host',
      ),
      icon: const Icon(Icons.add_circle_outline, size: 20),
      label: Text(
        bannerLayout ? 'Host' : 'Host a Game',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );

    final joinButton = OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.onPrimary,
        side: BorderSide(
          color: AppTheme.onPrimary.withValues(alpha: 0.6),
          width: 1.5,
        ),
        padding: EdgeInsets.symmetric(
          vertical: 14.0,
          horizontal: bannerLayout ? 18.0 : 0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.0),
        ),
      ),
      onPressed: () => context.push('/group-play/join'),
      icon: const Icon(Icons.login, size: 20),
      label: Text(
        bannerLayout ? 'Join' : 'Join a Game',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.editorialShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: bannerLayout
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: AppTheme.onPrimary.withValues(alpha: 0.18),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: const Icon(
                          Icons.groups,
                          color: AppTheme.onPrimary,
                          size: 28.0,
                        ),
                      ),
                      const SizedBox(width: 14.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            titleRow,
                            const SizedBox(height: 2.0),
                            Text(
                              'Quiz the whole seminary class together',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.onPrimary
                                        .withValues(alpha: 0.85),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      hostButton,
                      const SizedBox(width: 12.0),
                      joinButton,
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  hostFooter,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: AppTheme.onPrimary.withValues(alpha: 0.18),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: const Icon(
                          Icons.groups,
                          color: AppTheme.onPrimary,
                          size: 28.0,
                        ),
                      ),
                      const SizedBox(width: 14.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            titleRow,
                            const SizedBox(height: 2.0),
                            Text(
                              'Quiz the whole seminary class together',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.onPrimary
                                        .withValues(alpha: 0.85),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),
                  Row(
                    children: [
                      Expanded(child: hostButton),
                      const SizedBox(width: 12.0),
                      Expanded(child: joinButton),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  hostFooter,
                ],
              ),
      ),
    );
  }
}
