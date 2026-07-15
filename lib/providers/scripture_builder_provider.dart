import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scripture.dart';
import '../models/enums.dart';
import '../data/scriptures_data.dart';
import '../services/word_commit_engine.dart';

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

/// Represents a character the user has typed (Advanced) or committed via a
/// word check (Master) in typing mode.
class TypedChar {
  final String char;
  final bool isCorrect;

  const TypedChar({required this.char, required this.isCorrect});
}

// ─── Game mode enum ─────────────────────────────────────────────

/// The two fundamental interaction modes for Scripture Builder.
enum ScriptureBuilderMode {
  chunkTap,  // Beginner & Intermediate: tap word chunks in order
  typing,    // Advanced & Master: type the passage character by character
}

// ─── State ──────────────────────────────────────────────────────

class ScriptureBuilderState {
  final DifficultyLevel difficulty;
  final ScriptureBuilderMode mode;
  final ScriptureBook? bookFilter;
  final Scripture? currentScripture;
  final List<Scripture> scriptureQueue;
  final int currentIndex;
  final int totalScriptures;

  // ── Chunk-tap mode fields ──
  final List<WordChunk> targetChunks;    // Chunks in correct order
  final List<WordChunk> availablePool;   // Shuffled pool of chunk tiles (positions are stable)
  final Set<int> usedPoolIndices;        // Indices in availablePool that have been correctly placed
  final List<WordChunk?> placedChunks;   // Placed chunks (null = empty slot)
  final int nextChunkIndex;              // Next empty slot to fill

  // ── Typing mode fields ──
  final String targetText;               // Full text to type
  final String typedText;                // Advanced: all text typed so far.
                                         // Master: current word buffer only —
                                         // unjudged until committed with space.
  final List<TypedChar> typedChars;      // Judged/committed chars (incl. auto-fill)
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

