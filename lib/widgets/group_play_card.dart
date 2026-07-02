import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/subscription_provider.dart';
import '../theme/app_theme.dart';

/// The single entry point to Group Play — used by both Home and the Practice
/// Hub so hosts and joiners always see the same Host + Join card.
///
/// Joining is always free. The subtitle reflects the host's tier (free hosts
/// get up to 6 players; premium hosts get full class rooms).
class GroupPlayCard extends ConsumerWidget {
  /// When true (Home), shows a small "NEW" flag in the corner.
  final bool showNewFlag;

  const GroupPlayCard({super.key, this.showNewFlag = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    final hostSubtitle = isPremium
        ? 'Up to 30 players · Save your class roster'
        : 'Up to 6 players free · Premium for class size';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.secondary, AppTheme.tertiary],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.editorialShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: AppTheme.onPrimary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
                      Row(
                        children: [
                          Text(
                            'Group Play',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontFamily: 'Merriweather',
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.onPrimary,
                                ),
                          ),
                          if (showNewFlag) ...[
                            const SizedBox(width: 8.0),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.onPrimary.withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'NEW',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppTheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                      fontSize: 10,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        'Quiz the whole seminary class together',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  AppTheme.onPrimary.withValues(alpha: 0.85),
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
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.onPrimary,
                      foregroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => context.push('/group-play/host'),
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: const Text(
                      'Host a Game',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.onPrimary,
                      side: BorderSide(
                        color: AppTheme.onPrimary.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                    ),
                    onPressed: () => context.push('/group-play/join'),
                    icon: const Icon(Icons.login, size: 20),
                    label: const Text(
                      'Join a Game',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Text(
              hostSubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onPrimary.withValues(alpha: 0.75),
                    fontSize: 11.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
