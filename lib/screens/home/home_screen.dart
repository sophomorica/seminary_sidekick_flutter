import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/sidekick_response.dart';
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

  /// Dynamic mastery description based on actual progress.
  static String _masteryDescription(HolisticStats stats) {
    final pct = stats.mastered;
    if (pct == 0) {
      return 'Your journey begins here. Pick a scripture and start building mastery one verse at a time.';
    } else if (pct < 10) {
      return 'You\'ve taken the first steps. Keep practicing daily and you\'ll see your mastery grow.';
    } else if (pct < 25) {
      return 'Great momentum. You\'re building a strong foundation of scripture knowledge.';
    } else if (pct < 50) {
      return 'Impressive progress. Continue with daily practice to unlock deeper insights.';
    } else if (pct < 75) {
      return 'You\'re well past the halfway mark. Your dedication is paying off beautifully.';
    } else if (pct < 100) {
      return 'Almost there. You\'re approaching full mastery of the doctrinal scriptures.';
    } else {
      return 'Remarkable. You have mastered all 100 doctrinal mastery scriptures.';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(holisticStatsProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final sidekickResponse = ref.watch(sidekickResponseProvider);
    final greetingName = ref.watch(greetingNameProvider);
    ref.watch(dueCountProvider);

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
              // Premium: AI-generated daily prompt (if available)
              // Free: Time-based greeting + user name
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

              const SizedBox(height: 48.0),

              // ─── Overall Mastery Section ───────────────────────────────
              Text(
                'Overall Mastery',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                _masteryDescription(stats),
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // ─── Mastery Ring (160px) with Stats ───────────────────────
              Row(
                children: [
                  // Circular progress ring (custom painted, 160px)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 160,
                        height: 160,
                        child: CustomPaint(
                          painter: _MasteryRingPainter(
                            progress: stats.mastered / 100,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${stats.mastered}',
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge
                                ?.copyWith(
                                  fontFamily: 'Merriweather',
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '/ 100 MASTERED',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  letterSpacing: 0.5,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 24.0),
                  // Stats tiles
                  Expanded(
                    child: Column(
                      children: [
                        _buildStatTile(
                          context,
                          label: 'Scriptures Started',
                          value: '${stats.attempted}',
                          valueColor: AppTheme.secondary,
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        _buildStatTile(
                          context,
                          label: 'Needs Review',
                          value: '${stats.needsReview}',
                          valueColor: const Color(0xFF735C00),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48.0),

              // ─── Quick Win Card (Premium Only) ─────────────────────────
              if (isPremium && sidekickResponse?.quickWin != null)
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

              if (isPremium && sidekickResponse?.quickWin != null)
                const SizedBox(height: 48.0),

              // ─── Full-Width Navigation Cards (stacked) ────────────────
              _buildImageNavigationCard(
                context,
                title: 'Browse Scriptures',
                description: 'Explore the sacred library at your own pace.',
                overlayColor: AppTheme.secondary,
                icon: Icons.menu_book,
                imagePath: 'assets/images/browse_scriptures.jpg',
                onTap: () => context.go('/library'),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _buildImageNavigationCard(
                context,
                title: 'Practice Games',
                description: 'Strengthen your memory through guided play.',
                overlayColor: AppTheme.primary,
                icon: Icons.extension,
                imagePath: 'assets/images/practice_games.jpg',
                onTap: () => context.go('/practice'),
              ),

              const SizedBox(height: 120.0),
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
    required Color valueColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: valueColor,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }

  /// Quick Win card (tertiary-tinted, from Sidekick AI)
  Widget _buildQuickWinCard(
    BuildContext context,
    QuickWin quickWin, {
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF735C00).withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: const Color(0xFF735C00).withValues(alpha: 0.10),
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
                color: Color(0xFF735C00),
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Text(
                  "TODAY'S QUICK WIN",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF735C00),
                        letterSpacing: 0.5,
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
                  color: const Color(0xFF4E3D00),
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
                backgroundColor: const Color(0xFF735C00),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
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

  /// Full-width navigation card with background image and color overlay.
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
        height: 240,
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
            // Background image
            Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
            // Color overlay (mix-blend-multiply effect)
            Container(
              color: overlayColor.withValues(alpha: 0.80),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg + 8),
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
                            ?.copyWith(
                              color: Colors.white,
                              fontFamily: 'Merriweather',
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.80),
                              letterSpacing: 0.3,
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
}

/// Custom painter for the mastery ring (160px, primary color)
class _MasteryRingPainter extends CustomPainter {
  final double progress;

  _MasteryRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 10.0;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    // Background track
    final backgroundPaint = Paint()
      ..color = AppTheme.surfaceVariant
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawOval(rect, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      rect,
      -90 * 3.14159 / 180, // Start at top
      progress * 360 * 3.14159 / 180, // Progress to degrees
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_MasteryRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
