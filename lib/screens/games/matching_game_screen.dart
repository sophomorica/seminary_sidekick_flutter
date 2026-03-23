import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/enums.dart';
import '../../models/scripture.dart';
import '../../providers/matching_game_provider.dart';
import '../../theme/app_theme.dart';
import 'game_results_screen.dart';

class MatchingGameScreen extends ConsumerStatefulWidget {
  final DifficultyLevel difficulty;
  final ScriptureBook? bookFilter;

  const MatchingGameScreen({
    super.key,
    required this.difficulty,
    this.bookFilter,
  });

  @override
  ConsumerState<MatchingGameScreen> createState() => _MatchingGameScreenState();
}

class _MatchingGameScreenState extends ConsumerState<MatchingGameScreen>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;

  // Track which items are animating out (just matched)
  final Set<String> _animatingOutIds = {};

  @override
  void initState() {
    super.initState();

    // Shake animation for incorrect matches
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 8)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    // Pulse animation for correct matches
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_pulseController);

    // Start the game
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(matchingGameProvider.notifier).startGame(
            difficulty: widget.difficulty,
            bookFilter: widget.bookFilter,
          );
      _startTimer();
    });
  }

  void _startTimer() {
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(
            ref.read(matchingGameProvider).startTime,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _pulseController.dispose();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(matchingGameProvider);
    final notifier = ref.read(matchingGameProvider.notifier);

    // Listen for feedback changes
    ref.listen<MatchingGameState>(matchingGameProvider, (prev, next) {
      if (next.lastFeedback == 'correct') {
        _onCorrectMatch();
      } else if (next.lastFeedback == 'incorrect') {
        _onIncorrectMatch();
      }
      if (next.isComplete && !(prev?.isComplete ?? false)) {
        _onGameComplete(next);
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitDialog(context),
        ),
        title: Text(widget.difficulty.label),
        actions: [
          // Timer display
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(_elapsed),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: gameState.pairs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Progress bar
                _ProgressHeader(
                  matched: gameState.correctMatches,
                  total: gameState.totalPairs,
                  incorrect: gameState.incorrectAttempts,
                ),
                // Game area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left column: key phrases
                        Expanded(
                          child: _buildColumn(
                            context: context,
                            title: 'Key Phrases',
                            ids: gameState.shuffledPhrases,
                            isLeft: true,
                            gameState: gameState,
                            notifier: notifier,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Right column: references
                        Expanded(
                          child: _buildColumn(
                            context: context,
                            title: 'References',
                            ids: gameState.shuffledReferences,
                            isLeft: false,
                            gameState: gameState,
                            notifier: notifier,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildColumn({
    required BuildContext context,
    required String title,
    required List<String> ids,
    required bool isLeft,
    required MatchingGameState gameState,
    required MatchingGameNotifier notifier,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Column header
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.grey.shade500,
                  letterSpacing: 1,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        // Scrollable list of items
        Expanded(
          child: ListView.builder(
            itemCount: ids.length,
            itemBuilder: (context, index) {
              final id = ids[index];
              final scripture = notifier.getScripture(id);
              if (scripture == null) return const SizedBox.shrink();
              final isMatched = notifier.isMatched(id);

              return _MatchTile(
                scripture: scripture,
                isLeft: isLeft,
                isMatched: isMatched,
                isSelected: isLeft
                    ? gameState.selectedPhraseId == id
                    : gameState.selectedReferenceId == id,
                isAnimatingOut: _animatingOutIds.contains(id),
                lastFeedback: gameState.lastFeedback,
                lastMatchedId: gameState.lastMatchedId,
                shakeAnimation: _shakeAnimation,
                pulseAnimation: _pulseAnimation,
                onTap: () {
                  if (isMatched) return;
                  HapticFeedback.selectionClick();
                  if (isLeft) {
                    notifier.selectPhrase(id);
                  } else {
                    notifier.selectReference(id);
                  }
                },
                onDragAccepted: (draggedId) {
                  HapticFeedback.selectionClick();
                  if (isLeft) {
                    notifier.attemptDragMatch(
                      draggedId: draggedId,
                      targetId: id,
                    );
                  } else {
                    notifier.attemptDragMatch(
                      draggedId: id,
                      targetId: draggedId,
                    );
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _onCorrectMatch() {
    HapticFeedback.mediumImpact();
    _pulseController.forward().then((_) => _pulseController.reverse());

    // Mark matched items for animation
    final matchedId = ref.read(matchingGameProvider).lastMatchedId;
    if (matchedId != null) {
      setState(() => _animatingOutIds.add(matchedId));
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() => _animatingOutIds.remove(matchedId));
          ref.read(matchingGameProvider.notifier).clearFeedback();
        }
      });
    }
  }

  void _onIncorrectMatch() {
    HapticFeedback.heavyImpact();
    _shakeController.forward().then((_) {
      _shakeController.reset();
      ref.read(matchingGameProvider.notifier).clearFeedback();
    });
  }

  void _onGameComplete(MatchingGameState finalState) {
    _elapsedTimer?.cancel();
    HapticFeedback.heavyImpact();

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GameResultsScreen(
            gameType: GameType.matching,
            difficulty: widget.difficulty,
            correctMatches: finalState.correctMatches,
            incorrectAttempts: finalState.incorrectAttempts,
            totalPairs: finalState.totalPairs,
            completionTime: finalState.completionTime ?? _elapsed,
            starRating: finalState.starRating,
          ),
        ),
      );
    });
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quit Game?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Playing'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              'Quit',
              style: TextStyle(color: AppTheme.error),
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

// ─── Progress Header ────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  final int matched;
  final int total;
  final int incorrect;

  const _ProgressHeader({
    required this.matched,
    required this.total,
    required this.incorrect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$matched / $total matched',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (incorrect > 0)
                Row(
                  children: [
                    Icon(Icons.close, size: 16, color: AppTheme.error),
                    const SizedBox(width: 2),
                    Text(
                      '$incorrect miss${incorrect == 1 ? '' : 'es'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.error,
                          ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? matched / total : 0,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.success),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Individual Match Tile ──────────────────────────────────────

class _MatchTile extends StatelessWidget {
  final Scripture scripture;
  final bool isLeft;
  final bool isMatched;
  final bool isSelected;
  final bool isAnimatingOut;
  final String? lastFeedback;
  final String? lastMatchedId;
  final Animation<double> shakeAnimation;
  final Animation<double> pulseAnimation;
  final VoidCallback onTap;
  final void Function(String draggedId) onDragAccepted;

  const _MatchTile({
    required this.scripture,
    required this.isLeft,
    required this.isMatched,
    required this.isSelected,
    required this.isAnimatingOut,
    required this.lastFeedback,
    required this.lastMatchedId,
    required this.shakeAnimation,
    required this.pulseAnimation,
    required this.onTap,
    required this.onDragAccepted,
  });

  @override
  Widget build(BuildContext context) {
    // Already matched — show success state then fade
    if (isMatched) {
      return AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: isAnimatingOut ? 1.0 : 0.4,
        child: _buildTileContent(context, matched: true),
      );
    }

    // Draggable tile
    final draggable = LongPressDraggable<String>(
      data: scripture.id,
      delay: const Duration(milliseconds: 150),
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.42,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Text(
            isLeft ? scripture.keyPhrase : scripture.reference,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildTileContent(context),
      ),
      child: DragTarget<String>(
        onWillAcceptWithDetails: (details) => !isMatched,
        onAcceptWithDetails: (details) => onDragAccepted(details.data),
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          return AnimatedBuilder(
            animation: isSelected && lastFeedback == 'incorrect'
                ? shakeAnimation
                : const AlwaysStoppedAnimation(0),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  isSelected && lastFeedback == 'incorrect'
                      ? shakeAnimation.value * (scripture.id.hashCode.isEven ? 1 : -1)
                      : 0,
                  0,
                ),
                child: GestureDetector(
                  onTap: onTap,
                  child: _buildTileContent(
                    context,
                    isHovering: isHovering,
                  ),
                ),
              );
            },
          );
        },
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: draggable,
    );
  }

  Widget _buildTileContent(
    BuildContext context, {
    bool matched = false,
    bool isHovering = false,
  }) {
    Color bgColor;
    Color borderColor;
    Color textColor;

    if (matched) {
      bgColor = AppTheme.success.withValues(alpha: 0.15);
      borderColor = AppTheme.success;
      textColor = AppTheme.success;
    } else if (isHovering) {
      bgColor = AppTheme.accent.withValues(alpha: 0.15);
      borderColor = AppTheme.accent;
      textColor = AppTheme.dark;
    } else if (isSelected) {
      bgColor = AppTheme.primary.withValues(alpha: 0.12);
      borderColor = AppTheme.primary;
      textColor = AppTheme.primaryDark;
    } else {
      bgColor = Colors.white;
      borderColor = Colors.grey.shade300;
      textColor = AppTheme.dark;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          if (matched) ...[
            const Icon(Icons.check_circle, color: AppTheme.success, size: 18),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              isLeft ? scripture.keyPhrase : scripture.reference,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textColor,
                    fontWeight: isSelected || matched
                        ? FontWeight.w600
                        : FontWeight.normal,
                    height: 1.3,
                  ),
              maxLines: isLeft ? 3 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
