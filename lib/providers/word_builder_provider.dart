import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scripture.dart';
import '../models/enums.dart';
import '../data/scriptures_data.dart';

/// Represents a single word tile in the scrambled pool.
class WordTile {
  final String word;
  final int correctIndex; // Position in the original passage (-1 for distractors)
  final bool isDistractor;

  const WordTile({
    required this.word,
    required this.correctIndex,
    this.isDistractor = false,
  });
}

/// Full state for a Word Builder game session.
class WordBuilderState {
  final DifficultyLevel difficulty;
  final ScriptureBook? bookFilter;
  final Scripture? currentScripture;
  final List<Scripture> scriptureQueue; // Remaining scriptures to complete
  final int currentIndex; // Index in the queue
  final int totalScriptures; // Total scriptures in this round

  // Word tracking
  final List<String> targetWords; // Correct word order
  final List<WordTile> availablePool; // Shuffled pool of word tiles
  final List<String?> placedWords; // Words placed by user (null = empty slot)
  final int nextSlotIndex; // Next empty slot to fill

  // Scoring
  final int correctPlacements;
  final int incorrectAttempts;
  final int totalWordsAcrossAll; // Total words across all scriptures
  final int correctWordsAcrossAll; // Total correct placements across all

  // Game state
  final bool isComplete;
  final bool isScriptureComplete; // Current scripture done
  final DateTime startTime;
  final Duration? completionTime;
  final String? lastFeedback; // 'correct', 'incorrect', or null
  final int? lastIncorrectSlot; // Slot index of last incorrect attempt

  const WordBuilderState({
    required this.difficulty,
    this.bookFilter,
    this.currentScripture,
    this.scriptureQueue = const [],
    this.currentIndex = 0,
    this.totalScriptures = 0,
    this.targetWords = const [],
    this.availablePool = const [],
    this.placedWords = const [],
    this.nextSlotIndex = 0,
    this.correctPlacements = 0,
    this.incorrectAttempts = 0,
    this.totalWordsAcrossAll = 0,
    this.correctWordsAcrossAll = 0,
    this.isComplete = false,
    this.isScriptureComplete = false,
    required this.startTime,
    this.completionTime,
    this.lastFeedback,
    this.lastIncorrectSlot,
  });

  double get accuracy => (correctWordsAcrossAll + incorrectAttempts) == 0
      ? 0.0
      : correctWordsAcrossAll / (correctWordsAcrossAll + incorrectAttempts);

  int get starRating {
    if (incorrectAttempts == 0) return 3;
    if (incorrectAttempts <= 3) return 2;
    return 1;
  }

  Duration get elapsed =>
      completionTime ?? DateTime.now().difference(startTime);

  int get wordsPlaced =>
      placedWords.where((w) => w != null).length;

  double get scriptureProgress =>
      targetWords.isEmpty ? 0.0 : wordsPlaced / targetWords.length;

