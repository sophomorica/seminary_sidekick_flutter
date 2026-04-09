import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/enums.dart';
import '../../../models/scripture.dart';
import '../../../providers/activity_provider.dart';
import '../../../providers/progress_provider.dart';
import '../../../providers/word_builder_provider.dart';
import '../../../services/audio_service.dart';
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
  late AnimationController _slotPulseController;

  int? _shakingPoolIndex;

  // Typing mode
  final _typingController = TextEditingController();
  final _typingFocusNode = FocusNode();

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
      // For typing mode: if a Master reset happened, clear the text controller.
      // Do NOT clear _lastRecognizedText here — the speech recognizer sends
      // cumulative text, so clearing it would cause old words to replay.
      // Instead, _onSpeechResult stops listening on reset.
      if (next.lastFeedback == 'reset' && prev?.lastFeedback != 'reset') {
        _typingController.clear();
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () async {
          final shouldPop = await _onWillPop();
          if (!mounted) return;
          if (shouldPop) Navigator.of(context).pop();
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.currentScripture?.reference ?? '',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              // Difficulty badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: difficultyColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Text(
                  widget.difficulty.label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: difficultyColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),

            ],
          ),
        ],
      ),
      actions: [
        // Timer
        Padding(
          padding: const EdgeInsets.only(right: AppTheme.spacingMd),
          child: Center(
            child: Text(
              '$minutes:$seconds',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
          ),
        ),
        // Audio toggle
        IconButton(
          icon: Icon(
            ref.watch(audioProvider).isMuted
                ? Icons.volume_off
                : Icons.volume_up,
            size: 20,
          ),
          onPressed: () => ref.read(audioProvider.notifier).toggleMute(),
          tooltip: ref.watch(audioProvider).isMuted ? 'Unmute' : 'Mute',
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
    return Column(
      children: [
        // Mastery progress bar (thin, elegant)
        _buildMasteryProgressBar(state),

        // Scripture reference and topic
        _buildScriptureHeader(state),

        // Placed chunks area (scripture canvas)
        Expanded(
          flex: 3,
          child: _buildPlacedChunksArea(state),
        ),

        // Divider with hint text
        _buildTapHintDivider(),

        // Chunk pool (word choice grid)
        Expanded(
          flex: 2,
          child: state.isScriptureComplete
              ? _buildScriptureCompleteOverlay(state)
              : _buildChunkPool(state),
        ),

        const SizedBox(height: AppTheme.spacingMd),
      ],
    );
  }

  Widget _buildMasteryProgressBar(WordBuilderState state) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingMd,
      ),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: LinearProgressIndicator(
          value: state.scriptureProgress,
          backgroundColor: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(
            _getDifficultyColor(widget.difficulty),
          ),
          minHeight: 3,
        ),
      ),
    );
  }

  Widget _buildScriptureHeader(WordBuilderState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            state.currentScripture?.name ?? '',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          // Progress info
          Text(
            '${state.currentIndex + 1} of ${state.totalScriptures}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacedChunksArea(WordBuilderState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingMd,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: AppTheme.editorialShadow,
        ),
        child: Wrap(
          spacing: AppTheme.spacingMd,
          runSpacing: AppTheme.spacingMd,
          alignment: WrapAlignment.center,
          children: List.generate(state.targetChunks.length, (index) {
            final placed = state.placedChunks[index];
            final target = state.targetChunks[index];
            final isNext =
                index == state.nextChunkIndex && !state.isScriptureComplete;
            final chunkColor =
                _chunkPalette[target.colorIndex % _chunkPalette.length];

            return AnimatedBuilder(
              animation: _slotPulseController,
              builder: (context, child) {
                final borderColor = isNext
                    ? Color.lerp(
                        chunkColor,
                        chunkColor.withValues(alpha: 0.3),
                        _slotPulseController.value,
                      )!
                    : Colors.transparent;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                    vertical: AppTheme.spacingSm,
                  ),
                  decoration: BoxDecoration(
                    color: placed != null
                        ? chunkColor.withValues(alpha: 0.15)
                        : (isNext
                            ? chunkColor.withValues(alpha: 0.08)
                            : Theme.of(context).colorScheme.surface),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: isNext
                        ? Border.all(
                            color: borderColor,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Text(
                    placed?.text ?? _chunkPlaceholder(target),
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      fontFamily: 'Merriweather',
                      fontWeight:
                          placed != null ? FontWeight.w700 : FontWeight.w500,
                      color: placed != null
                          ? chunkColor.withValues(alpha: 0.95)
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.35),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  String _chunkPlaceholder(WordChunk target) {
    // Show dashes for each word in the chunk
    return target.words.map((w) => '─' * w.length.clamp(2, 6)).join(' ');
  }

  Widget _buildChunkPool(WordBuilderState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Wrap(
        spacing: AppTheme.spacingMd,
        runSpacing: AppTheme.spacingMd,
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
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                    vertical: AppTheme.spacingSm,
                  ),
                  decoration: BoxDecoration(
                    color: tileColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
                      fontSize: 16,
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
      HapticFeedback.lightImpact();
      ref.read(audioProvider.notifier).play(SoundEffect.correct);
      _pulseController.forward(from: 0);

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
    return Column(
      children: [
        // Mastery progress bar
        _buildMasteryProgressBar(state),

        // Scripture reference and topic
        _buildScriptureHeader(state),

        // Typed text display (scripture canvas for typing)
        Expanded(
          flex: 4,
          child: _buildTypedTextDisplay(state),
        ),

        // Feedback banner for Master resets
        if (state.lastFeedback == 'reset') _buildResetBanner(),

        // Text input area
        if (!state.isScriptureComplete) _buildTypingInput(state),

        if (state.isScriptureComplete)
          Expanded(
            flex: 1,
            child: _buildScriptureCompleteOverlay(state),
          ),

        const SizedBox(height: AppTheme.spacingMd),
      ],
    );
  }

  Widget _buildTypedTextDisplay(WordBuilderState state) {
    // Show the passage with typed characters colored green/red,
    // and remaining text as gray placeholders.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: AppTheme.editorialShadow,
        ),
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 18,
              height: 1.8,
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
                color: AppTheme.accent.withValues(alpha: 0.5),
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

  Widget _buildResetBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppTheme.spacingMd,
        horizontal: AppTheme.spacingLg,
      ),
      color: AppTheme.error.withValues(alpha: 0.12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.refresh,
            color: AppTheme.error,
            size: 18,
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
    );
  }

  Widget _buildTypingInput(WordBuilderState state) {
    final isMaster = widget.difficulty == DifficultyLevel.master;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingLg,
        AppTheme.spacingMd,
        AppTheme.spacingLg,
        AppTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHigh,
          ),
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
                hintStyle: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.35),
                ),
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide(
                    color: state.hasActiveError
                        ? AppTheme.error
                        : _getDifficultyColor(widget.difficulty),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingMd,
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
                ref.read(wordBuilderProvider.notifier).onType(value);
                final newState = ref.read(wordBuilderProvider);
                // If Master reset, controller is cleared via the listener
                if (newState.lastFeedback == 'reset') {
                  HapticFeedback.heavyImpact();
                  ref.read(audioProvider.notifier).play(SoundEffect.incorrect);
                } else if (newState.lastFeedback == 'incorrect') {
                  HapticFeedback.mediumImpact();
                  ref.read(audioProvider.notifier).play(SoundEffect.incorrect);
                }

                if (newState.isScriptureComplete) {
                  HapticFeedback.heavyImpact();
                  _typingFocusNode.unfocus();
                  if (!newState.isComplete) {
                    Future.delayed(const Duration(milliseconds: 1000), () {
                      if (mounted) {
                        _typingController.clear();
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

      HapticFeedback.heavyImpact();
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

      HapticFeedback.heavyImpact();
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

  Widget _buildTapHintDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHigh,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            child: Text(
              'Tap the next word',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHigh,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScriptureCompleteOverlay(WordBuilderState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            color: AppTheme.success,
            size: 56,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            state.isComplete ? 'All Done!' : 'Scripture Complete!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.success,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (!state.isComplete) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Loading next scripture...',
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
