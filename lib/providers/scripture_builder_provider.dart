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

  /// Punctuation characters that are auto-filled during typing mode
  /// so speech-to-text input (which omits punctuation) works seamlessly.
  static final _punctuation = RegExp(r'''[,;:!?\-\—\–\.\'\"\'\'\"\"\(\)\[\]]''');

  /// Common number-word to digit mappings for speech-to-text normalization.
  static const _numberWords = <String, String>{
    'zero': '0', 'one': '1', 'two': '2', 'three': '3', 'four': '4',
    'five': '5', 'six': '6', 'seven': '7', 'eight': '8', 'nine': '9',
    'ten': '10', 'eleven': '11', 'twelve': '12', 'thirteen': '13',
    'fourteen': '14', 'fifteen': '15', 'sixteen': '16', 'seventeen': '17',
    'eighteen': '18', 'nineteen': '19', 'twenty': '20',
    'thirty': '30', 'forty': '40', 'fifty': '50',
  };

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

    // Check correctness: same start index and not a distractor
    if (!tapped.isDistractor && tapped.startIndex == expectedChunk.startIndex) {
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
  bool _isAutoFillChar(String ch) {
    return ch == ' ' || ch == '\n' || _punctuation.hasMatch(ch);
  }

  /// User types a character. Called on every keystroke.
  /// Punctuation in the target text is auto-filled so that speech-to-text
  /// (which typically omits punctuation) works seamlessly.
  void onType(String newText) {
    if (state.isScriptureComplete || state.mode != ScriptureBuilderMode.typing) {
      return;
    }

    // Handle backspace (text got shorter)
    if (newText.length < state.typedText.length) {
      // Advanced: allow deleting to fix errors
      if (state.difficulty == DifficultyLevel.advanced) {
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
      }
      // Master: backspace doesn't help — you can't fix errors
      return;
    }

    // New character typed
    if (newText.length > state.typedText.length) {
      // In Advanced mode, block new typing until errors are deleted
      if (state.hasActiveError && state.difficulty == DifficultyLevel.advanced) {
        return;
      }

      final newChar = newText[newText.length - 1];

      // Ignore spaces and punctuation typed by the user — both are
      // auto-filled. The user only needs to type letters and digits.
      // Without this, typing a natural "world," (with the comma) counted
      // the comma as a wrong character — and triggered a full reset on
      // Master difficulty.
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
        // WRONG CHARACTER
        if (state.difficulty == DifficultyLevel.master) {
          // Master: full reset!
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
        } else {
          // Advanced: show red, user must backspace to fix
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
  }

  // ═══════════════════════════════════════════════════════════════
  // SPEECH-TO-TEXT INPUT
  // ═══════════════════════════════════════════════════════════════

  /// Process speech-to-text input word-by-word instead of character-by-character.
  /// This handles homophones (e.g. STT "four" vs target "for"), capitalization,
  /// spaces, and punctuation automatically. Returns true if a Master reset occurred.
  bool onSpeechInput(String newWords) {
    if (state.isScriptureComplete || state.mode != ScriptureBuilderMode.typing) {
      return false;
    }

    // Split the new speech input into words
    final speechWords = newWords.trim().split(RegExp(r'\s+'));
    if (speechWords.isEmpty || (speechWords.length == 1 && speechWords[0].isEmpty)) {
      return false;
    }

    for (final speechWord in speechWords) {
      if (state.isScriptureComplete) break;

      // Auto-fill any leading punctuation and spaces at current position
      final newChars = List<TypedChar>.from(state.typedChars);
      int pos = newChars.length;

      // Skip spaces at current position
      while (pos < state.targetText.length && state.targetText[pos] == ' ') {
        newChars.add(const TypedChar(char: ' ', isCorrect: true));
        pos++;
      }

      // Auto-fill punctuation
      _autoFillNonLetters(newChars, '');
      pos = newChars.length;

      // Extract the next target word (letters only, up to next space/end)
      final targetWordStart = pos;
      var targetWordEnd = pos;
      while (targetWordEnd < state.targetText.length &&
          state.targetText[targetWordEnd] != ' ') {
        targetWordEnd++;
      }
      if (targetWordStart >= state.targetText.length) break;

      // Get the target word without punctuation for comparison
      final targetWordRaw = state.targetText.substring(targetWordStart, targetWordEnd);
      final targetWordClean = targetWordRaw.replaceAll(_punctuation, '').toLowerCase();
      final speechWordClean = speechWord.replaceAll(_punctuation, '').toLowerCase();

      // Check if speech word matches target word:
      // 1. Direct match (case-insensitive, punctuation-stripped)
      // 2. Number word match (e.g. "four" matches target "for" — NO, but "4" matches "four")
      bool wordMatches = speechWordClean == targetWordClean;

      // Check if STT gave a number word where target has the same-sounding word or vice versa
      if (!wordMatches) {
        // STT said a number word, check if its digit form matches target
        final digitForm = _numberWords[speechWordClean];
        if (digitForm != null && digitForm == targetWordClean) {
          wordMatches = true;
        }
        // STT said digits, check if the word form matches target
        final wordForm = _numberWords.entries
            .where((e) => e.value == speechWordClean)
            .map((e) => e.key)
            .firstOrNull;
        if (wordForm != null && wordForm == targetWordClean) {
          wordMatches = true;
        }
        // Handle homophones: if target word sounds like speech word
        // e.g. "for"/"four", "to"/"too"/"two", "their"/"there"/"they're"
        if (!wordMatches) {
          wordMatches = _areHomophones(speechWordClean, targetWordClean);
        }
      }

      if (wordMatches) {
        // Feed the actual target characters (preserving original case/punctuation)
        for (int i = targetWordStart; i < targetWordEnd; i++) {
          final ch = state.targetText[i];
          if (_punctuation.hasMatch(ch)) {
            newChars.add(TypedChar(char: ch, isCorrect: true));
          } else {
            newChars.add(TypedChar(char: ch, isCorrect: true));
          }
        }

        // Auto-fill trailing punctuation
        _autoFillNonLetters(newChars, '');

        final totalFilled = newChars.length - state.typedChars.length;
        final newCorrectAcross = state.correctUnitsAcrossAll + totalFilled;
        final done = newChars.length >= state.targetText.length;

        state = state.copyWith(
          typedText: state.targetText.substring(0, newChars.length),
          typedChars: newChars,
          correctPlacements: state.correctPlacements + totalFilled,
          correctUnitsAcrossAll: newCorrectAcross,
          lastFeedback: done ? 'correct' : null,
          isScriptureComplete: done,
          clearFeedback: !done,
        );
      } else {
        // Word doesn't match
        if (state.difficulty == DifficultyLevel.master) {
          // Master: full reset
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
          return true; // Signal reset so speech can stop
        } else {
          // Advanced: mark as incorrect
          state = state.copyWith(
            incorrectAttempts: state.incorrectAttempts + 1,
            hasActiveError: true,
            lastFeedback: 'incorrect',
          );
          return false;
        }
      }
    }
    return false;
  }

  /// Check if two words are homophones (sound alike but spelled differently).
  static bool _areHomophones(String a, String b) {
    const homophones = <Set<String>>{
      {'for', 'four', 'fore'},
      {'to', 'too', 'two'},
      {'their', 'there', 'theyre'},
      {'your', 'youre'},
      {'no', 'know'},
      {'by', 'buy', 'bye'},
      {'hear', 'here'},
      {'right', 'write', 'rite'},
      {'sea', 'see'},
      {'son', 'sun'},
      {'one', 'won'},
      {'would', 'wood'},
      {'which', 'witch'},
      {'peace', 'piece'},
      {'pray', 'prey'},
      {'soul', 'sole'},
      {'whole', 'hole'},
      {'holy', 'wholly'},
      {'prophet', 'profit'},
      {'reign', 'rain', 'rein'},
      {'altar', 'alter'},
      {'born', 'borne'},
      {'council', 'counsel'},
      {'might', 'mite'},
      {'night', 'knight'},
      {'way', 'weigh'},
      {'week', 'weak'},
      {'wait', 'weight'},
      {'eye', 'i'},
      {'thee', 'the'},
    };
    for (final set in homophones) {
      if (set.contains(a) && set.contains(b)) return true;
    }
    return false;
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
