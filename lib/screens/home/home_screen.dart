import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/sidekick_response.dart';
import '../../providers/scripture_mastery_provider.dart';

import '../../providers/sidekick_provider.dart';
import '../../providers/spaced_repetition_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/progress_ring.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(holisticStatsProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final sidekickResponse = ref.watch(sidekickResponseProvider);
    ref.watch(dueCountProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Large Editorial Greeting ──────────────────────────────
              const SizedBox(height: AppTheme.spacingXl),
              Text(
                'Good morning',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'Continue your spiritual journey with intentional study',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppTheme.onSurfaceVariant),
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // ─── Overall Mastery Section ───────────────────────────────
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  boxShadow: AppTheme.editorialShadow,
                ),
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Mastery',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    Row(
                      children: [
                        // Circular progress ring
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            ProgressRing(
                              value: stats.mastered / 100,
                              size: 100,
                              color: AppTheme.secondary,
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${stats.mastered}',
                                  style:
                                      Theme.of(context).textTheme.displaySmall,
                                ),
                                Text(
                                  '/100',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(width: AppTheme.spacingLg),
                        // Stats tiles
                        Expanded(
                          child: Column(
                            children: [
                              _buildStatTile(
                                context,
                                label: 'Memorized',
                                value: '${stats.memorized}',
                              ),
                              const SizedBox(height: AppTheme.spacingMd),
                              _buildStatTile(
                                context,
                                label: 'Needs Review',
                                value: '${stats.needsReview}',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // ─── Quick Win Card (Premium Only) ─────────────────────────
              if (isPremium && sidekickResponse?.quickWin != null)
                _buildQuickWinCard(
                  context,
                  sidekickResponse!.quickWin!,
                  onTap: () {
                    if (sidekickResponse.quickWin!.scriptureId != null) {
                      context.go(
                        '/scripture/${sidekickResponse.quickWin!.scriptureId}',
                      );
                    }
                  },
                ),

              if (isPremium && sidekickResponse?.quickWin != null)
                const SizedBox(height: AppTheme.spacingXl),

              // ─── Two Large Navigation Cards ────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _buildNavigationCard(
                      context,
                      title: 'Browse\nScriptures',
                      description: 'Explore all 100 Doctrinal Mastery passages',
                      backgroundColor: AppTheme.secondary,
                      icon: Icons.library_books,
                      onTap: () => context.go('/library'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: _buildNavigationCard(
                      context,
                      title: 'Practice\nGames',
                      description: 'Test your knowledge with guided quizzes',
                      backgroundColor: AppTheme.primary,
                      icon: Icons.gamepad,
                      onTap: () => context.go('/practice'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spacingXxl),
            ],
          ),
        ),
      ),
    );
  }

  /// Stat tile (Practiced Today, Day Streak)
  Widget _buildStatTile(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }

  /// Quick Win card (gold-tinted, from Sidekick AI)
  Widget _buildQuickWinCard(
    BuildContext context,
    QuickWin quickWin, {
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.premiumGold.withValues(alpha: 0.12),
            AppTheme.premiumGoldLight.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: AppTheme.premiumGold.withValues(alpha: 0.2),
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
                Icons.auto_awesome,
                color: AppTheme.premiumGold,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Text(
                  'Quick Win',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.premiumGold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            quickWin.suggestion,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
            ),
            child: const Text('Start Exercise'),
          ),
        ],
      ),
    );
  }

  /// Large navigation card (Browse Scriptures / Practice Games)
  Widget _buildNavigationCard(
    BuildContext context, {
    required String title,
    required String description,
    required Color backgroundColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: AppTheme.editorialShadow,
        ),
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
