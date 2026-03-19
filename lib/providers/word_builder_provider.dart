import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scripture.dart';
import '../models/enums.dart';
import '../data/scriptures_data.dart';

// ─── Data classes ────────────────────────────────────────────────

/// A chunk of consecutive words displayed as a single tappable tile.
class WordChunk {
  final List<String> words;
  final int startIndex; // Position in the original passage (-1 for distractor)
  final bool isDistractor;
  final int colorIndex; // For visual distinction in beginner mode

  const WordChunk({
    required this.words,
    required this.startIndex,
    this.isDistractor = false,
    this.colorIndex = 0,
  });

  String get text => words.join(' ');
  int get wordCount => words.length;
}

/// Represents a character the user has typed in Advanced/Master mode.
class TypedChar {
  final String char;
  final bool isCorrect;

  const TypedChar({required this.char, required this.isCorrect});
}

// ─── Game mode enum ─────────────────────────────────────────────

/// The two fundamental interaction modes for Word Builder.
enum WordBuilderMode {
  chunkTap,  // Beginner & Intermediate: tap word chunks in order
  typing,    // Advanced & Master: type the passage character by character
}

// ─── State ──────────────────────────────────────────────────────

class WordBuilderState {
  final DifficultyLevel difficulty;
  final WordBuilderMode mode;
  final ScriptureBook? bookFilter;
  final Scripture? currentScripture;
  final List<Scripture> scriptureQueue;
  final int currentIndex;
  final int totalScriptures;

  // ── Chunk-tap mode fields ──
  final List<WordChunk> targetChunks;    // Chunks in correct order
  final List<WordChunk> availablePool;   // Shuffled pool of chunk tiles
  final List<WordChunk?> placedChunks;   // Placed chunks (null = empty slot)
  final int nextChunkIndex;              // Next empty slot to fill

  // ── Typing mode fields ──
  final String targetText;               // Full text to type
  final String typedText;                // What user has typed so far
  final List<TypedChar> typedChars;      // Per-character correctness
  final bool hasActiveError;             // Currently has a red character (Advanced)
  final int resetCount;                  // How many times Master reset

  // ── Shared scoring ──
  final int correctPlacements;           // Chunks or characters correct
  final int incorrectAttempts;           // Wrong taps or wrong chars
  final int totalUnitsAcrossAll;         // Total chunks/chars across all scriptures
  final int correctUnitsAcrossAll;       // Total correct across all scriptures

  // ── Game flow ──
  final bool isComplete;
  final bool isScriptureComplete;
  final DateTime startTime;
  final Duration? completionTime;
  final String? lastFeedback;            // 'correct', 'incorrect', 'reset', null

  const WordBuilderState({
    required this.difficulty,
    required this.mode,
    this.bookFilter,
    this.currentScripture,
    this.scriptureQueue = const [],
    this.currentIndex = 0,
    this.totalScriptures = 0,
    // Chunk mode
    this.targetChunks = const [],
    this.availablePool = const [],
    this.placedChunks = const [],
    this.nextChunkIndex = 0,
    // Typing mode
    this.targetText = '',
    this.typedText = '',
    this.typedChars = const [],
    this.hasActiveError = false,
    this.resetCount = 0,
    // Scoring
    this.correctPlacements = 0,
    this.incorrectAttempts = 0,
    this.totalUnitsAcrossAll = 0,
    this.correctUnitsAcrossAll = 0,
    // Flow
    this.isComplete = false,
    this.isScriptureComplete = false,
    required this.startTime,
    this.completionTime,
    this.lastFeedback,
  });

  double get accuracy => (correctUnitsAcrossAll + incorrectAttempts) == 0
      ? 0.0
      : correctUnitsAcrossAll / (correctUnitsAcrossAll + incorrectAttempts);

  int get starRating {
    if (incorrectAttempts == 0) return 3;
    if (incorrectAttempts <= 3) return 2;
    return 1;
  }

  Duration get elapsed =>
      completionTime ?? DateTime.now().difference(startTime);

  // Chunk mode progress
  int get chunksPlaced => placedChunks.where((c) => c != null).length;
  double get chunkProgress =>
      targetChunks.isEmpty ? 0.0 : chunksPlaced / targetChunks.length;