  const ScriptureBuilderState({
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
    this.usedPoolIndices = const <int>{},
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

  // Typing mode progress (use typedChars which includes auto-filled punctuation)
  double get typingProgress =>
      targetText.isEmpty ? 0.0 : typedChars.length / targetText.length;

  double get scriptureProgress =>
      mode == ScriptureBuilderMode.chunkTap ? chunkProgress : typingProgress;

  ScriptureBuilderState copyWith({
    DifficultyLevel? difficulty,
    ScriptureBuilderMode? mode,
    ScriptureBook? bookFilter,
    Scripture? currentScripture,
    List<Scripture>? scriptureQueue,
    int? currentIndex,
    int? totalScriptures,
    List<WordChunk>? targetChunks,
    List<WordChunk>? availablePool,
    Set<int>? usedPoolIndices,
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
    return ScriptureBuilderState(
      difficulty: difficulty ?? this.difficulty,
      mode: mode ?? this.mode,
      bookFilter: bookFilter ?? this.bookFilter,
      currentScripture: currentScripture ?? this.currentScripture,
      scriptureQueue: scriptureQueue ?? this.scriptureQueue,
      currentIndex: currentIndex ?? this.currentIndex,
      totalScriptures: totalScriptures ?? this.totalScriptures,
      targetChunks: targetChunks ?? this.targetChunks,
      availablePool: availablePool ?? this.availablePool,
      usedPoolIndices: usedPoolIndices ?? this.usedPoolIndices,
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

class ScriptureBuilderNotifier extends StateNotifier<ScriptureBuilderState> {
  ScriptureBuilderNotifier()
      : super(ScriptureBuilderState(
          difficulty: DifficultyLevel.beginner,
          mode: ScriptureBuilderMode.chunkTap,
          startTime: DateTime.now(),
        ));

  final _random = Random();

  // ── Chunk colors for visual distinction ──
  static const _chunkColors = [0, 1, 2, 3, 4, 5, 6, 7];

  /// Start a new game session.
  void startGame({
    required DifficultyLevel difficulty,
    ScriptureBook? bookFilter,
    List<Scripture>? scriptures,
  }) {
    final mode = (difficulty == DifficultyLevel.beginner ||
            difficulty == DifficultyLevel.intermediate)
        ? ScriptureBuilderMode.chunkTap
        : ScriptureBuilderMode.typing;

    List<Scripture> selected;
    if (scriptures != null && scriptures.isNotEmpty) {
      selected = List.from(scriptures);
    } else {
      List<Scripture> available = List.from(allScriptures);
      if (bookFilter != null) {
        available = available.where((s) => s.book == bookFilter).toList();
      }
      available.shuffle(_random);
      final count = min(difficulty.scriptureCount, available.length);
      selected = available.take(count).toList();
    }

    state = ScriptureBuilderState(
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

    if (state.mode == ScriptureBuilderMode.chunkTap) {
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
      usedPoolIndices: const <int>{},
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
    if (state.isScriptureComplete || state.mode != ScriptureBuilderMode.chunkTap) {
      return;
    }
    // Ignore taps on chunks that have already been correctly placed.
    if (state.usedPoolIndices.contains(poolIndex)) return;

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

    // Check correctness: same text and not a distractor. Text equality (not
    // startIndex) so identical duplicate chunks are interchangeable — e.g.
    // two "words of" tiles in 2 Nephi 32:3 both count for either slot.
    if (!tapped.isDistractor && tapped.text == expectedChunk.text) {
      // Correct! Mark the pool index as used instead of removing it,
      // so the chip layout stays stable (no reflow) and users can tap
      // remaining chunks without the bubbles shifting under their finger.
      final updated = List<WordChunk?>.from(state.placedChunks);
      updated[targetSlot] = tapped;

      final newUsedIndices = <int>{...state.usedPoolIndices, poolIndex};

      final newCorrect = state.correctPlacements + 1;
      final newCorrectAcross = state.correctUnitsAcrossAll + 1;
      final done = newCorrect >= state.targetChunks.length;

      state = state.copyWith(
        placedChunks: updated,
        usedPoolIndices: newUsedIndices,
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

  /// Auto-fill any punctuation at the current position in the target text.
  /// Returns the number of punctuation characters auto-filled.
  /// Auto-fills punctuation AND spaces in the target text so the user
  /// only needs to type actual letters/digits. This handles em dashes,
  /// commas, periods, quotes, and the spaces around them seamlessly.
  int _autoFillNonLetters(List<TypedChar> chars, String currentTyped) {
    int filled = 0;
    int pos = chars.length;
    while (pos < state.targetText.length &&
        _isAutoFillChar(state.targetText[pos])) {
      chars.add(TypedChar(char: state.targetText[pos], isCorrect: true));
      filled++;
      pos++;
    }
    return filled;
  }

  /// Returns true if this character should be auto-filled (not typed by user).
  /// Punctuation and spaces are both auto-filled.
  bool _isAutoFillChar(String ch) => WordCommitEngine.isAutoFill(ch);

  /// User input changed. Called on every keystroke.
  /// Punctuation in the target text is auto-filled so the user only
  /// has to type letters and digits.
  ///
  /// Advanced judges each character as it lands; Master buffers the current
  /// word and only judges it when committed (see [_onTypeWord]).
  void onType(String newText) {
    if (state.isScriptureComplete || state.mode != ScriptureBuilderMode.typing) {
      return;
    }
    if (state.difficulty == DifficultyLevel.master) {
      _onTypeWord(newText);
    } else {
      _onTypeChar(newText);
    }
  }

  /// Master: commit the current word buffer as if the user pressed space.
  /// Wired to the keyboard's done/submit action so the final word of a verse
  /// doesn't strand the user waiting for a trailing space.
  void submitWord() {
    if (state.isScriptureComplete ||
        state.mode != ScriptureBuilderMode.typing ||
        state.difficulty != DifficultyLevel.master) {
      return;
    }
    _onTypeWord('${state.typedText} ');
  }

  // ── Master: word-commit typing ──
  //
  // The field only ever holds the word in progress. Nothing is judged until
  // the user commits with whitespace — which is also the moment the OS
  // keyboard applies autocorrect, so fat-finger typos get fixed before they
  // can trigger a reset. Backspace inside the buffer is always free.
  void _onTypeWord(String newText) {
    final endsWithWhitespace =
        newText.endsWith(' ') || newText.endsWith('\n');

    if (!endsWithWhitespace) {
      // In-progress buffer: typing, backspacing, and autocorrect rewrites
      // are all unjudged. The only exception is the verse's final word —
      // commit it the moment it matches so completion doesn't require a
      // trailing space (which many users would never think to type).
      final result = WordCommitEngine.tryCommit(
        target: state.targetText,
        position: state.typedChars.length,
        buffer: newText,
      );
      if (result.status == WordCommitStatus.committed &&
          state.typedChars.length + result.committedText.length >=
              state.targetText.length) {
        _commitWord(result.committedText);
        return;
      }
      state = state.copyWith(typedText: newText, clearFeedback: true);
      return;
    }

    // Whitespace committed the word — judge the buffer.
    final result = WordCommitEngine.tryCommit(
      target: state.targetText,
      position: state.typedChars.length,
      buffer: newText,
    );
    switch (result.status) {
      case WordCommitStatus.committed:
        _commitWord(result.committedText);
      case WordCommitStatus.nothingToCommit:
        // Stray space with no letters typed — consume it silently.
        state = state.copyWith(
          typedText: '',
          lastFeedback: 'clearfield',
        );
      case WordCommitStatus.wrongWord:
        // Master: wrong word = full reset.
        state = state.copyWith(
          typedText: '',
          typedChars: [],
          incorrectAttempts: state.incorrectAttempts + 1,
          resetCount: state.resetCount + 1,
          correctUnitsAcrossAll:
              state.correctUnitsAcrossAll - state.correctPlacements,
          correctPlacements: 0,
          hasActiveError: false,
          lastFeedback: 'reset',
        );
    }
  }

  /// Append a successfully committed word (target casing + auto-filled
  /// punctuation/spaces) and clear the buffer for the next word.
  void _commitWord(String committedText) {
    final newChars = List<TypedChar>.from(state.typedChars);
    for (var i = 0; i < committedText.length; i++) {
      newChars.add(TypedChar(char: committedText[i], isCorrect: true));
    }
    final done = newChars.length >= state.targetText.length;

    state = state.copyWith(
      typedText: '',
      typedChars: newChars,
      correctPlacements: state.correctPlacements + committedText.length,
      correctUnitsAcrossAll:
          state.correctUnitsAcrossAll + committedText.length,
      lastFeedback: done ? 'correct' : 'word',
      isScriptureComplete: done,
    );
  }

  // ── Advanced: per-character typing ──
  void _onTypeChar(String newText) {
    // Handle backspace (text got shorter): allow deleting to fix errors
    if (newText.length < state.typedText.length) {
      final newChars = List<TypedChar>.from(state.typedChars);
      if (newChars.isNotEmpty) {
        // Remove the last user-typed char, plus any auto-filled chars
        // (punctuation and spaces) that preceded it.
        newChars.removeLast();
        while (newChars.isNotEmpty &&
            _isAutoFillChar(newChars.last.char)) {
          newChars.removeLast();
        }
      }
      final stillHasError = newChars.any((c) => !c.isCorrect);
      state = state.copyWith(
        typedText: newText,
        typedChars: newChars,
        hasActiveError: stillHasError,
        clearFeedback: true,
      );
      return;
    }

    // New character typed
    if (newText.length > state.typedText.length) {
      // Block new typing until errors are deleted
      if (state.hasActiveError) {
        return;
      }

      final newChar = newText[newText.length - 1];

      // Ignore spaces and punctuation typed by the user — both are
      // auto-filled. The user only needs to type letters and digits.
      // Without this, typing a natural "world," (with the comma) counted
      // the comma as a wrong character.
      if (_isAutoFillChar(newChar)) {
        state = state.copyWith(typedText: newText);
        return;
      }

      // Auto-fill any punctuation/spaces at the current position first
      final newChars = List<TypedChar>.from(state.typedChars);
      final autoFilled = _autoFillNonLetters(newChars, state.typedText);

      final expectedIndex = newChars.length;
      if (expectedIndex >= state.targetText.length) return;

      final expectedChar = state.targetText[expectedIndex];
      // Case-insensitive comparison for letters
      final isCorrect = newChar.toLowerCase() == expectedChar.toLowerCase();

      if (isCorrect) {
        newChars.add(TypedChar(char: newChar, isCorrect: true));

        // Also auto-fill any trailing punctuation (e.g. end of verse with period)
        final trailingFilled = _autoFillNonLetters(newChars, '');

        final totalFilled = 1 + autoFilled + trailingFilled;
        final newCorrectAcross = state.correctUnitsAcrossAll + totalFilled;
        final done = newChars.length >= state.targetText.length;

        state = state.copyWith(
          typedText: newText,
          typedChars: newChars,
          correctPlacements: state.correctPlacements + totalFilled,
          correctUnitsAcrossAll: newCorrectAcross,
          lastFeedback: done ? 'correct' : null,
          isScriptureComplete: done,
          clearFeedback: !done,
        );
      } else {
        // Wrong character: show red, user must backspace to fix
        newChars.add(TypedChar(char: newChar, isCorrect: false));

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

final scriptureBuilderProvider =
    StateNotifierProvider<ScriptureBuilderNotifier, ScriptureBuilderState>((ref) {
  return ScriptureBuilderNotifier();
});
