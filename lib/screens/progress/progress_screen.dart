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
      backgroundColor: AppTheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppTheme.spacingXl),

            // Editorial Header
            _buildEditorialHeader(context),
            const SizedBox(height: AppTheme.spacingXl),

            // Continuity Heatmap
            _buildContinuityHeatmap(context),
            const SizedBox(height: AppTheme.spacingXl),

            // Sacred Mastery Streak Card
            _buildStreakCard(context, stats),
            const SizedBox(height: AppTheme.spacingXl),

            // Book Breakdown (4 circular rings)
            _buildBookBreakdown(context, ref, allScriptures),
            const SizedBox(height: AppTheme.spacingXl),

            // Needs Review Section
            if (needsReview.isNotEmpty) ...[
              _buildNeedsReviewSection(context, ref, needsReview.map((s) => s.id).toList()),
              const SizedBox(height: AppTheme.spacingXl),
            ],

            // Achievement Medals (placeholder)
            _buildAchievementMedals(context, stats),
            const SizedBox(height: 120), // Bottom nav padding
          ],
        ),
      ),
    );
  }

  // Editorial header with title and subtitle
  Widget _buildEditorialHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mastery &\nProgress',
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          'Reflect on your journey through sacred scripture',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  // Continuity heatmap (last 90 days)
  Widget _buildContinuityHeatmap(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Continuity Heatmap',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            boxShadow: AppTheme.editorialShadow,
          ),
          child: _buildHeatmapGrid(),
        ),
      ],
    );
  }

  // Heatmap grid widget
  Widget _buildHeatmapGrid() {
    const daysToShow = 90;
    final now = DateTime.now();
    final colors = [
      AppTheme.surfaceContainerHighest,
      AppTheme.primaryFixed.withValues(alpha: 0.3),
      AppTheme.primaryFixed.withValues(alpha: 0.6),
      AppTheme.primaryFixed,
      AppTheme.primary,
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 13,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: daysToShow,
      itemBuilder: (context, index) {
        final _ = now.subtract(Duration(days: daysToShow - 1 - index));
        // Placeholder: 0-4 activity levels
        final activityLevel = (index % 5).toInt();
        return Container(
          decoration: BoxDecoration(
            color: colors[activityLevel],
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
        );
      },
    );
  }

  // Sacred Mastery Streak Card
  Widget _buildStreakCard(BuildContext context, HolisticStats stats) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.editorialShadow,
      ),
      child: Column(
        children: [
          // Large streak number
          Text(
            '42',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Days of Focus',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          // Circular progress ring (simplified)
          Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: CustomPaint(
                painter: _ProgressRingPainter(
                  progress: 0.7,
                  color: AppTheme.secondary,
                  strokeWidth: 8,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Keep the momentum going',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Book breakdown with 4 circular rings
  Widget _buildBookBreakdown(
    BuildContext context,
    WidgetRef ref,
    List<Scripture> allScriptures,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mastery by Book',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppTheme.spacingMd,
          crossAxisSpacing: AppTheme.spacingMd,
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

            return _BookCard(
              bookName: book.displayName,
              progress: progress,
              masteredCount: masteredCount,
              totalCount: total,
              bookColor: AppTheme.bookColor(book.displayName),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Needs Review section
  Widget _buildNeedsReviewSection(
    BuildContext context,
    WidgetRef ref,
    List<String> needsReview,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Needs Review',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        ...needsReview.take(5).map((scriptureId) {
          final scripture =
              ref.watch(scriptureByIdProvider(scriptureId));
          if (scripture == null) return const SizedBox.shrink();
          return _NeedsReviewTile(
            scripture: scripture,
            daysSincePractice: 15,
          );
        }),
      ],
    );
  }

  // Achievement Medals section
  Widget _buildAchievementMedals(BuildContext context, HolisticStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievement Medals',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppTheme.spacingMd,
          crossAxisSpacing: AppTheme.spacingMd,
          children: [
            _AchievementMedal(
              icon: Icons.whatshot,
              label: 'Hot Streak',
              unlocked: stats.mastered > 0,
            ),
            _AchievementMedal(
              icon: Icons.auto_awesome,
              label: 'First Master',
              unlocked: stats.mastered > 0,
            ),
            _AchievementMedal(
              icon: Icons.workspace_premium,
              label: 'Book Master',
              unlocked: stats.eternal > 0,
            ),
            _AchievementMedal(
              icon: Icons.diamond,
              label: 'Eternal',
              unlocked: stats.eternal > 0,
            ),
          ],
        ),
      ],
    );
  }
}

// Book card with circular progress
class _BookCard extends StatelessWidget {
  final String bookName;
  final double progress;
  final int masteredCount;
  final int totalCount;
  final Color bookColor;

  const _BookCard({
    required this.bookName,
    required this.progress,
    required this.masteredCount,
    required this.totalCount,
    required this.bookColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.editorialShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular progress ring
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: _ProgressRingPainter(
                progress: progress,
                color: bookColor,
                strokeWidth: 6,
              ),
              child: Center(
                child: Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: bookColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            bookName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            '$masteredCount/$totalCount',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.onSurface.withValues(alpha: 0.6),
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
  final int daysSincePractice;

  const _NeedsReviewTile({
    required this.scripture,
    required this.daysSincePractice,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.editorialShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scripture.reference,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    '$daysSincePractice days since practice',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.warning,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm,
                ),
              ),
              child: Text(
                'Review',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
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

// Achievement Medal Widget
class _AchievementMedal extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool unlocked;

  const _AchievementMedal({
    required this.icon,
    required this.label,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: unlocked
            ? AppTheme.tertiary.withValues(alpha: 0.1)
            : AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.editorialShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: unlocked ? AppTheme.tertiary : AppTheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: unlocked
                  ? AppTheme.onSurface
                  : AppTheme.onSurface.withValues(alpha: 0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Custom Painter for circular progress rings
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
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
        ..color = AppTheme.surfaceContainerHigh
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
        oldDelegate.strokeWidth != strokeWidth;
  }
}
