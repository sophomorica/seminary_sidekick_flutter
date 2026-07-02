import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/scriptures_data.dart';
import '../../../models/group_sb_config.dart';
import '../../../models/scripture.dart';
import '../../../services/audio_service.dart';
import '../../../services/haptic_service.dart';
import '../../../theme/app_theme.dart';

/// Chunk-tap board for the group Scripture Builder race.
///
/// **Intentionally a fork** of `lib/screens/games/scripture_builder/scripture_builder_screen.dart`
/// rather than a shared widget. Solo Scripture Builder writes through to personal
/// mastery (progress_provider); the race must never touch personal mastery.
/// Forking guarantees that promise — there's no chance a future refactor of
/// the solo board accidentally imports `progress_provider` into the race.
///
/// The board owns its own local chunk state. On completion it calls
/// [onFinish] with `(elapsedMs, mistakeCount)`; the parent screen records the
/// finish in Supabase via `groupPlayProvider.submitSbFinish`.
class SbRaceBoard extends ConsumerStatefulWidget {
  /// The scripture being raced.
  final Scripture scripture;

  /// Difficulty for chunk sizing + distractor inclusion.
  final GroupSbChunkDifficulty chunkDifficulty;

  /// Pool of other in-scope scriptures used for distractor chunks (Intermediate
  /// only). Distractors are drawn from this pool — never from out-of-scope
  /// scriptures, so the host's curated set doesn't get polluted by surprise
  /// references. When the host picked exactly one scripture, this is empty and
  /// Intermediate visually degrades to "Beginner-with-2-word-chunks".
  final List<Scripture> distractorPool;

  /// Called once when the player completes the scripture.
  /// `elapsedMs` is the wall-clock time since this board was first built;
  /// `mistakeCount` is the number of wrong chunk taps.
  final void Function(int elapsedMs, int mistakeCount) onFinish;

  /// Resets the internal stopwatch when this key changes. Pass the scripture
  /// index from the parent so a Round-by-Round host advance re-instantiates
  /// the board fresh.
  const SbRaceBoard({
    super.key,
    required this.scripture,
    required this.chunkDifficulty,
    required this.distractorPool,
    required this.onFinish,
  });

  @override
  ConsumerState<SbRaceBoard> createState() => _WbRaceBoardState();
}