  // Typing mode progress
  double get typingProgress =>
      targetText.isEmpty ? 0.0 : typedText.length / targetText.length;

  double get scriptureProgress =>
      mode == WordBuilderMode.chunkTap ? chunkProgress : typingProgress;

  WordBuilderState copyWith({
    DifficultyLevel? difficulty,
    WordBuilderMode? mode,
    ScriptureBook? bookFilter,
    Scripture? currentScripture,
    List<Scripture>? scriptureQueue,
    int? currentIndex,
    int? totalScriptures,
    List<WordChunk>? targetChunks,
    List<WordChunk>? availablePool,
    List<WordChunk?>? placedChunks,
    int? nextChunkIndex,
    String? targetText,
    String? typedText,
    List<TypedChar>? typedChars,
    bool? hasActiveError,
    int? resetCount,
    int? correctPlacements,
    int? incorrectAttempts,
    int? totalUnitsAcrossAll,
    int? correctUnitsAcrossAll,
    bool? isComplete,
    bool? isScriptureComplete,
    DateTime? startTime,
    Duration? completionTime,
    String? lastFeedback,
    bool clearFeedback = false,
  }) {
    return WordBuilderState(
      difficulty: difficulty ?? this.difficulty,
      mode: mode ?? this.mode,
      bookFilter: bookFilter ?? this.bookFilter,
      currentScripture: currentScripture ?? this.currentScripture,
      scriptureQueue: scriptureQueue ?? this.scriptureQueue,
      currentIndex: currentIndex ?? this.currentIndex,
      totalScriptures: totalScriptures ?? this.totalScriptures,
      targetChunks: targetChunks ?? this.targetChunks,
      availablePool: availablePool ?? this.availablePool,
      placedChunks: placedChunks ?? this.placedChunks,
      nextChunkIndex: nextChunkIndex ?? this.nextChunkIndex,
      targetText: targetText ?? this.targetText,
      typedText: typedText ?? this.typedText,
      typedChars: typedChars ?? this.typedChars,
      hasActiveError: hasActiveError ?? this.hasActiveError,
      resetCount: resetCount ?? this.resetCount,
      correctPlacements: correctPlacements ?? this.correctPlacements,
      incorrectAttempts: incorrectAttempts ?? this.incorrectAttempts,
      totalUnitsAcrossAll: totalUnitsAcrossAll ?? this.totalUnitsAcrossAll,
      correctUnitsAcrossAll:
          correctUnitsAcrossAll ?? this.correctUnitsAcrossAll,
      isComplete: isComplete ?? this.isComplete,
      isScriptureComplete: isScriptureComplete ?? this.isScriptureComplete,
      startTime: startTime ?? this.startTime,
      completionTime: completionTime ?? this.completionTime,
      lastFeedback: clearFeedback ? null : (lastFeedback ?? this.lastFeedback),
    );
  }
}

// ─── Notifier ───────────────────────────────────────────────────

class WordBuilderNotifier extends StateNotifier<WordBuilderState> {
  WordBuilderNotifier()
      : super(WordBuilderState(
          difficulty: DifficultyLevel.beginner,
          mode: WordBuilderMode.chunkTap,
          startTime: DateTime.now(),
        ));

  final _random = Random();

  // ── Chunk colors for visual distinction ──
  static const _chunkColors = [0, 1, 2, 3, 4, 5, 6, 7];

  /// Start a new game session.
  void startGame({
    required DifficultyLevel difficulty,
    ScriptureBook? bookFilter,
  }) {
    final mode = (difficulty == DifficultyLevel.beginner ||
            difficulty == DifficultyLevel.intermediate)
        ? WordBuilderMode.chunkTap
        : WordBuilderMode.typing;

    List<Scripture> available = List.from(allScriptures);
    if (bookFilter != null) {
      available = available.where((s) => s.book == bookFilter).toList();
    }
    available.shuffle(_random);

    final count = min(difficulty.scriptureCount, available.length);
    final selected = available.take(count).toList();

    state = WordBuilderState(
      difficulty: difficulty,
      mode: mode,
      bookFilter: bookFilter,
      scriptureQueue: selected,
      totalScriptures: selected.length,
      startTime: DateTime.now(),
    );

    _loadScripture(0);
  }

