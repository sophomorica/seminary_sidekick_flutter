import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/scripture.dart';
import '../../providers/scripture_provider.dart';
import '../../providers/scripture_mastery_provider.dart';
import '../../providers/spaced_repetition_provider.dart';
import '../../theme/app_theme.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(holisticStatsProvider);
    final allScriptures = ref.watch(scripturesProvider);
    final needsReview = ref.watch(smartReviewQueueProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24.0),

            // Header
            _buildHeader(context),
            const SizedBox(height: 16.0),

            // Continuity Heatmap
            _buildContinuityHeatmap(context),
            const SizedBox(height: 16.0),

            // Mastery Streak + Book Breakdown
            _buildStreakCard(context, stats),
            const SizedBox(height: 16.0),

            _buildBookBreakdown(context, ref, allScriptures),
            const SizedBox(height: 16.0),

            // Needs Review + Achievements
            if (needsReview.isNotEmpty)
              _buildNeedsReviewAndAchievements(context, ref, stats, needsReview)
            else
              _buildAchievementMedalsStandalone(context, stats),

            const SizedBox(height: 16.0),

            // CTA
            _buildDeepFoundationCTA(context),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mastery & Progress',
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 8.0),
        Text(
          'A reflection of your consistency and the deepening of your scriptural understanding. Every verse mastered is a step closer to wisdom.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildContinuityHeatmap(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.editorialShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Continuity Heatmap',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Your daily engagement with the sacred word',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12.0),

          // Color legend
          Row(
            children: [
              _ColorLegendBox(color: Theme.of(context).colorScheme.surfaceContainerHighest),
              const SizedBox(width: 8.0),
              _ColorLegendBox(color: AppTheme.primary.withValues(alpha: 0.1)),
              const SizedBox(width: 8.0),
              _ColorLegendBox(color: AppTheme.primary.withValues(alpha: 0.3)),
              const SizedBox(width: 8.0),
              _ColorLegendBox(color: AppTheme.primary.withValues(alpha: 0.6)),
              const SizedBox(width: 8.0),
              const _ColorLegendBox(color: AppTheme.primary),
            ],
          ),
          const SizedBox(height: 12.0),

          // Heatmap grid
          _buildHeatmapGrid(context),
        ],
      ),
    );
  }

  Widget _buildHeatmapGrid(BuildContext context) {
    const daysToShow = 60;
    final colors = [
      Theme.of(context).colorScheme.surfaceContainerHighest,
      AppTheme.primary.withValues(alpha: 0.1),
      AppTheme.primary.withValues(alpha: 0.3),
      AppTheme.primary.withValues(alpha: 0.6),
      AppTheme.primary,
    ];

    return Wrap(
      spacing: 3.0,
      runSpacing: 3.0,
      children: List.generate(daysToShow, (index) {
        final activityLevel = (index % 5).toInt();
        return SizedBox(
          width: 12.0,
          height: 12.0,
          child: Container(
            decoration: BoxDecoration(
              color: colors[activityLevel],
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStreakCard(BuildContext context, HolisticStats stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppTheme.tertiaryFixed,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.editorialShadow,
      ),
      child: Column(
        children: [
          Text(
            'SACRED MASTERY',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.onTertiaryFixedVariant,
                  letterSpacing: 1.5,
                ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Mastery Streak',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.onTertiaryFixed,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '42',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppTheme.onTertiaryFixed,
                      fontWeight: FontWeight.bold,
                      fontSize: 48,
                    ),
              ),
              const SizedBox(width: 16.0),
              Text(
                'Days of Focus',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.onTertiaryFixedVariant,
                      fontSize: 18,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: LinearProgressIndicator(
              value: 0.8,
              minHeight: 8.0,
              backgroundColor: AppTheme.onTertiaryFixed.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.onTertiaryFixed,
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            '12 days until "The Elder" status',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onTertiaryFixedVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookBreakdown(
    BuildContext context,
    WidgetRef ref,
    List<Scripture> allScriptures,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 4 : 2;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16.0,
      crossAxisSpacing: 16.0,
      childAspectRatio: 1.0,
      children: ScriptureBook.values.map((book) {
        final bookScriptures =
            allScriptures.where((s) => s.book == book).toList();

        int masteredCount = 0;
        for (final scripture in bookScriptures) {
          final mastery = ref.watch(scriptureMasteryProvider(scripture.id));
          if (mastery.level == MasteryLevel.mastered ||
              mastery.level == MasteryLevel.eternal) {
            masteredCount++;
          }
        }

        final total = bookScriptures.length;
        final progress = total > 0 ? masteredCount / total : 0.0;

        return _BookBreakdownCard(
          bookName: book.displayName,
          progress: progress,
          percentage: (progress * 100).toInt(),
          bookColor: AppTheme.bookColor(book.displayName),
        );
      }).toList(),
    );
  }

  Widget _buildNeedsReviewAndAchievements(
    BuildContext context,
    WidgetRef ref,
    HolisticStats stats,
    List<Scripture> needsReview,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Needs Review (left, wider)
        Expanded(
          flex: 7,
          child: _buildNeedsReviewSection(context, ref, needsReview),
        ),
        const SizedBox(width: 32.0),

        // Achievements (right, narrower)
        Expanded(
          flex: 5,
          child: _buildAchievementMedals(context, stats),
        ),
      ],
    );
  }

  Widget _buildNeedsReviewSection(
    BuildContext context,
    WidgetRef ref,
    List<Scripture> needsReview,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Needs Review',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            ),
            const SizedBox(width: 12.0),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: AppTheme.errorContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text(
                '${needsReview.length} Flagged',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.onErrorContainer,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        ...needsReview.take(5).map((scripture) {
          return _NeedsReviewTile(scripture: scripture);
        }),
      ],
    );
  }

  Widget _buildAchievementMedals(BuildContext context, HolisticStats stats) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.editorialShadow,
      ),
      child: Column(
        children: [
          Text(
            'Achievement Medals',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
          ),
          const SizedBox(height: 24.0),

          // 2x2 grid with larger gaps
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AchievementMedalWidget(
                    icon: Icons.whatshot,
                    label: 'Hot Streak',
                    unlocked: stats.mastered > 0,
                  ),
                  _AchievementMedalWidget(
                    icon: Icons.auto_awesome,
                    label: 'First Master',
                    unlocked: stats.mastered > 0,
                  ),
                ],
              ),
              const SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AchievementMedalWidget(
                    icon: Icons.workspace_premium,
                    label: 'Book Master',
                    unlocked: stats.eternal > 0,
                  ),
                  _AchievementMedalWidget(
                    icon: Icons.diamond,
                    label: 'Eternal',
                    unlocked: stats.eternal > 0,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementMedalsStandalone(
    BuildContext context,
    HolisticStats stats,
  ) {
    return _buildAchievementMedals(context, stats);
  }

  Widget _buildDeepFoundationCTA(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      padding: const EdgeInsets.all(4.0),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(28.0),
        ),
        child: Column(
          children: [
            Text(
              'Deepen Your Foundation',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    fontSize: 28,
                  ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Continue your journey with daily prompts, reflection exercises, and personalized insights from your Seminary Sidekick.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 48.0,
                  vertical: 16.0,
                ),
              ),
              child: Text(
                'Explore Premium',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Color legend box
class _ColorLegendBox extends StatelessWidget {
  final Color color;

  const _ColorLegendBox({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16.0,
      height: 16.0,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
      ),
    );
  }
}

// Book breakdown card with circular ring
class _BookBreakdownCard extends StatelessWidget {
  final String bookName;
  final double progress;
  final int percentage;
  final Color bookColor;

  const _BookBreakdownCard({
    required this.bookName,
    required this.progress,
    required this.percentage,
    required this.bookColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.editorialShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular progress ring (70px = w-12 h-12)
          SizedBox(
            width: 70,
            height: 70,
            child: CustomPaint(
              painter: _ProgressRingPainter(
                progress: progress,
                color: bookColor,
                strokeWidth: 4,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Center(
                child: Text(
                  '$percentage%',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: bookColor,
                        fontSize: 14,
                      ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            bookName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
          ),
          const SizedBox(height: 1.5),
          Text(
            'Scripture Mastery',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 9,
                ),
          ),
        ],
      ),
    );
  }
}

// Needs Review Tile
class _NeedsReviewTile extends StatelessWidget {
  final Scripture scripture;

  const _NeedsReviewTile({required this.scripture});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.editorialShadow,
          border: const Border(
            left: BorderSide(
              color: AppTheme.error,
              width: 4.0,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mastery Low (32%)',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.error,
                          letterSpacing: 1.0,
                        ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    scripture.reference,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    scripture.keyPhrase,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16.0),
            Container(
              width: 48.0,
              height: 48.0,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: AppTheme.editorialShadow,
              ),
              child: const Icon(
                Icons.refresh,
                color: AppTheme.primary,
                size: 20.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Achievement Medal Widget
class _AchievementMedalWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool unlocked;

  const _AchievementMedalWidget({
    required this.icon,
    required this.label,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96.0,
          height: 96.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: unlocked
                ? AppTheme.tertiaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHigh,
            border: unlocked
                ? Border.all(
                    color: AppTheme.tertiary.withValues(alpha: 0.1),
                    width: 8.0,
                  )
                : Border.all(
                    color: AppTheme.outline,
                    width: 2.0,
                    strokeAlign: BorderSide.strokeAlignOutside,
                    style: BorderStyle.solid,
                  ),
          ),
          child: Icon(
            unlocked ? icon : Icons.lock_outline,
            size: 48.0,
            color: unlocked
                ? AppTheme.tertiary
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(height: 12.0),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: unlocked
                    ? AppTheme.tertiary
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                letterSpacing: 1.0,
              ),
        ),
      ],
    );
  }
}

// Custom Painter for circular progress rings
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final Color backgroundColor;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);

    // Background circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc
    final sweepAngle = (progress * 2 * 3.14159);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      sweepAngle,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