class _WbRaceBoardState extends ConsumerState<SbRaceBoard>
    with TickerProviderStateMixin {
  late final DateTime _startedAt;
  final List<_RaceChunk> _targetChunks = [];
  final List<_RaceChunk> _pool = [];
  final Set<int> _usedPoolIndices = {};
  final List<_RaceChunk?> _placedChunks = [];
  int _nextSlot = 0;
  int _mistakeCount = 0;
  bool _finished = false;

  // Animation: shake the chip the user just tapped if wrong.
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  int? _shakingPoolIndex;

  // Chunk colors for visual distinction — copied from solo board so the
  // palette feels familiar.
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
    _startedAt = DateTime.now();
    _buildBoard();

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
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _buildBoard() {
    final words = widget.scripture.words;
    final size = widget.chunkDifficulty.chunkSize;
    final rng = Random();

    final chunks = <_RaceChunk>[];
    var colorIdx = 0;
    for (var i = 0; i < words.length; i += size) {
      final end = min(i + size, words.length);
      chunks.add(_RaceChunk(
        words: words.sublist(i, end),
        startIndex: i,
        colorIndex: colorIdx % _chunkPalette.length,
      ));
      colorIdx++;
    }
    _targetChunks
      ..clear()
      ..addAll(chunks);

    _placedChunks
      ..clear()
      ..addAll(List<_RaceChunk?>.filled(chunks.length, null));

    final pool = List<_RaceChunk>.from(chunks);
    if (widget.chunkDifficulty.hasDistractors &&
        widget.distractorPool.isNotEmpty) {
      // Match solo Intermediate's extraDistractors count (3) so the race
      // feels equivalent to the solo experience at the same difficulty.
      const distractorCount = 3;
      final others = List<Scripture>.from(widget.distractorPool)
        ..shuffle(rng);
      for (final s in others) {
        if (pool.length - chunks.length >= distractorCount) break;
        final w = s.words;
        if (w.length < size) continue;
        final start = rng.nextInt(max(1, w.length - size));
        pool.add(_RaceChunk(
          words: w.sublist(start, min(start + size, w.length)),
          startIndex: -1,
          isDistractor: true,
          colorIndex: -1,
        ));
      }
    }
    pool.shuffle(rng);
    _pool
      ..clear()
      ..addAll(pool);
  }

  void _onChunkTapped(int poolIndex) {
    if (_finished) return;
    if (_usedPoolIndices.contains(poolIndex)) return;

    final tapped = _pool[poolIndex];
    final expected = _targetChunks[_nextSlot];

    if (!tapped.isDistractor && tapped.startIndex == expected.startIndex) {
      // Correct
      setState(() {
        _placedChunks[_nextSlot] = tapped;
        _usedPoolIndices.add(poolIndex);
        _nextSlot++;
      });
      ref.read(hapticProvider).light();
      ref.read(audioProvider.notifier).play(SoundEffect.correct);

      if (_nextSlot >= _targetChunks.length && !_finished) {
        _finished = true;
        final elapsed = DateTime.now().difference(_startedAt).inMilliseconds;
        // Hand control back to the parent. Fire on the next frame so the last
        // chunk's "placed" visual paints before the screen swaps.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.onFinish(elapsed, _mistakeCount);
        });
      }
    } else {
      // Wrong tap — shake, no scoring penalty in v1 (tracked only)
      _mistakeCount++;
      ref.read(hapticProvider).medium();
      ref.read(audioProvider.notifier).play(SoundEffect.incorrect);
      setState(() => _shakingPoolIndex = poolIndex);
      _shakeController.forward(from: 0).then((_) {
        if (!mounted) return;
        setState(() => _shakingPoolIndex = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _targetChunks.isEmpty
        ? 0.0
        : _nextSlot / _targetChunks.length;

    return Column(
      children: [
        // ─── Progress bar ───
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: 4,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              minHeight: 3,
            ),
          ),
        ),
        // ─── Scripture canvas ───
        Expanded(
          flex: 2,
          child: _buildCanvas(theme),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          child: Divider(color: theme.colorScheme.surfaceContainerHigh),
        ),
        // ─── Chunk pool ───
        Expanded(
          flex: 3,
          child: _buildPool(theme),
        ),
      ],
    );
  }

  Widget _buildCanvas(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd, vertical: 4),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 22,
            height: 1.6,
            fontFamily: 'Merriweather',
            color: theme.colorScheme.onSurface,
          ),
          children: _buildCanvasSpans(theme),
        ),
      ),
    );
  }

  List<InlineSpan> _buildCanvasSpans(ThemeData theme) {
    final spans = <InlineSpan>[];
    final color = theme.colorScheme.primary;
    for (var i = 0; i < _targetChunks.length; i++) {
      final placed = _placedChunks[i];
      final target = _targetChunks[i];
      final isNext = i == _nextSlot && !_finished;

      if (i > 0) spans.add(const TextSpan(text: ' '));

      if (placed != null) {
        spans.add(TextSpan(
          text: placed.text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
            decorationColor: color.withValues(alpha: 0.2),
          ),
        ));
      } else if (isNext) {
        final placeholder = '─' * target.text.length.clamp(3, 10);
        spans.add(TextSpan(
          text: placeholder,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
            letterSpacing: 2,
            decoration: TextDecoration.underline,
            decorationColor: color.withValues(alpha: 0.5),
            decorationStyle: TextDecorationStyle.dashed,
          ),
        ));
      } else {
        final hidden =
            target.words.map((w) => '_' * w.length.clamp(2, 8)).join(' ');
        spans.add(TextSpan(
          text: hidden,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
            letterSpacing: 1,
          ),
        ));
      }
    }
    return spans;
  }

  Widget _buildPool(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingSm,
        AppTheme.spacingSm,
        AppTheme.spacingSm,
        AppTheme.spacingXl + AppTheme.spacingLg,
      ),
      child: Wrap(
        spacing: AppTheme.spacingSm,
        runSpacing: AppTheme.spacingSm,
        alignment: WrapAlignment.center,
        children: List.generate(_pool.length, (index) {
          final chunk = _pool[index];
          final isShaking = _shakingPoolIndex == index;
          final isUsed = _usedPoolIndices.contains(index);
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
                                  : theme.colorScheme.onSurface),
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
}

/// Local chunk model — intentionally private and detached from the solo
/// board's [WordChunk] type so the race board can never import progress
/// recording by accident.
class _RaceChunk {
  final List<String> words;
  final int startIndex;
  final bool isDistractor;
  final int colorIndex;

  const _RaceChunk({
    required this.words,
    required this.startIndex,
    this.isDistractor = false,
    this.colorIndex = 0,
  });

  String get text => words.join(' ');
}

/// Resolves an in-scope distractor pool: every scripture in [scope] except
/// the one currently being raced. Helper so the parent screen doesn't have
/// to recompute on every build.
List<Scripture> distractorPoolFor({
  required List<String> scopeIds,
  required String excludeId,
}) {
  final byId = {for (final s in allScriptures) s.id: s};
  final out = <Scripture>[];
  for (final id in scopeIds) {
    if (id == excludeId) continue;
    final s = byId[id];
    if (s != null) out.add(s);
  }
  return out;
}