  /// Load a scripture by queue index.
  void _loadScripture(int index) {
    if (index >= state.scriptureQueue.length) {
      state = state.copyWith(
        isComplete: true,
        completionTime: DateTime.now().difference(state.startTime),
      );
      return;
    }

    final scripture = state.scriptureQueue[index];

    if (state.mode == WordBuilderMode.chunkTap) {
      _loadChunkMode(index, scripture);
    } else {
      _loadTypingMode(index, scripture);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CHUNK-TAP MODE (Beginner / Intermediate)
  // ═══════════════════════════════════════════════════════════════

  void _loadChunkMode(int index, Scripture scripture) {
    final words = scripture.words;
    final chunkSize = state.difficulty == DifficultyLevel.beginner ? 3 : 2;

    // Split words into chunks of the target size
    List<WordChunk> chunks = [];
    int colorIdx = 0;
    for (int i = 0; i < words.length; i += chunkSize) {
      final end = min(i + chunkSize, words.length);
      chunks.add(WordChunk(
        words: words.sublist(i, end),
        startIndex: i,
        colorIndex: colorIdx % _chunkColors.length,
      ));
      colorIdx++;
    }

    // Build the pool (shuffle of real chunks + distractors)
    List<WordChunk> pool = List.from(chunks);

    // Intermediate gets distractor chunks
    if (state.difficulty == DifficultyLevel.intermediate) {
      final distractorChunks = _getDistractorChunks(
        excludeScripture: scripture,
        chunkSize: chunkSize,
        count: state.difficulty.extraDistractors,
      );
      pool.addAll(distractorChunks);
    }

    pool.shuffle(_random);

    state = state.copyWith(
      currentScripture: scripture,
      currentIndex: index,
      targetChunks: chunks,
      availablePool: pool,
      placedChunks: List.filled(chunks.length, null),
      nextChunkIndex: 0,
      correctPlacements: 0,
      isScriptureComplete: false,
      totalUnitsAcrossAll: state.totalUnitsAcrossAll + chunks.length,
      clearFeedback: true,
    );
  }

  /// Get distractor chunks from other scriptures.
  List<WordChunk> _getDistractorChunks({
    required Scripture excludeScripture,
    required int chunkSize,
    required int count,
  }) {
    final others =
        allScriptures.where((s) => s.id != excludeScripture.id).toList();
    others.shuffle(_random);

    final result = <WordChunk>[];
    for (final s in others) {
      if (result.length >= count) break;
      final words = s.words;
      if (words.length >= chunkSize) {
        final start = _random.nextInt(max(1, words.length - chunkSize));
        result.add(WordChunk(
          words: words.sublist(start, min(start + chunkSize, words.length)),
          startIndex: -1,
          isDistractor: true,
          colorIndex: -1,
        ));
      }
    }
    return result;
  }

  /// User taps a chunk from the pool.
  void selectChunk(int poolIndex) {
    if (state.isScriptureComplete || state.mode != WordBuilderMode.chunkTap) {
      return;
    }

    final tapped = state.availablePool[poolIndex];

    // Find next empty slot
    int targetSlot = -1;
    for (int i = 0; i < state.placedChunks.length; i++) {
      if (state.placedChunks[i] == null) {
        targetSlot = i;
        break;
      }
    }
    if (targetSlot == -1) return;

    final expectedChunk = state.targetChunks[targetSlot];

    // Check correctness: same start index and not a distractor
    if (!tapped.isDistractor && tapped.startIndex == expectedChunk.startIndex) {
      // Correct!
      final updated = List<WordChunk?>.from(state.placedChunks);
      updated[targetSlot] = tapped;

      final updatedPool = List<WordChunk>.from(state.availablePool);
      updatedPool.removeAt(poolIndex);

      final newCorrect = state.correctPlacements + 1;
      final newCorrectAcross = state.correctUnitsAcrossAll + 1;
      final done = newCorrect >= state.targetChunks.length;

      state = state.copyWith(
        placedChunks: updated,
        availablePool: updatedPool,
        nextChunkIndex: targetSlot + 1,
        correctPlacements: newCorrect,
        correctUnitsAcrossAll: newCorrectAcross,
        lastFeedback: 'correct',
        isScriptureComplete: done,
      );
    } else {
      // Wrong — beginner/intermediate just bounces back
      state = state.copyWith(
        incorrectAttempts: state.incorrectAttempts + 1,
        lastFeedback: 'incorrect',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // TYPING MODE (Advanced / Master)
  // ═══════════════════════════════════════════════════════════════

  void _loadTypingMode(int index, Scripture scripture) {
    final fullText = scripture.fullText;

    state = state.copyWith(
      currentScripture: scripture,
      currentIndex: index,
      targetText: fullText,
      typedText: '',
      typedChars: [],
      hasActiveError: false,
      correctPlacements: 0,
      isScriptureComplete: false,
      totalUnitsAcrossAll: state.totalUnitsAcrossAll + fullText.length,
      clearFeedback: true,
    );
  }

  /// User types a character. Called on every keystroke.
  void onType(String newText) {
    if (state.isScriptureComplete || state.mode != WordBuilderMode.typing) {
      return;
    }

    // Handle backspace (text got shorter)
    if (newText.length < state.typedText.length) {
      // Advanced: allow deleting to fix errors
      if (state.difficulty == DifficultyLevel.advanced) {
        final newChars = List<TypedChar>.from(state.typedChars);
        if (newChars.isNotEmpty) {
          newChars.removeLast();
        }
        final stillHasError = newChars.any((c) => !c.isCorrect);
        state = state.copyWith(
          typedText: newText,
          typedChars: newChars,
          hasActiveError: stillHasError,
          clearFeedback: true,
        );
      }
      // Master: backspace doesn't help — you can't fix errors
      // (the full reset happens on the wrong char, not on backspace)
      return;
    }

    // New character typed
    if (newText.length > state.typedText.length) {
      // In Advanced mode, block new typing until errors are deleted
      if (state.hasActiveError && state.difficulty == DifficultyLevel.advanced) {
        return;
      }

      final newChar = newText[newText.length - 1];
      final expectedIndex = newText.length - 1;

      if (expectedIndex >= state.targetText.length) return;

      final expectedChar = state.targetText[expectedIndex];
      // Case-insensitive comparison for letters
      final isCorrect = newChar.toLowerCase() == expectedChar.toLowerCase();

      if (isCorrect) {
        final newChars = List<TypedChar>.from(state.typedChars)
          ..add(TypedChar(char: newChar, isCorrect: true));
        final newCorrectAcross = state.correctUnitsAcrossAll + 1;
        final done = newText.length >= state.targetText.length;

        state = state.copyWith(
          typedText: newText,
          typedChars: newChars,
          correctPlacements: state.correctPlacements + 1,
          correctUnitsAcrossAll: newCorrectAcross,
          lastFeedback: done ? 'correct' : null,
          isScriptureComplete: done,
          clearFeedback: !done,
        );
      } else {
        // WRONG CHARACTER
        if (state.difficulty == DifficultyLevel.master) {
          // Master: full reset!
          state = state.copyWith(
            typedText: '',
            typedChars: [],
            incorrectAttempts: state.incorrectAttempts + 1,
            resetCount: state.resetCount + 1,
            // Undo any correct chars we counted for this scripture
            correctUnitsAcrossAll:
                state.correctUnitsAcrossAll - state.correctPlacements,
            correctPlacements: 0,
            hasActiveError: false,
            lastFeedback: 'reset',
          );
        } else {
          // Advanced: show red, user must backspace to fix
          final newChars = List<TypedChar>.from(state.typedChars)
            ..add(TypedChar(char: newChar, isCorrect: false));

          state = state.copyWith(
            typedText: newText,
            typedChars: newChars,
            incorrectAttempts: state.incorrectAttempts + 1,
            hasActiveError: true,
            lastFeedback: 'incorrect',
          );
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SHARED
  // ═══════════════════════════════════════════════════════════════

  /// Advance to next scripture.
  void nextScripture() {
    _loadScripture(state.currentIndex + 1);
  }

  /// Clear feedback.
  void clearFeedback() {
    state = state.copyWith(clearFeedback: true);
  }
}

// ─── Provider ───────────────────────────────────────────────────

final wordBuilderProvider =
    StateNotifierProvider<WordBuilderNotifier, WordBuilderState>((ref) {
  return WordBuilderNotifier();
});
