import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../services/audio_service.dart';
import '../../theme/app_theme.dart';

class GameResultsScreen extends ConsumerStatefulWidget {
  final GameType gameType;
  final DifficultyLevel difficulty;
  final int correctMatches;
  final int incorrectAttempts;
  final int totalPairs;
  final Duration completionTime;
  final int starRating; // 1-3
  final bool isNewMastery; // True when user first reaches "Mastered" level

  const GameResultsScreen({
    super.key,
    required this.gameType,
    required this.difficulty,
    required this.correctMatches,
    required this.incorrectAttempts,
    required this.totalPairs,
    required this.completionTime,
    required this.starRating,
    this.isNewMastery = false,
  });

  @override
  ConsumerState<GameResultsScreen> createState() => _GameResultsScreenState();
}

class _GameResultsScreenState extends ConsumerState<GameResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _starsController;
  late AnimationController _statsController;
  late Animation<double> _starsScale;
  late Animation<double> _statsSlide;
  late ConfettiController _confettiController;

  bool get _shouldCelebrate => widget.starRating == 3 || widget.isNewMastery;

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

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

    // Fire confetti after stars animate in
    if (_shouldCelebrate) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _confettiController.play();
      });
    }

    // Celebration haptics and audio
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 300), () {
      HapticFeedback.mediumImpact();
    });
    if (widget.isNewMastery) {
      ref.read(audioProvider.notifier).play(SoundEffect.levelup);
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
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
      body: Stack(
        children: [
          SafeArea(
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

          // Confetti overlay — IgnorePointer ensures it never blocks interaction
          if (_shouldCelebrate)
            Align(
              alignment: Alignment.topCenter,
              child: IgnorePointer(
                child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2, // straight down
                blastDirectionality: BlastDirectionality.explosive,
                maxBlastForce: 20,
                minBlastForce: 8,
                emissionFrequency: 0.05,
                numberOfParticles: 25,
                gravity: 0.2,
                shouldLoop: false,
                colors: const [
                  AppTheme.primary,
                  AppTheme.secondary,
                  AppTheme.accent,
                  Color(0xFFFFD54F), // gold
                  Color(0xFFFF8A65), // warm orange
                  Color(0xFF81C784), // soft green
                ],
              ),
              ),
            ),

          // Mastery banner overlay
          if (widget.isNewMastery)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF64B5F6).withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.workspace_premium,
                          color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Scripture Mastered!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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