  WordBuilderState copyWith({
    DifficultyLevel? difficulty,
    ScriptureBook? bookFilter,
    Scripture? currentScripture,
    List<Scripture>? scriptureQueue,
    int? currentIndex,
    int? totalScriptures,
    List<String>? targetWords,
    List<WordTile>? availablePool,
    List<String?>? placedWords,
    int? nextSlotIndex,
    int? correctPlacements,
    int? incorrectAttempts,
    int? totalWordsAcrossAll,
    int? correctWordsAcrossAll,
    bool? isComplete,
    bool? isScriptureComplete,
    DateTime? startTime,
    Duration? completionTime,
    String? lastFeedback,
    int? lastIncorrectSlot,
    bool clearFeedback = false,
    bool clearLastIncorrect = false,
  }) {
    return WordBuilderState(
      difficulty: difficulty ?? this.difficulty,
      bookFilter: bookFilter ?? this.bookFilter,
      currentScripture: currentScripture ?? this.currentScripture,
      scriptureQueue: scriptureQueue ?? this.scriptureQueue,
      currentIndex: currentIndex ?? this.currentIndex,
      totalScriptures: totalScriptures ?? this.totalScriptures,
      targetWords: targetWords ?? this.targetWords,
      availablePool: availablePool ?? this.availablePool,
      placedWords: placedWords ?? this.placedWords,
      nextSlotIndex: nextSlotIndex ?? this.nextSlotIndex,
      correctPlacements: correctPlacements ?? this.correctPlacements,
      incorrectAttempts: incorrectAttempts ?? this.incorrectAttempts,
      totalWordsAcrossAll: totalWordsAcrossAll ?? this.totalWordsAcrossAll,
      correctWordsAcrossAll:
          correctWordsAcrossAll ?? this.correctWordsAcrossAll,
      isComplete: isComplete ?? this.isComplete,
      isScriptureComplete: isScriptureComplete ?? this.isScriptureComplete,
      startTime: startTime ?? this.startTime,
      completionTime: completionTime ?? this.completionTime,
      lastFeedback: clearFeedback ? null : (lastFeedback ?? this.lastFeedback),
      lastIncorrectSlot: clearLastIncorrect
          ? null
          : (lastIncorrectSlot ?? this.lastIncorrectSlot),
    );
  }
}

/// Manages the Word Builder game logic.
class WordBuilderNotifier extends StateNotifier<WordBuilderState> {
  WordBuilderNotifier()
      : super(WordBuilderState(
          difficulty: DifficultyLevel.beginner,
          startTime: DateTime.now(),
        ));

  final _random = Random();

  /// Initialize a new game session.
  void startGame({
    required DifficultyLevel difficulty,
    ScriptureBook? bookFilter,
  }) {
    // Get available scriptures
    List<Scripture> available = List.from(allScriptures);
    if (bookFilter != null) {
      available = available.where((s) => s.book == bookFilter).toList();
    }
    available.shuffle(_random);

    // Pick scriptures based on difficulty
    final count = min(difficulty.scriptureCount, available.length);
    final selected = available.take(count).toList();

    state = WordBuilderState(
      difficulty: difficulty,
      bookFilter: bookFilter,
      scriptureQueue: selected,
      totalScriptures: selected.length,
      startTime: DateTime.now(),
    );

    // Load the first scripture
    _loadScripture(0);
  }

  /// Load a scripture by index in the queue.
  void _loadScripture(int index) {
    if (index >= state.scriptureQueue.length) {
      // All done!
      state = state.copyWith(
        isComplete: true,
        completionTime: DateTime.now().difference(state.startTime),
      );
      return;
    }

    final scripture = state.scriptureQueue[index];
    final words = scripture.words;

    // Create word tiles
    List<WordTile> pool = [];
    for (int i = 0; i < words.length; i++) {
      pool.add(WordTile(word: words[i], correctIndex: i));
    }

    // Add distractor words from other scriptures if difficulty requires it
    if (state.difficulty.extraDistractors > 0) {
      final distractors = _getDistractorWords(
        excludeScripture: scripture,
        count: state.difficulty.extraDistractors,
      );
      for (final word in distractors) {
        pool.add(WordTile(word: word, correctIndex: -1, isDistractor: true));
      }
    }

    // Shuffle the pool
    pool.shuffle(_random);

    state = state.copyWith(
      currentScripture: scripture,
      currentIndex: index,
      targetWords: words,
      availablePool: pool,
      placedWords: List.filled(words.length, null),
      nextSlotIndex: 0,
      correctPlacements: 0,
      isScriptureComplete: false,
      totalWordsAcrossAll:
          state.totalWordsAcrossAll + words.length,
      clearFeedback: true,
      clearLastIncorrect: true,
    );
  }

