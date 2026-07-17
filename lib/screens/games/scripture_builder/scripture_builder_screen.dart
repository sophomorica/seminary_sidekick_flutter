import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/enums.dart';
import '../../../models/scripture.dart';
import '../../../providers/activity_provider.dart';
import '../../../providers/progress_provider.dart';
import '../../../providers/scripture_builder_provider.dart';
import '../../../services/audio_service.dart';
import '../../../services/haptic_service.dart';
import '../../../theme/app_theme.dart';
import '../game_results_screen.dart';
import 'typed_display_rules.dart';
import 'typing_input_field.dart';

class ScriptureBuilderScreen extends ConsumerStatefulWidget {
  final DifficultyLevel difficulty;
  final ScriptureBook? bookFilter;
  final List<Scripture>? scriptures;

  const ScriptureBuilderScreen({
    super.key,
    required this.difficulty,
    this.bookFilter,
    this.scriptures,
  });

  @override
  ConsumerState<ScriptureBuilderScreen> createState() => _ScriptureBuilderScreenState();
}

class _ScriptureBuilderScreenState extends ConsumerState<ScriptureBuilderScreen>
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
  bool _advanceScheduled = false; // Completion handled for current scripture

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
      ref.read(scriptureBuilderProvider.notifier).startGame(
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
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scriptureBuilderProvider);

    ref.listen<ScriptureBuilderState>(scriptureBuilderProvider, (prev, next) {
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
      // Master word-commit: whenever the provider consumed the word buffer
      // (word committed, or a stray space swallowed), mirror that into the
      // controller so the field is empty for the next word. The guard is
      // released synchronously — unlike the reset path there is no rebuild
      // race here, and holding it until the next frame would drop the first
      // keystrokes of a fast typist's next word.
      if (widget.difficulty == DifficultyLevel.master &&
          next.mode == ScriptureBuilderMode.typing &&
          next.typedText.isEmpty &&
          _typingController.text.isNotEmpty) {
        _isResetting = true;
        _typingController.clear();
        _isResetting = false;
      }
      // Reset hint + completion guard when scripture changes
      if (next.currentIndex != (prev?.currentIndex ?? -1)) {
        _advanceScheduled = false;
        setState(() => _hintRevealed = false);
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(state),
      body: state.currentScripture == null
          ? const Center(child: CircularProgressIndicator())
          : (state.mode == ScriptureBuilderMode.chunkTap
              ? _buildChunkTapBody(state)
              : _buildTypingBody(state)),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════════

  PreferredSizeWidget _buildAppBar(ScriptureBuilderState state) {
    final minutes = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final difficultyColor = _getDifficultyColor(widget.difficulty);
    final isTablet = AppTheme.isTabletLandscape(context);
    final toolbarH = isTablet ? 56.0 : 40.0;
    final backSize = isTablet ? 22.0 : 20.0;
    final badgeSize = isTablet ? 10.0 : 9.0;
    final timerSize = isTablet ? 14.0 : 11.0;

    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      toolbarHeight: toolbarH,
      leadingWidth: isTablet ? 48 : 40,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, size: backSize),
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
                  fontFamily: isTablet ? 'Merriweather' : null,
                  fontSize: isTablet ? 18 : null,
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
                    fontSize: badgeSize,
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
                  fontSize: badgeSize,
                ),
          ),
        ],
      ),
      actions: [
        // Timer
        Padding(
          padding: EdgeInsets.only(right: isTablet ? 12 : 4),
          child: Text(
            '$minutes:$seconds',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  fontSize: timerSize,
                ),
          ),
        ),
        // Audio toggle
        Padding(
          padding: EdgeInsets.only(right: isTablet ? 16 : 0),
          child: IconButton(
            icon: Icon(
              ref.watch(audioProvider).isMuted
                  ? Icons.volume_off
                  : Icons.volume_up,
              size: isTablet ? 22 : 18,
            ),
            onPressed: () => ref.read(audioProvider.notifier).toggleMute(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ),
      ],
    );
  }

  Color _getDifficultyColor(DifficultyLevel difficulty) {
    return switch (difficulty) {
      DifficultyLevel.beginner => AppTheme.secondary,
      DifficultyLevel.intermediate => Theme.of(context).colorScheme.primary,
      DifficultyLevel.advanced => AppTheme.accent,
      DifficultyLevel.master => AppTheme.tertiary,
    };
  }

  // ═══════════════════════════════════════════════════════════════
  // CHUNK-TAP MODE (Beginner / Intermediate)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildChunkTapBody(ScriptureBuilderState state) {
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

  Widget _buildMasteryProgressBar(ScriptureBuilderState state) {
    final hPad = AppTheme.isTabletLandscape(context)
        ? 24.0
        : AppTheme.spacingMd;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: hPad,
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
  Widget _buildHintDivider(ScriptureBuilderState state) {
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
  Widget _buildScriptureCanvas(ScriptureBuilderState state) {
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

  List<InlineSpan> _buildCanvasSpans(ScriptureBuilderState state, Color diffColor) {
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

  Widget _buildChunkPool(ScriptureBuilderState state) {
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
          final isUsed = state.usedPoolIndices.contains(index);
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
            // Used chunks stay in place (preserving Wrap layout) but are
            // faded out and non-tappable so the remaining chips never shift
            // under the user's finger.
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isUsed ? 0.2 : 1.0,
              child: IgnorePointer(
                ignoring: isUsed,
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
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSm),
                        boxShadow: isShaking
                            ? [
                                BoxShadow(
                                  color:
                                      AppTheme.error.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : (isUsed ? null : AppTheme.editorialShadow),
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
              ),
            ),
          );
        }),
      ),
    );
  }

  void _onChunkTapped(int poolIndex) {
    final state = ref.read(scriptureBuilderProvider);
    if (state.isScriptureComplete || state.isComplete) return;

    ref.read(scriptureBuilderProvider.notifier).selectChunk(poolIndex);

    final newState = ref.read(scriptureBuilderProvider);
    if (newState.lastFeedback == 'correct') {
      ref.read(hapticProvider).light();
      ref.read(audioProvider.notifier).play(SoundEffect.correct);
      _pulseController.forward(from: 0);

      if (newState.isScriptureComplete) {
        ref.read(hapticProvider).heavy();
        if (!newState.isComplete) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              ref.read(scriptureBuilderProvider.notifier).nextScripture();
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
          ref.read(scriptureBuilderProvider.notifier).clearFeedback();
        }
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // TYPING MODE (Advanced / Master)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTypingBody(ScriptureBuilderState state) {
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

  Widget _buildTypedTextDisplay(ScriptureBuilderState state) {
    // Show the passage with typed characters colored green/red,
    // and remaining text as gray placeholders.
    final isTablet = AppTheme.isTabletLandscape(context);
    final card = Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 48 : AppTheme.spacingMd,
        vertical: isTablet ? 40 : AppTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(
          isTablet ? AppTheme.radiusLg : AppTheme.radiusMd,
        ),
        boxShadow: AppTheme.editorialShadow,
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: isTablet ? 21 : 16,
            height: isTablet ? 1.8 : 1.6,
            fontFamily: 'Merriweather',
            color: Theme.of(context).colorScheme.onSurface,
          ),
          children: _buildTypedSpans(state),
        ),
      ),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : AppTheme.spacingSm,
        vertical: 4,
      ),
      child: isTablet
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppTheme.builderReadingMaxWidth,
                ),
                child: card,
              ),
            )
          : card,
    );
  }

  List<TextSpan> _buildTypedSpans(ScriptureBuilderState state) {
    final spans = <TextSpan>[];
    final target = state.targetText;
    final typed = state.typedChars;
    final isMaster = widget.difficulty == DifficultyLevel.master;

    // For Advanced: pre-compute which indices are "first letter of a word"
    // so we can show those as hints. Never reveal any other untyped letter —
    // including the cursor position (that used to spoil the next character).
    final firstLetterIndices = isMaster
        ? const <int>{}
        : TypedDisplayRules.firstLetterIndices(target);

    // Subtle cursor chrome for Advanced: highlight the next letter slot the
    // user must type, without disclosing the character (unless it's already
    // a first-letter hint). Hidden while a red error is active — the required
    // action there is backspacing, not typing the next letter.
    final cursorIndex = isMaster || state.hasActiveError
        ? -1
        : TypedDisplayRules.nextLetterIndex(target, typed.length);

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
      } else {
        // Untyped — the glyph choice is centralized in TypedDisplayRules
        // (unit-tested) so this branch can never disclose a hidden letter:
        // spaces/newlines verbatim, first-letter hints on Advanced,
        // underscores for everything else (all of Master).
        final glyph = TypedDisplayRules.untypedGlyph(
          target,
          i,
          isMaster: isMaster,
          hintIndices: firstLetterIndices,
        );
        final atCursor = i == cursorIndex;
        final cursorBg = atCursor
            ? AppTheme.accent.withValues(alpha: 0.15)
            : null;
        if (glyph == ' ' || glyph == '\n') {
          spans.add(TextSpan(text: glyph));
        } else if (glyph == '_') {
          spans.add(TextSpan(
            text: '_',
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: atCursor ? 0.45 : 0.25),
              letterSpacing: 1,
              backgroundColor: cursorBg,
            ),
          ));
        } else {
          // First letter hint — show it dimly (bolden slightly at cursor)
          spans.add(TextSpan(
            text: glyph,
            style: TextStyle(
              color: AppTheme.accent.withValues(alpha: atCursor ? 0.95 : 0.7),
              fontWeight: atCursor ? FontWeight.w700 : FontWeight.w600,
              backgroundColor: cursorBg,
            ),
          ));
        }
      }
    }

    return spans;
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
                    'Wrong word! Starting over...',
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

  Widget _buildTypingInput(ScriptureBuilderState state) {
    final isMaster = widget.difficulty == DifficultyLevel.master;

    return SbTypingInputField(
      controller: _typingController,
      focusNode: _typingFocusNode,
      isMaster: isMaster,
      hasActiveError: state.hasActiveError,
      difficultyColor: _getDifficultyColor(widget.difficulty),
      onChanged: _handleTypingChanged,
      onSubmitted: isMaster ? _handleTypingSubmitted : null,
    );
  }

  void _handleTypingChanged(String value) {
    // Skip if we're in the middle of a programmatic reset/clear
    if (_isResetting) return;

    ref.read(scriptureBuilderProvider.notifier).onType(value);
    _afterTypingInput();
  }

  /// Master only: the keyboard's done key commits the current word, so the
  /// final word of a verse doesn't require a trailing space.
  void _handleTypingSubmitted(String value) {
    if (_isResetting) return;

    ref.read(scriptureBuilderProvider.notifier).submitWord(value);
    _afterTypingInput();

    // The done key dismisses the keyboard — bring it back unless the verse
    // just completed (the completion flow manages focus itself).
    if (!ref.read(scriptureBuilderProvider).isScriptureComplete) {
      _typingFocusNode.requestFocus();
    }
  }

  void _afterTypingInput() {
    final newState = ref.read(scriptureBuilderProvider);

    if (newState.lastFeedback == 'reset') {
      ref.read(hapticProvider).heavy();
      ref.read(audioProvider.notifier).play(SoundEffect.incorrect);
      // Don't do anything else — the listener handles clearing
      return;
    } else if (newState.lastFeedback == 'incorrect') {
      ref.read(hapticProvider).medium();
      ref.read(audioProvider.notifier).play(SoundEffect.incorrect);
    } else if (newState.lastFeedback == 'word') {
      // Master: a word was committed correctly. Haptic only — a per-word
      // ding would fire dozens of times per verse while the user is
      // heads-down typing (owner call, 2026-07-15; chunk-tap keeps its
      // per-chunk sound since taps are the whole interaction there).
      ref.read(hapticProvider).light();
    }

    // Only handle completion once per scripture: a second input event
    // arriving while the state is still complete (e.g. a double-tapped done
    // key) must not schedule a second nextScripture() and skip a verse.
    if (newState.isScriptureComplete && !_advanceScheduled) {
      _advanceScheduled = true;
      ref.read(hapticProvider).heavy();
      _typingFocusNode.unfocus();
      if (!newState.isComplete) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            _isResetting = true;
            _typingController.clear();
            _isResetting = false;
            ref.read(scriptureBuilderProvider.notifier).nextScripture();
            _typingFocusNode.requestFocus();
          }
        });
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildScriptureCompleteOverlay(ScriptureBuilderState state) {
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

  void _navigateToResults(ScriptureBuilderState state) {
    _timer.cancel();

    // Record an attempt for each scripture in the session
    final progressNotifier = ref.read(progressProvider.notifier);
    final activityNotifier = ref.read(activityProvider.notifier);
    final timeInSeconds = (state.completionTime ?? _elapsed).inSeconds;
    // True when any scripture in this session first crossed into Mastered —
    // drives the results screen's mastery banner + avatar level-up morph.
    var newlyMastered = false;
    // Per-scripture avatar badge for the results screen: shows where you are
    // on THIS scripture (primary = first in queue) after the round.
    AvatarStage? avatarAfter;
    for (final scripture in state.scriptureQueue) {
      // Capture previous mastery level before recording
      final prevProgress =
          progressNotifier.getProgress(scripture.id, GameType.scriptureBuilder);
      final prevMastery =
          prevProgress?.masteryLevel ?? MasteryLevel.newScripture;
      final isFirstAttempt = prevProgress == null;

      progressNotifier.recordAttempt(
        scriptureId: scripture.id,
        gameType: GameType.scriptureBuilder,
        correct: true, // All scriptures are completed at this point
        time: timeInSeconds,
        difficultyCompleted: widget.difficulty,
      );

      // Log game completion activity
      activityNotifier.logGameCompleted(
        scriptureId: scripture.id,
        scriptureReference: scripture.reference,
        gameType: GameType.scriptureBuilder,
        difficulty: widget.difficulty,
        timeSeconds: timeInSeconds,
      );

      // Log first attempt
      if (isFirstAttempt) {
        activityNotifier.logFirstAttempt(
          scriptureId: scripture.id,
          scriptureReference: scripture.reference,
          gameType: GameType.scriptureBuilder,
        );
      }

      // Check for mastery level-up
      final newProgress =
          progressNotifier.getProgress(scripture.id, GameType.scriptureBuilder);
      final newMastery = newProgress?.masteryLevel ?? MasteryLevel.newScripture;
      if (prevMastery.index < MasteryLevel.mastered.index &&
          newMastery.index >= MasteryLevel.mastered.index) {
        newlyMastered = true;
      }
      if (scripture.id == state.scriptureQueue.first.id) {
        avatarAfter = AvatarStage.forMasteryLevel(newMastery);
      }
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
          gameType: GameType.scriptureBuilder,
        );
        ref.read(audioProvider.notifier).play(SoundEffect.streakMilestone);
      }
    }

    // Log perfect run if no incorrect attempts
    if (state.incorrectAttempts == 0 && state.scriptureQueue.isNotEmpty) {
      activityNotifier.logPerfectRun(
        scriptureId: state.scriptureQueue.first.id,
        scriptureReference: state.scriptureQueue.first.reference,
        gameType: GameType.scriptureBuilder,
        difficulty: widget.difficulty,
      );
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameResultsScreen(
          gameType: GameType.scriptureBuilder,
          difficulty: widget.difficulty,
          correctMatches: state.correctUnitsAcrossAll,
          incorrectAttempts: state.incorrectAttempts,
          totalPairs: state.totalUnitsAcrossAll,
          completionTime: state.completionTime ?? _elapsed,
          starRating: state.starRating,
          isNewMastery: newlyMastered,
          avatarStageAfter: avatarAfter,
          tryAgainBuilder: _sessionBuilder(),
        ),
      ),
    );
  }

  /// Captures this session's config while mounted so Try Again can rebuild
  /// the same game after this State is disposed by [Navigator.pushReplacement].
  WidgetBuilder _sessionBuilder() {
    final difficulty = widget.difficulty;
    final bookFilter = widget.bookFilter;
    final scriptures = widget.scriptures;
    return (_) => ScriptureBuilderScreen(
          difficulty: difficulty,
          bookFilter: bookFilter,
          scriptures: scriptures,
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
