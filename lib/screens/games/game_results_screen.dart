import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/enums.dart';
import '../../theme/app_theme.dart';

class GameResultsScreen extends StatefulWidget {
  final GameType gameType;
  final DifficultyLevel difficulty;
  final int correctMatches;
  final int incorrectAttempts;
  final int totalPairs;
  final Duration completionTime;
  final int starRating; // 1-3

  const GameResultsScreen({
    super.key,
    required this.gameType,
    required this.difficulty,
    required this.correctMatches,
    required this.incorrectAttempts,
    required this.totalPairs,
    required this.completionTime,
    required this.starRating,
  });

  @override
  State<GameResultsScreen> createState() => _GameResultsScreenState();
}

class _GameResultsScreenState extends State<GameResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _starsController;
  late AnimationController _statsController;
  late Animation<double> _starsScale;
  late Animation<double> _statsSlide;

  @override
  void initState() {
    super.initState();

    _starsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _starsScale = CurvedAnimation(
      parent: _starsController,
      curve: Curves.elasticOut,
    );

    _statsController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _statsSlide = CurvedAnimation(
      parent: _statsController,
      curve: Curves.easeOut,
    );

    // Staggered entrance
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _starsController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _statsController.forward();
    });

    // Celebration haptics
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 300), () {
      HapticFeedback.mediumImpact();
    });
  }

  @override
  void dispose() {
    _starsController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = widget.totalPairs > 0
        ? (widget.correctMatches /
                (widget.correctMatches + widget.incorrectAttempts) *
                100)
            .round()
        : 0;

    final message = switch (widget.starRating) {
      3 => 'Perfect!',
      2 => 'Great Job!',
      _ => 'Keep Practicing!',
    };

    final subtitle = switch (widget.starRating) {
      3 => 'Flawless victory — no mistakes!',
      2 => 'Almost perfect. Try for zero misses next time!',
      _ => 'Practice makes perfect. You\'re getting there!',
    };

    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Stars
              ScaleTransition(
                scale: _starsScale,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final isFilled = index < widget.starRating;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: index == 1 ? 72 : 56, // Middle star bigger
                        color: isFilled ? AppTheme.gold : Colors.grey.shade300,
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),

              // Message
              Text(
                message,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Stats card
              FadeTransition(
                opacity: _statsSlide,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_statsSlide),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _StatRow(
                            icon: Icons.check_circle_outline,
                            iconColor: AppTheme.success,
                            label: 'Correct Matches',
                            value: '${widget.correctMatches}/${widget.totalPairs}',
                          ),
                          const Divider(height: 20),
                          _StatRow(
                            icon: Icons.close,
                            iconColor: AppTheme.error,
                            label: 'Misses',
                            value: '${widget.incorrectAttempts}',
                          ),
                          const Divider(height: 20),
                          _StatRow(
                            icon: Icons.percent,
                            iconColor: AppTheme.accent,
                            label: 'Accuracy',
                            value: '$accuracy%',
                          ),
                          const Divider(height: 20),
                          _StatRow(
                            icon: Icons.timer_outlined,
                            iconColor: AppTheme.secondary,
                            label: 'Time',
                            value: _formatDuration(widget.completionTime),
                          ),
                          const Divider(height: 20),
                          _StatRow(
                            icon: Icons.speed,
                            iconColor: AppTheme.primary,
                            label: 'Difficulty',
                            value: widget.difficulty.label,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Action buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Pop back to games hub and let user start a new game
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.replay),
                  label: const Text('Play Again'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Navigate back to games hub
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Back to Games'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