  /// Get random distractor words from other scriptures.
  List<String> _getDistractorWords({
    required Scripture excludeScripture,
    required int count,
  }) {
    final otherScriptures =
        allScriptures.where((s) => s.id != excludeScripture.id).toList();
    otherScriptures.shuffle(_random);

    final distractors = <String>[];
    for (final s in otherScriptures) {
      if (distractors.length >= count) break;
      final words = s.words;
      if (words.isNotEmpty) {
        distractors.add(words[_random.nextInt(words.length)]);
      }
    }
    return distractors;
  }

  /// User taps a word from the pool.
  void selectWord(int poolIndex) {
    if (state.isScriptureComplete) return;

    final tile = state.availablePool[poolIndex];

    // Find the next empty slot
    int targetSlot = -1;
    for (int i = 0; i < state.placedWords.length; i++) {
      if (state.placedWords[i] == null) {
        targetSlot = i;
        break;
      }
    }
    if (targetSlot == -1) return; // All slots filled (shouldn't happen)

    // Check if this is the correct word for this slot
    if (!tile.isDistractor && tile.correctIndex == targetSlot) {
      // Correct!
      final updatedPlaced = List<String?>.from(state.placedWords);
      updatedPlaced[targetSlot] = tile.word;

      // Remove from pool
      final updatedPool = List<WordTile>.from(state.availablePool);
      updatedPool.removeAt(poolIndex);

      final newCorrect = state.correctPlacements + 1;
      final newCorrectAcross = state.correctWordsAcrossAll + 1;
      final scriptureComplete = newCorrect >= state.targetWords.length;

      state = state.copyWith(
        placedWords: updatedPlaced,
        availablePool: updatedPool,
        nextSlotIndex: targetSlot + 1,
        correctPlacements: newCorrect,
        correctWordsAcrossAll: newCorrectAcross,
        lastFeedback: 'correct',
        isScriptureComplete: scriptureComplete,
        clearLastIncorrect: true,
      );
    } else {
      // Incorrect
      if (state.difficulty.allowRetry) {
        // Beginner/Intermediate: word just bounces back, no penalty beyond counter
        state = state.copyWith(
          incorrectAttempts: state.incorrectAttempts + 1,
          lastFeedback: 'incorrect',
          lastIncorrectSlot: targetSlot,
        );
      } else {
        // Advanced/Master: reset all placed words back to pool
        _resetPlacedWords();
        state = state.copyWith(
          incorrectAttempts: state.incorrectAttempts + 1,
          lastFeedback: 'incorrect',
        );
      }
    }
  }

  /// Reset all placed words back to pool (for advanced difficulty).
  void _resetPlacedWords() {
    final scripture = state.currentScripture;
    if (scripture == null) return;

    final words = scripture.words;
    List<WordTile> pool = [];
    for (int i = 0; i < words.length; i++) {
      pool.add(WordTile(word: words[i], correctIndex: i));
    }

    // Re-add distractors
    if (state.difficulty.extraDistractors > 0) {
      final distractors = _getDistractorWords(
        excludeScripture: scripture,
        count: state.difficulty.extraDistractors,
      );
      for (final word in distractors) {
        pool.add(WordTile(word: word, correctIndex: -1, isDistractor: true));
      }
    }

    pool.shuffle(_random);

    // Deduct the correct placements we're undoing from the across-all counter
    final wordsToUndo = state.correctPlacements;

    state = state.copyWith(
      availablePool: pool,
      placedWords: List.filled(words.length, null),
      nextSlotIndex: 0,
      correctPlacements: 0,
      correctWordsAcrossAll: state.correctWordsAcrossAll - wordsToUndo,
    );
  }

  /// Advance to the next scripture after completing one.
  void nextScripture() {
    _loadScripture(state.currentIndex + 1);
  }

  /// Clear feedback state.
  void clearFeedback() {
    state = state.copyWith(clearFeedback: true, clearLastIncorrect: true);
  }
}

/// The provider for Word Builder game state.
final wordBuilderProvider =
    StateNotifierProvider<WordBuilderNotifier, WordBuilderState>((ref) {
  return WordBuilderNotifier();
});
