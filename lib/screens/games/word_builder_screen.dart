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

  // Animations
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _pulseController;
  late AnimationController _slotPulseController;

  int? _shakingPoolIndex;
  int? _pulsingSlot;

  // Typing mode
  final _typingController = TextEditingController();
  final _typingFocusNode = FocusNode();

  // Chunk colors for visual distinction
  static const _chunkPalette = [
    Color(0xFF5B8ABF), // blue
    Color(0xFF618C84), // sage
    Color(0xFFD9805F), // rust
    Color(0xFFAB47BC), // purple
    Color(0xFF26A69A), // teal
    Color(0xFFD4A843), // gold
    Color(0xFF5C6BC0), // indigo
    Color(0xFF8D6E63), // brown
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wordBuilderProvider.notifier).startGame(
            difficulty: widget.difficulty,
            bookFilter: widget.bookFilter,
          );
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });

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
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slotPulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer.cancel();
    _shakeController.dispose();
    _pulseController.dispose();
    _slotPulseController.dispose();
    _typingController.dispose();
    _typingFocusNode.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wordBuilderProvider);

    ref.listen<WordBuilderState>(wordBuilderProvider, (prev, next) {
      if (next.isComplete && !(prev?.isComplete ?? false)) {
        _timer.cancel();
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _navigateToResults(next);
        });
      }
      // For typing mode: if a Master reset happened, clear the text controller
      if (next.lastFeedback == 'reset' && prev?.lastFeedback != 'reset') {
        _typingController.clear();
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
            : (state.mode == WordBuilderMode.chunkTap
                ? _buildChunkTapBody(state)
                : _buildTypingBody(state)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════════

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
              color: AppTheme.dark.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined,
                    size: 16, color: AppTheme.dark.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                Text(
                  '$minutes:$seconds',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.dark.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(WordBuilderState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: AppTheme.surface,
      child: Row(
        children: [
          // Scripture progress
          _buildPill(Icons.menu_book, AppTheme.secondary,
              '${state.currentIndex + 1}/${state.totalScriptures}'),
          const SizedBox(width: 12),
          // Difficulty label
          _buildPill(
            Icons.speed,
            AppTheme.accent,
            widget.difficulty.label,
          ),
          const Spacer(),
          if (state.incorrectAttempts > 0)
            _buildPill(Icons.close, AppTheme.error,
                '${state.incorrectAttempts}'),
          if (state.mode == WordBuilderMode.typing && state.resetCount > 0) ...[
            const SizedBox(width: 8),
            _buildPill(Icons.refresh, AppTheme.warning,
                '${state.resetCount} resets'),
          ],
        ],
      ),
    );
  }

  Widget _buildPill(IconData icon, Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: color, fontSize: 13)),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.scriptureProgress,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondary),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CHUNK-TAP MODE (Beginner / Intermediate)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildChunkTapBody(WordBuilderState state) {
    return Column(
      children: [
        _buildProgressHeader(state),
        _buildScriptureHeader(state),

        // Placed chunks area
        Expanded(
          flex: 3,
          child: _buildPlacedChunksArea(state),
        ),

        // Divider
        _buildTapHintDivider(),

        // Chunk pool
        Expanded(
          flex: 2,
          child: state.isScriptureComplete
              ? _buildScriptureCompleteOverlay(state)
              : _buildChunkPool(state),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPlacedChunksArea(WordBuilderState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: List.generate(state.targetChunks.length, (index) {
          final placed = state.placedChunks[index];
          final target = state.targetChunks[index];
          final isNext =
              index == state.nextChunkIndex && !state.isScriptureComplete;
          final isPulsing = _pulsingSlot == index;
          final chunkColor = _chunkPalette[target.colorIndex % _chunkPalette.length];

          return AnimatedBuilder(
            animation: _slotPulseController,
            builder: (context, child) {
              final borderColor = isNext
                  ? Color.lerp(
                      chunkColor,
                      chunkColor.withValues(alpha: 0.3),
                      _slotPulseController.value,
                    )!
                  : Colors.grey.shade300;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: placed != null
                      ? (isPulsing
                          ? chunkColor.withValues(alpha: 0.2)
                          : chunkColor.withValues(alpha: 0.1))
                      : (isNext
                          ? chunkColor.withValues(alpha: 0.04)
                          : Colors.white),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: placed != null
                        ? chunkColor.withValues(alpha: 0.5)
                        : borderColor,
                    width: isNext ? 2 : 1,
                  ),
                ),
                child: Text(
                  placed?.text ?? _chunkPlaceholder(target),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        placed != null ? FontWeight.w600 : FontWeight.normal,
                    color: placed != null
                        ? chunkColor.withValues(alpha: 0.9)
                        : Colors.grey.shade400,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  String _chunkPlaceholder(WordChunk target) {
    // Show dashes for each word in the chunk
    return target.words.map((w) => '─' * w.length.clamp(2, 6)).join(' ');
  }

  Widget _buildChunkPool(WordBuilderState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: List.generate(state.availablePool.length, (index) {
          final chunk = state.availablePool[index];
          final isShaking = _shakingPoolIndex == index;
          final tileColor = chunk.isDistractor
              ? AppTheme.warning.withValues(alpha: 0.06)
              : _chunkPalette[chunk.colorIndex % _chunkPalette.length]
                  .withValues(alpha: 0.08);
          final borderCol = chunk.isDistractor
              ? AppTheme.warning.withValues(alpha: 0.3)
              : _chunkPalette[chunk.colorIndex % _chunkPalette.length]
                  .withValues(alpha: 0.3);

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
                onTap: () => _onChunkTapped(index),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: tileColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isShaking ? AppTheme.error : borderCol,
                      width: isShaking ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    chunk.text,
                    style: TextStyle(
                      fontSize: 14,
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

  void _onChunkTapped(int poolIndex) {
    final state = ref.read(wordBuilderProvider);
    if (state.isScriptureComplete || state.isComplete) return;

    ref.read(wordBuilderProvider.notifier).selectChunk(poolIndex);

    final newState = ref.read(wordBuilderProvider);
    if (newState.lastFeedback == 'correct') {
      HapticFeedback.lightImpact();
      setState(() => _pulsingSlot = newState.nextChunkIndex - 1);
      _pulseController.forward(from: 0).then((_) {
        if (mounted) setState(() => _pulsingSlot = null);
      });

      if (newState.isScriptureComplete) {
        HapticFeedback.heavyImpact();
        if (!newState.isComplete) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              ref.read(wordBuilderProvider.notifier).nextScripture();
            }
          });
        }
      }
    } else if (newState.lastFeedback == 'incorrect') {
      HapticFeedback.mediumImpact();
      setState(() => _shakingPoolIndex = poolIndex);
      _shakeController.forward(from: 0).then((_) {
        if (mounted) {
          setState(() => _shakingPoolIndex = null);
          ref.read(wordBuilderProvider.notifier).clearFeedback();
        }
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // TYPING MODE (Advanced / Master)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTypingBody(WordBuilderState state) {
    return Column(
      children: [
        _buildProgressHeader(state),
        _buildScriptureHeader(state),

        // Typed text display (colored per character)
        Expanded(
          flex: 4,
          child: _buildTypedTextDisplay(state),
        ),

        // Feedback banner for Master resets
        if (state.lastFeedback == 'reset')
          _buildResetBanner(),

        // Text input area
        if (!state.isScriptureComplete)
          _buildTypingInput(state),

        if (state.isScriptureComplete)
          Expanded(
            flex: 1,
            child: _buildScriptureCompleteOverlay(state),
          ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTypedTextDisplay(WordBuilderState state) {
    // Show the passage with typed characters colored green/red,
    // and remaining text as gray placeholders.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 18,
              height: 1.6,
              fontFamily: 'monospace',
            ),
            children: _buildTypedSpans(state),
          ),
        ),
      ),
    );
  }

  List<TextSpan> _buildTypedSpans(WordBuilderState state) {
    final spans = <TextSpan>[];
    final target = state.targetText;
    final typed = state.typedChars;
    final isMaster = widget.difficulty == DifficultyLevel.master;

    // For Advanced: pre-compute which indices are "first letter of a word"
    // so we can show those as hints.
    final firstLetterIndices = <int>{};
    if (!isMaster) {
      bool prevWasSpace = true; // treat start of text as word boundary
      for (int i = 0; i < target.length; i++) {
        if (prevWasSpace && target[i] != ' ') {
          firstLetterIndices.add(i);
        }
        prevWasSpace = target[i] == ' ';
      }
    }

    for (int i = 0; i < target.length; i++) {
      if (i < typed.length) {
        // Already typed — show green or red
        final tc = typed[i];
        spans.add(TextSpan(
          text: tc.char,
          style: TextStyle(
            color: tc.isCorrect ? AppTheme.success : AppTheme.error,
            fontWeight: FontWeight.w600,
            backgroundColor: tc.isCorrect
                ? AppTheme.success.withValues(alpha: 0.08)
                : AppTheme.error.withValues(alpha: 0.12),
            decoration: tc.isCorrect ? null : TextDecoration.underline,
            decorationColor: AppTheme.error,
          ),
        ));
      } else if (i == typed.length && !isMaster) {
        // Cursor position (Advanced only) — highlight the next expected char
        spans.add(TextSpan(
          text: target[i],
          style: TextStyle(
            color: AppTheme.accent,
            fontWeight: FontWeight.w700,
            backgroundColor: AppTheme.accent.withValues(alpha: 0.15),
          ),
        ));
      } else {
        // Not yet reached
        if (isMaster) {
          // Master: show nothing — just an underscore for letters,
          // but preserve spaces so word boundaries are visible.
          final ch = target[i];
          if (ch == ' ') {
            spans.add(const TextSpan(text: ' '));
          } else if (ch == '\n') {
            spans.add(const TextSpan(text: '\n'));
          } else {
            spans.add(TextSpan(
              text: '_',
              style: TextStyle(
                color: Colors.grey.shade300,
                letterSpacing: 1,
              ),
            ));
          }
        } else {
          // Advanced: show first letter of each word, hide the rest
          final ch = target[i];
          if (ch == ' ' || ch == '\n') {
            spans.add(TextSpan(text: ch));
          } else if (firstLetterIndices.contains(i)) {
            // First letter hint — show it dimly
            spans.add(TextSpan(
              text: ch,
              style: TextStyle(
                color: AppTheme.accent.withValues(alpha: 0.4),
                fontWeight: FontWeight.w600,
              ),
            ));
          } else {
            spans.add(TextSpan(
              text: '_',
              style: TextStyle(
                color: Colors.grey.shade300,
                letterSpacing: 1,
              ),
            ));
          }
        }
      }
    }

    return spans;
  }

  Widget _buildResetBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      color: AppTheme.error.withValues(alpha: 0.1),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.refresh, color: AppTheme.error, size: 18),
          SizedBox(width: 8),
          Text(
            'Wrong character! Starting over...',
            style: TextStyle(
              color: AppTheme.error,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingInput(WordBuilderState state) {
    final isMaster = widget.difficulty == DifficultyLevel.master;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _typingController,
              focusNode: _typingFocusNode,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              decoration: InputDecoration(
                hintText: state.hasActiveError
                    ? 'Delete the error and try again...'
                    : (isMaster
                        ? 'Type from memory — no peeking!'
                        : 'Type the scripture (first letters shown)...'),
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: state.hasActiveError
                        ? AppTheme.error
                        : AppTheme.accent,
                    width: 2,
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: isMaster
                    ? IconButton(
                        icon: const Icon(Icons.mic, color: AppTheme.accent),
                        onPressed: () {
                          // Speech-to-text placeholder
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Speech-to-text coming soon!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(wordBuilderProvider.notifier).onType(value);
                final newState = ref.read(wordBuilderProvider);
                // If Master reset, controller is cleared via the listener
                if (newState.lastFeedback == 'reset') {
                  HapticFeedback.heavyImpact();
                } else if (newState.lastFeedback == 'incorrect') {
                  HapticFeedback.mediumImpact();
                }

                if (newState.isScriptureComplete) {
                  HapticFeedback.heavyImpact();
                  _typingFocusNode.unfocus();
                  if (!newState.isComplete) {
                    Future.delayed(const Duration(milliseconds: 1000), () {
                      if (mounted) {
                        _typingController.clear();
                        ref
                            .read(wordBuilderProvider.notifier)
                            .nextScripture();
                        _typingFocusNode.requestFocus();
                      }
                    });
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTapHintDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Tap the next chunk',
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
    );
  }

  Widget _buildScriptureCompleteOverlay(WordBuilderState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: AppTheme.success, size: 48),
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
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToResults(WordBuilderState state) {
    _timer.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameResultsScreen(
          gameType: GameType.wordOrder,
          difficulty: widget.difficulty,
          correctMatches: state.correctUnitsAcrossAll,
          incorrectAttempts: state.incorrectAttempts,
          totalPairs: state.totalUnitsAcrossAll,
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
}
