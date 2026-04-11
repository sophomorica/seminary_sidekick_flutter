import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/enums.dart';
import '../../../models/scripture.dart';
import '../../../providers/activity_provider.dart';
import '../../../providers/progress_provider.dart';
import '../../../providers/word_builder_provider.dart';
import '../../../services/audio_service.dart';
import '../../../services/haptic_service.dart';
import '../../../services/speech_service.dart';
import '../../../theme/app_theme.dart';
import '../game_results_screen.dart';

class WordBuilderScreen extends ConsumerStatefulWidget {
  final DifficultyLevel difficulty;
  final ScriptureBook? bookFilter;
  final List<Scripture>? scriptures;

  const WordBuilderScreen({
    super.key,
    required this.difficulty,
    this.bookFilter,
    this.scriptures,
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
  int? _shakingPoolIndex;

  // Typing mode
  final _typingController = TextEditingController();
  final _typingFocusNode = FocusNode();
  bool _isResetting = false; // Guard against onChanged re-triggers during reset

  // Speech-to-text
  final _speechService = SpeechService.instance;
  bool _isSpeechListening = false;
  String _lastRecognizedText = '';

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
            scriptures: widget.scriptures,
          );
      // For typing modes, ensure the text field gets focus after the
      // game state is ready. autofocus alone can be unreliable on iOS
      // when launching via Navigator.push from certain screens.
      if (widget.difficulty == DifficultyLevel.advanced ||
          widget.difficulty == DifficultyLevel.master) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !_typingFocusNode.hasFocus) {
            _typingFocusNode.requestFocus();
          }
        });
      }
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
  }

  @override
  void dispose() {
    _timer.cancel();
    _shakeController.dispose();
    _pulseController.dispose();
    _typingController.dispose();
    _typingFocusNode.dispose();
    _speechService.stopListening();
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
        ref.read(audioProvider.notifier).play(SoundEffect.complete);
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _navigateToResults(next);
        });
      }
      // For typing mode: if a Master reset happened, clear the controller
      // and re-focus so the user can immediately start typing again.
      if (next.lastFeedback == 'reset' && prev?.lastFeedback != 'reset') {
        _isResetting = true;
        _typingController.clear();
        // Wait for the current frame to finish before re-enabling input.
        // This prevents the onChanged callback from firing with stale text
        // while the widget tree is still rebuilding.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _isResetting = false;
          // Re-request focus after the build is fully complete
          if (!_typingFocusNode.hasFocus) {
            _typingFocusNode.requestFocus();
          }
        });
      }
      // Reset hint when scripture changes
      if (next.currentIndex != (prev?.currentIndex ?? -1)) {
        setState(() => _hintRevealed = false);
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(state),
      body: state.currentScripture == null
          ? const Center(child: CircularProgressIndicator())
          : (state.mode == WordBuilderMode.chunkTap
              ? _buildChunkTapBody(state)
              : _buildTypingBody(state)),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════════

  PreferredSizeWidget _buildAppBar(WordBuilderState state) {
    final minutes = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final difficultyColor = _getDifficultyColor(widget.difficulty);

    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      toolbarHeight: 40,
      leadingWidth: 40,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, size: 20),
        onPressed: () async {
          final shouldPop = await _onWillPop();
          if (!mounted) return;
          if (shouldPop) Navigator.of(context).pop();
        },
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          // Scripture reference
          Text(
            state.currentScripture?.reference ?? '',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          // Difficulty badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: difficultyColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              widget.difficulty.label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: difficultyColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                  ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Text(
            '${state.currentIndex + 1}/${state.totalScriptures}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                  fontSize: 9,
                ),
          ),
        ],
      ),
      actions: [
        // Timer
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Text(
            '$minutes:$seconds',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
          ),
        ),
        // Audio toggle
        IconButton(
          icon: Icon(
            ref.watch(audioProvider).isMuted
                ? Icons.volume_off
                : Icons.volume_up,
            size: 18,
          ),
          onPressed: () => ref.read(audioProvider.notifier).toggleMute(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ],
    );
  }

  Color _getDifficultyColor(DifficultyLevel difficulty) {
    return switch (difficulty) {
      DifficultyLevel.beginner => AppTheme.secondary,
      DifficultyLevel.intermediate => AppTheme.primary,
      DifficultyLevel.advanced => AppTheme.accent,
      DifficultyLevel.master => AppTheme.tertiary,
    };
  }

  // ═══════════════════════════════════════════════════════════════
  // CHUNK-TAP MODE (Beginner / Intermediate)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildChunkTapBody(WordBuilderState state) {
    if (state.isScriptureComplete) {
      // Only show the overlay, scrollable if needed
      return _buildScriptureCompleteOverlay(state);
    }
    return Column(
      children: [
        // Mastery progress bar (thin)
        _buildMasteryProgressBar(state),

        // Scripture canvas — flowing text with inline placeholders
        Expanded(
          flex: 2,
          child: _buildScriptureCanvas(state),
        ),

        // Divider with hint embedded
        _buildHintDivider(state),

        // Chunk pool (word choice grid) — gets MORE space
        Expanded(
          flex: 3,
          child: _buildChunkPool(state),
        ),
      ],
    );
  }

  Widget _buildMasteryProgressBar(WordBuilderState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: 4,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: LinearProgressIndicator(
          value: state.scriptureProgress,
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(
            _getDifficultyColor(widget.difficulty),
          ),
          minHeight: 3,
        ),
      ),
    );
  }

  bool _hintRevealed = false;

  /// Combined divider + hint row. Hint is always visible between the canvas
  /// and the chip pool — no scrolling needed to find it.
  Widget _buildHintDivider(WordBuilderState state) {
    final keyPhrase = state.currentScripture?.keyPhrase ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
            ),
          ),
          if (keyPhrase.isNotEmpty && !state.isScriptureComplete)
            Flexible(
              flex: 0,
              child: GestureDetector(
                onTap: () => setState(() => _hintRevealed = !_hintRevealed),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.55,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSm),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        size: 14,
                        color: AppTheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _hintRevealed ? keyPhrase : 'Hint',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppTheme.secondary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm),
              child: Text(
                'Tap the next chunk',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.35),
                      fontStyle: FontStyle.italic,
                      fontSize: 10,
                    ),
              ),
            ),
          Expanded(
            child: Divider(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
            ),
          ),
        ],
      ),
    );
  }

  /// Scripture canvas: placed words render as flowing inline text (like the
  /// design reference). The next slot is a dashed underline. Future slots are
  /// faded placeholder text. No chip containers — just natural paragraph flow.
  Widget _buildScriptureCanvas(WordBuilderState state) {
    final diffColor = _getDifficultyColor(widget.difficulty);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd, vertical: 4),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 22,
            height: 1.6,
            fontFamily: 'Merriweather',
            color: Theme.of(context).colorScheme.onSurface,
          ),
          children: _buildCanvasSpans(state, diffColor),
        ),
      ),
    );
  }

  List<InlineSpan> _buildCanvasSpans(WordBuilderState state, Color diffColor) {
    final spans = <InlineSpan>[];

    for (int i = 0; i < state.targetChunks.length; i++) {
      final placed = state.placedChunks[i];
      final target = state.targetChunks[i];
      final isNext = i == state.nextChunkIndex && !state.isScriptureComplete;

      if (i > 0) {
        // Space between chunks
        spans.add(const TextSpan(text: ' '));
      }

      if (placed != null) {
        // ── Already placed: show as bold colored text ──
        spans.add(TextSpan(
          text: placed.text,
          style: TextStyle(
            color: diffColor,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
            decorationColor: diffColor.withValues(alpha: 0.2),
            decorationStyle: TextDecorationStyle.solid,
          ),
        ));
      } else if (isNext) {
        // ── Next slot: dashed underline placeholder ──
        final placeholder = '─' * target.text.length.clamp(3, 10);
        spans.add(TextSpan(
          text: placeholder,
          style: TextStyle(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
            letterSpacing: 2,
            decoration: TextDecoration.underline,
            decorationColor: diffColor.withValues(alpha: 0.5),
            decorationStyle: TextDecorationStyle.dashed,
          ),
        ));
      } else {
        // ── Future slots: uniform underscores, no readable text ──
        // Each word in the chunk becomes a run of underscores,
        // separated by spaces to preserve word-break flow.
        final hidden =
            target.words.map((w) => '_' * w.length.clamp(2, 8)).join(' ');
        spans.add(TextSpan(
          text: hidden,
          style: TextStyle(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10),
            letterSpacing: 1,
          ),
        ));
      }
    }

    return spans;
  }

  Widget _buildChunkPool(WordBuilderState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingSm,
        AppTheme.spacingSm,
        AppTheme.spacingSm,
        // Extra bottom padding so the last row is fully accessible
        AppTheme.spacingXl + AppTheme.spacingLg,
      ),
      child: Wrap(
        spacing: AppTheme.spacingSm,
        runSpacing: AppTheme.spacingSm,
        alignment: WrapAlignment.center,
        children: List.generate(state.availablePool.length, (index) {
          final chunk = state.availablePool[index];
          final isShaking = _shakingPoolIndex == index;
          final chunkColor =
              _chunkPalette[chunk.colorIndex % _chunkPalette.length];
          final tileColor = chunk.isDistractor
              ? AppTheme.error.withValues(alpha: 0.08)
              : chunkColor.withValues(alpha: 0.08);

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
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tileColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    boxShadow: isShaking
                        ? [
                            BoxShadow(
                              color: AppTheme.error.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : AppTheme.editorialShadow,
                  ),
                  child: Text(
                    chunk.text,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Merriweather',
                      fontWeight: FontWeight.w600,
                      color: isShaking
                          ? AppTheme.error
                          : (chunk.isDistractor
                              ? AppTheme.error.withValues(alpha: 0.6)
                              : Theme.of(context).colorScheme.onSurface),
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
      ref.read(hapticProvider).light();
      ref.read(audioProvider.notifier).play(SoundEffect.correct);
      _pulseController.forward(from: 0);

      if (newState.isScriptureComplete) {
        ref.read(hapticProvider).heavy();
        if (!newState.isComplete) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              ref.read(wordBuilderProvider.notifier).nextScripture();
            }
          });
        }
      }
    } else if (newState.lastFeedback == 'incorrect') {
      ref.read(hapticProvider).medium();
      ref.read(audioProvider.notifier).play(SoundEffect.incorrect);
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
    if (state.isScriptureComplete) {
      // Only show the overlay, scrollable if needed
      return _buildScriptureCompleteOverlay(state);
    }

    // Active typing layout: input pinned at bottom, text display fills rest.
    // IMPORTANT: The widget tree structure must stay stable across state
    // changes (e.g. reset banner appearing/disappearing). If children are
    // conditionally added/removed, Flutter can't match the TextField across
    // rebuilds, causing it to be recreated and lose focus.
    return SafeArea(
      top: false,
      child: Column(
        children: [
          // Progress bar
          _buildMasteryProgressBar(state),

          // Typed text display fills available space
          Expanded(
            child: _buildTypedTextDisplay(state),
          ),

          // Reset banner — always present in tree, just animated visible/hidden
          // so the TextField below never loses its position in the widget tree.
          _buildResetBanner(visible: state.lastFeedback == 'reset'),

          // Input is always last — never hidden by Expanded
          _buildTypingInput(state),
        ],
      ),
    );
  }

  Widget _buildTypedTextDisplay(WordBuilderState state) {
    // Show the passage with typed characters colored green/red,
    // and remaining text as gray placeholders.
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: 4,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.editorialShadow,
        ),
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              fontFamily: 'Merriweather',
              color: Theme.of(context).colorScheme.onSurface,
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
            fontWeight: FontWeight.w700,
            backgroundColor: tc.isCorrect
                ? AppTheme.success.withValues(alpha: 0.1)
                : AppTheme.error.withValues(alpha: 0.15),
            decoration: tc.isCorrect ? null : TextDecoration.underline,
            decorationColor: AppTheme.error,
          ),
        ));
      } else if (i >= typed.length &&
          !isMaster &&
          i == _nextLetterIndex(target, typed.length)) {
        // Cursor position (Advanced only) — highlight the next letter the user
        // needs to type (skipping auto-filled punctuation/spaces)
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
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.25),
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
                color: AppTheme.accent.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ));
          } else {
            spans.add(TextSpan(
              text: '_',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.25),
                letterSpacing: 1,
              ),
            ));
          }
        }
      }
    }

    return spans;
  }

  /// Find the index of the next actual letter/digit in the target,
  /// skipping spaces and punctuation (which are auto-filled).
  int _nextLetterIndex(String target, int from) {
    int i = from;
    while (i < target.length) {
      final ch = target[i];
      if (ch != ' ' &&
          ch != '\n' &&
          !RegExp(r'''[,;:!?\-\—\–\.\'\"\'\'\"\"\(\)\[\]]''').hasMatch(ch)) {
        return i;
      }
      i++;
    }
    return from; // fallback
  }

  Widget _buildResetBanner({bool visible = true}) {
    // Always present in widget tree to keep Column children stable.
    // Uses AnimatedSize + ClipRect so it collapses to zero height when hidden
    // without removing the widget (which would shift TextField's tree position).
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: visible
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: AppTheme.spacingSm,
                horizontal: AppTheme.spacingMd,
              ),
              color: AppTheme.error.withValues(alpha: 0.12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.refresh,
                    color: AppTheme.error,
                    size: 16,
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(
                    'Wrong character! Starting over...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildTypingInput(WordBuilderState state) {
    final isMaster = widget.difficulty == DifficultyLevel.master;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingSm,
        AppTheme.spacingMd,
        AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('wb_typing_field'),
              controller: _typingController,
              focusNode: _typingFocusNode,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                hintText: state.hasActiveError
                    ? 'Delete the error and try again...'
                    : (isMaster
                        ? 'Type from memory — no peeking!'
                        : 'Type the scripture (first letters shown)...'),
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.35),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  borderSide: BorderSide(
                    color: state.hasActiveError
                        ? AppTheme.error
                        : _getDifficultyColor(widget.difficulty),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: AppTheme.spacingSm,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isSpeechListening ? Icons.mic_off : Icons.mic,
                    color: _isSpeechListening
                        ? AppTheme.error
                        : _getDifficultyColor(widget.difficulty),
                  ),
                  onPressed: _toggleSpeechListening,
                ),
              ),
              onChanged: (value) {
                // Skip if we're in the middle of a programmatic reset/clear
                if (_isResetting) return;

                ref.read(wordBuilderProvider.notifier).onType(value);
                final newState = ref.read(wordBuilderProvider);

                if (newState.lastFeedback == 'reset') {
                  ref.read(hapticProvider).heavy();
                  ref.read(audioProvider.notifier).play(SoundEffect.incorrect);
                  // Don't do anything else — the listener handles clearing
                  return;
                } else if (newState.lastFeedback == 'incorrect') {
                  ref.read(hapticProvider).medium();
                  ref.read(audioProvider.notifier).play(SoundEffect.incorrect);
                }

                if (newState.isScriptureComplete) {
                  ref.read(hapticProvider).heavy();
                  _typingFocusNode.unfocus();
                  if (!newState.isComplete) {
                    Future.delayed(const Duration(milliseconds: 1000), () {
                      if (mounted) {
                        _isResetting = true;
                        _typingController.clear();
                        _isResetting = false;
                        ref.read(wordBuilderProvider.notifier).nextScripture();
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
  // SPEECH-TO-TEXT
  // ═══════════════════════════════════════════════════════════════

  Future<void> _toggleSpeechListening() async {
    if (_isSpeechListening) {
      await _speechService.stopListening();
      setState(() => _isSpeechListening = false);
      return;
    }

    // Start listening
    setState(() {
      _isSpeechListening = true;
      _lastRecognizedText = '';
    });

    await _speechService.startListening(
      onResult: _onSpeechResult,
      onError: (errorMessage) {
        if (!mounted) return;
        setState(() => _isSpeechListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 3),
          ),
        );
      },
    );

    // If initialization failed (service set _isListening back to false)
    if (!_speechService.isListening && mounted) {
      setState(() => _isSpeechListening = false);
    }
  }

  /// Called whenever the speech recognizer has new text.
  /// Extracts only the newly recognized words and feeds them through the
  /// word-based speech input handler, which handles homophones, punctuation,
  /// and capitalization automatically.
  void _onSpeechResult(String recognizedText) {
    if (!mounted) return;

    // The recognizer sends the full cumulative text each time.
    // Extract only the new portion since our last callback.
    final newText = recognizedText.length > _lastRecognizedText.length
        ? recognizedText.substring(_lastRecognizedText.length).trim()
        : '';
    _lastRecognizedText = recognizedText;

    if (newText.isEmpty) return;

    final notifier = ref.read(wordBuilderProvider.notifier);

    // Use word-based speech processing (handles homophones, case, punctuation)
    final didReset = notifier.onSpeechInput(newText);

    if (didReset) {
      // Master reset happened — stop listening immediately to prevent
      // stale speech text from replaying and causing cascading resets.
      _typingController.clear();
      _speechService.stopListening();
      setState(() => _isSpeechListening = false);

      ref.read(hapticProvider).heavy();
      ref.read(audioProvider.notifier).play(SoundEffect.incorrect);
      return;
    }

    final stateAfter = ref.read(wordBuilderProvider);

    // Keep text controller in sync with provider state
    _typingController.text = stateAfter.typedText;
    _typingController.selection = TextSelection.collapsed(
      offset: _typingController.text.length,
    );

    if (stateAfter.isScriptureComplete) {
      _speechService.stopListening();
      setState(() => _isSpeechListening = false);

      ref.read(hapticProvider).heavy();
      _typingFocusNode.unfocus();
      if (!stateAfter.isComplete) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            _typingController.clear();
            _lastRecognizedText = '';
            ref.read(wordBuilderProvider.notifier).nextScripture();
          }
        });
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildScriptureCompleteOverlay(WordBuilderState state) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: AppTheme.success,
              size: 40,
            ),
            const SizedBox(height: AppTheme.spacingSm),
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
                'Loading next...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToResults(WordBuilderState state) {
    _timer.cancel();

    // Record an attempt for each scripture in the session
    final progressNotifier = ref.read(progressProvider.notifier);
    final activityNotifier = ref.read(activityProvider.notifier);
    final timeInSeconds = (state.completionTime ?? _elapsed).inSeconds;
    for (final scripture in state.scriptureQueue) {
      // Capture previous mastery level before recording
      final prevProgress =
          progressNotifier.getProgress(scripture.id, GameType.wordOrder);
      final prevMastery =
          prevProgress?.masteryLevel ?? MasteryLevel.newScripture;
      final isFirstAttempt = prevProgress == null;

      progressNotifier.recordAttempt(
        scriptureId: scripture.id,
        gameType: GameType.wordOrder,
        correct: true, // All scriptures are completed at this point
        time: timeInSeconds,
        difficultyCompleted: widget.difficulty,
      );

      // Log game completion activity
      activityNotifier.logGameCompleted(
        scriptureId: scripture.id,
        scriptureReference: scripture.reference,
        gameType: GameType.wordOrder,
        difficulty: widget.difficulty,
        timeSeconds: timeInSeconds,
      );

      // Log first attempt
      if (isFirstAttempt) {
        activityNotifier.logFirstAttempt(
          scriptureId: scripture.id,
          scriptureReference: scripture.reference,
          gameType: GameType.wordOrder,
        );
      }

      // Check for mastery level-up
      final newProgress =
          progressNotifier.getProgress(scripture.id, GameType.wordOrder);
      final newMastery = newProgress?.masteryLevel ?? MasteryLevel.newScripture;
      if (newMastery.index > prevMastery.index) {
        activityNotifier.logMasteryLevelUp(
          scriptureId: scripture.id,
          scriptureReference: scripture.reference,
          previousLevel: prevMastery,
          newLevel: newMastery,
        );
      }

      // Check for streak milestones
      final newStreak = newProgress?.currentStreak ?? 0;
      if ([5, 10, 25, 50, 100].contains(newStreak)) {
        activityNotifier.logStreakMilestone(
          scriptureId: scripture.id,
          scriptureReference: scripture.reference,
          streakCount: newStreak,
          gameType: GameType.wordOrder,
        );
      }
    }

    // Log perfect run if no incorrect attempts
    if (state.incorrectAttempts == 0 && state.scriptureQueue.isNotEmpty) {
      activityNotifier.logPerfectRun(
        scriptureId: state.scriptureQueue.first.id,
        scriptureReference: state.scriptureQueue.first.reference,
        gameType: GameType.wordOrder,
        difficulty: widget.difficulty,
      );
    }

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
