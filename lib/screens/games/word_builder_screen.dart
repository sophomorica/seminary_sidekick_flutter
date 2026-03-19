import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../providers/word_builder_provider.dart';
import '../../theme/app_theme.dart';
import 'game_results_screen.dart';

class WordBuilderScreen extends ConsumerStatefulWidget {
  final DifficultyLevel difficulty;
  final ScriptureBook? bookFilter;

  const WordBuilderScreen({
    super.key,
    required this.difficulty,
    this.bookFilter,
  });

  @override
  ConsumerState<WordBuilderScreen> createState() => _WordBuilderScreenState();
}

class _WordBuilderScreenState extends ConsumerState<WordBuilderScreen>
    with TickerProviderStateMixin {
  late Timer _timer;
  Duration _elapsed = Duration.zero;

  // Animation controllers
  AnimationController? _shakeController;
  AnimationController? _pulseController;
  AnimationController? _slotPulseController;
  late Animation<double> _shakeAnimation;

  // Track which pool index got the incorrect feedback
  int? _shakingPoolIndex;
  // Track which slot just got filled correctly
  int? _pulsingSlot;

  @override
  void initState() {
    super.initState();

    // Start the game
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wordBuilderProvider.notifier).startGame(
            difficulty: widget.difficulty,
            bookFilter: widget.bookFilter,
          );
    });

    // Timer
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });

    // Shake animation for incorrect
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6, end: 4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController!,
      curve: Curves.easeInOut,
    ));

    // Pulse for correct placement
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Pulse for the active slot
    _slotPulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer.cancel();
    _shakeController?.dispose();
    _pulseController?.dispose();
    _slotPulseController?.dispose();
    super.dispose();
  }

  void _onWordTapped(int poolIndex) {
    final state = ref.read(wordBuilderProvider);
    if (state.isScriptureComplete || state.isComplete) return;

    ref.read(wordBuilderProvider.notifier).selectWord(poolIndex);

    final newState = ref.read(wordBuilderProvider);
    if (newState.lastFeedback == 'correct') {
      HapticFeedback.lightImpact();
      setState(() => _pulsingSlot = newState.nextSlotIndex - 1);
      _pulseController?.forward(from: 0).then((_) {
        if (mounted) setState(() => _pulsingSlot = null);
      });

      // Check if scripture is complete
      if (newState.isScriptureComplete) {
        HapticFeedback.heavyImpact();
        // Auto-advance or show completion
        if (!newState.isComplete) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              ref.read(wordBuilderProvider.notifier).nextScripture();
            }
          });
        } else {
          _timer.cancel();
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) _navigateToResults(newState);
          });
        }
      }
    } else if (newState.lastFeedback == 'incorrect') {
      HapticFeedback.mediumImpact();
      setState(() => _shakingPoolIndex = poolIndex);
      _shakeController?.forward(from: 0).then((_) {
        if (mounted) {
          setState(() => _shakingPoolIndex = null);
          ref.read(wordBuilderProvider.notifier).clearFeedback();
        }
      });
    }
  }

  void _navigateToResults(WordBuilderState state) {
    _timer.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameResultsScreen(
          gameType: GameType.wordOrder,
          difficulty: widget.difficulty,
          correctMatches: state.correctWordsAcrossAll,
          incorrectAttempts: state.incorrectAttempts,
          totalPairs: state.totalWordsAcrossAll,
          completionTime: state.completionTime ?? _elapsed,
          starRating: state.starRating,
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quit Game?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Quit'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wordBuilderProvider);

    // Listen for game completion
    ref.listen<WordBuilderState>(wordBuilderProvider, (prev, next) {
      if (next.isComplete && !(prev?.isComplete ?? false)) {
        _timer.cancel();
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _navigateToResults(next);
        });
      }
    });

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: AppTheme.offWhite,
        appBar: _buildAppBar(state),
        body: state.currentScripture == null
            ? const Center(child: CircularProgressIndicator())
            : _buildGameBody(state),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(WordBuilderState state) {
    final minutes = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');

    return AppBar(
      backgroundColor: AppTheme.surface,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () async {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) Navigator.of(context).pop();
        },
      ),
      title: Row(
        children: [
          const Icon(Icons.sort_by_alpha, size: 20),
          const SizedBox(width: 8),
          const Text('Word Builder'),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.dark.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined,
                    size: 16, color: AppTheme.dark.withOpacity(0.6)),
                const SizedBox(width: 4),
                Text(
                  '$minutes:$seconds',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.dark.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameBody(WordBuilderState state) {
    return Column(
      children: [
        // Progress header
        _buildProgressHeader(state),

        // Scripture reference & name
        _buildScriptureHeader(state),

        // Placed words area (the "blanks")
        Expanded(
          flex: 3,
          child: _buildPlacedWordsArea(state),
        ),

        // Divider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Tap the next word',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),
        ),

        // Word pool
        Expanded(
          flex: 2,
          child: _buildWordPool(state),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProgressHeader(WordBuilderState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: AppTheme.surface,
      child: Row(
        children: [
          // Scripture progress (e.g., "2/4")
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.menu_book, size: 16, color: AppTheme.secondary),
                const SizedBox(width: 4),
                Text(
                  '${state.currentIndex + 1}/${state.totalScriptures}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.secondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Words placed in current scripture
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, size: 16, color: AppTheme.success),
                const SizedBox(width: 4),
                Text(
                  '${state.wordsPlaced}/${state.targetWords.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.success,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Misses
          if (state.incorrectAttempts > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.close, size: 16, color: AppTheme.error),
                  const SizedBox(width: 4),
                  Text(
                    '${state.incorrectAttempts}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.error,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScriptureHeader(WordBuilderState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          Text(
            state.currentScripture?.reference ?? '',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            state.currentScripture?.name ?? '',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Word progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.scriptureProgress,
              backgroundColor: Colors.grey.shade200,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppTheme.secondary),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacedWordsArea(WordBuilderState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: List.generate(state.targetWords.length, (index) {
          final word = state.placedWords[index];
          final isNext = index == state.nextSlotIndex &&
              !state.isScriptureComplete;
          final isPulsing = _pulsingSlot == index;

          return AnimatedBuilder(
            animation: _slotPulseController!,
            builder: (context, child) {
              final isActiveSlot = isNext;
              final borderColor = isActiveSlot
                  ? Color.lerp(
                      AppTheme.accent,
                      AppTheme.accent.withOpacity(0.3),
                      _slotPulseController!.value,
                    )!
                  : Colors.grey.shade300;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: word != null
                      ? (isPulsing
                          ? AppTheme.successLight
                          : AppTheme.success.withOpacity(0.1))
                      : (isNext
                          ? AppTheme.accent.withOpacity(0.05)
                          : Colors.white),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: word != null
                        ? AppTheme.success.withOpacity(0.4)
                        : borderColor,
                    width: isNext ? 2 : 1,
                  ),
                ),
                child: Text(
                  word ?? _getHintForSlot(state, index),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        word != null ? FontWeight.w600 : FontWeight.normal,
                    color: word != null
                        ? AppTheme.dark
                        : Colors.grey.shade400,
                    letterSpacing: word == null ? 2 : 0,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  String _getHintForSlot(WordBuilderState state, int index) {
    // Show underscores matching the word length
    final targetWord = state.targetWords[index];
    if (index == state.nextSlotIndex) {
      // Active slot — show dashes as hint of length
      return '─' * (targetWord.length.clamp(2, 8));
    }
    return '─' * (targetWord.length.clamp(2, 6));
  }

  Widget _buildWordPool(WordBuilderState state) {
    if (state.isScriptureComplete) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: AppTheme.success, size: 48),
            const SizedBox(height: 12),
            Text(
              state.isComplete ? 'All Done!' : 'Scripture Complete!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.success,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (!state.isComplete) ...[
              const SizedBox(height: 4),
              Text(
                'Loading next scripture...',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: List.generate(state.availablePool.length, (index) {
          final tile = state.availablePool[index];
          final isShaking = _shakingPoolIndex == index;

          return AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(isShaking ? _shakeAnimation.value : 0, 0),
                child: child,
              );
            },
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onWordTapped(index),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: tile.isDistractor
                        ? AppTheme.warning.withOpacity(0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isShaking
                          ? AppTheme.error
                          : (tile.isDistractor
                              ? AppTheme.warning.withOpacity(0.3)
                              : AppTheme.accent.withOpacity(0.3)),
                      width: isShaking ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    tile.word,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isShaking ? AppTheme.error : AppTheme.dark,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
