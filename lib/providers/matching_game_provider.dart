import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scripture.dart';
import '../models/enums.dart';
import '../data/scriptures_data.dart';

/// Represents a single match pair in the game.
class MatchPair {
  final Scripture scripture;
  bool isMatched;

  MatchPair({required this.scripture, this.isMatched = false});
}

/// Full state for a matching game session.
class MatchingGameState {
  final DifficultyLevel difficulty;
  final ScriptureBook? bookFilter; // null = all books
  final List<MatchPair> pairs;
  final List<String> shuffledReferences; // Right column order
  final List<String> shuffledPhrases;    // Left column order
  final String? selectedPhraseId;        // Currently selected left item
  final String? selectedReferenceId;     // Currently selected right item
  final int correctMatches;
  final int incorrectAttempts;
  final int totalPairs;
  final bool isComplete;
  final DateTime startTime;
  final Duration? completionTime;
  final String? lastFeedback; // 'correct', 'incorrect', or null
  final String? lastMatchedId; // ID of last correctly matched scripture

  const MatchingGameState({
    required this.difficulty,
    this.bookFilter,
    this.pairs = const [],
    this.shuffledReferences = const [],
    this.shuffledPhrases = const [],
    this.selectedPhraseId,
    this.selectedReferenceId,
    this.correctMatches = 0,
    this.incorrectAttempts = 0,
    this.totalPairs = 0,
    this.isComplete = false,
    required this.startTime,
    this.completionTime,
    this.lastFeedback,
    this.lastMatchedId,
  });

  double get accuracy => (correctMatches + incorrectAttempts) == 0
      ? 0.0
      : correctMatches / (correctMatches + incorrectAttempts);

  int get starRating {
    if (incorrectAttempts == 0) return 3;
    if (incorrectAttempts <= 2) return 2;
    return 1;
  }

  Duration get elapsed => completionTime ?? DateTime.now().difference(startTime);

  MatchingGameState copyWith({
    DifficultyLevel? difficulty,
    ScriptureBook? bookFilter,
    List<MatchPair>? pairs,
    List<String>? shuffledReferences,
    List<String>? shuffledPhrases,
    String? selectedPhraseId,
    String? selectedReferenceId,
    int? correctMatches,
    int? incorrectAttempts,
    int? totalPairs,
    bool? isComplete,
    DateTime? startTime,
    Duration? completionTime,
    String? lastFeedback,
    String? lastMatchedId,
    bool clearSelectedPhrase = false,
    bool clearSelectedReference = false,
    bool clearFeedback = false,
    bool clearLastMatched = false,
  }) {
    return MatchingGameState(
      difficulty: difficulty ?? this.difficulty,
      bookFilter: bookFilter ?? this.bookFilter,
      pairs: pairs ?? this.pairs,
      shuffledReferences: shuffledReferences ?? this.shuffledReferences,
      shuffledPhrases: shuffledPhrases ?? this.shuffledPhrases,
      selectedPhraseId: clearSelectedPhrase ? null : (selectedPhraseId ?? this.selectedPhraseId),
      selectedReferenceId: clearSelectedReference ? null : (selectedReferenceId ?? this.selectedReferenceId),
      correctMatches: correctMatches ?? this.correctMatches,
      incorrectAttempts: incorrectAttempts ?? this.incorrectAttempts,
      totalPairs: totalPairs ?? this.totalPairs,
      isComplete: isComplete ?? this.isComplete,
      startTime: startTime ?? this.startTime,
      completionTime: completionTime ?? this.completionTime,
      lastFeedback: clearFeedback ? null : (lastFeedback ?? this.lastFeedback),
      lastMatchedId: clearLastMatched ? null : (lastMatchedId ?? this.lastMatchedId),
    );
  }
}

/// Manages the matching game logic.
class MatchingGameNotifier extends StateNotifier<MatchingGameState> {
  MatchingGameNotifier()
      : super(MatchingGameState(
          difficulty: DifficultyLevel.beginner,
          startTime: DateTime.now(),
        ));

  final _random = Random();

  /// Initialize a new game with given difficulty and optional book filter.
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

    // Pick the right number based on difficulty
    final count = min(difficulty.scriptureCount, available.length);
    final selected = available.take(count).toList();

    // Create match pairs
    final pairs = selected.map((s) => MatchPair(scripture: s)).toList();

    // Shuffle both columns independently
    final phraseIds = selected.map((s) => s.id).toList()..shuffle(_random);
    final refIds = selected.map((s) => s.id).toList()..shuffle(_random);

    state = MatchingGameState(
      difficulty: difficulty,
      bookFilter: bookFilter,
      pairs: pairs,
      shuffledPhrases: phraseIds,
      shuffledReferences: refIds,
      totalPairs: pairs.length,
      startTime: DateTime.now(),
    );
  }

  /// Select a phrase (left column item).
  void selectPhrase(String scriptureId) {
    if (_isPairMatched(scriptureId)) return;

    // If a reference is already selected, try to match
    if (state.selectedReferenceId != null) {
      _tryMatch(scriptureId, state.selectedReferenceId!);
    } else {
      state = state.copyWith(
        selectedPhraseId: scriptureId,
        clearFeedback: true,
      );
    }
  }

  /// Select a reference (right column item).
  void selectReference(String scriptureId) {
    if (_isPairMatched(scriptureId)) return;

    // If a phrase is already selected, try to match
    if (state.selectedPhraseId != null) {
      _tryMatch(state.selectedPhraseId!, scriptureId);
    } else {
      state = state.copyWith(
        selectedReferenceId: scriptureId,
        clearFeedback: true,
      );
    }
  }

  /// Handle a drag-and-drop match attempt.
  void attemptDragMatch({
    required String draggedId,
    required String targetId,
  }) {
    _tryMatch(draggedId, targetId);
  }

  /// Core matching logic.
  void _tryMatch(String phraseId, String referenceId) {
    if (phraseId == referenceId) {
      // Correct match!
      final updatedPairs = state.pairs.map((p) {
        if (p.scripture.id == phraseId) {
          return MatchPair(scripture: p.scripture, isMatched: true);
        }
        return p;
      }).toList();

      final newCorrect = state.correctMatches + 1;
      final isComplete = newCorrect >= state.totalPairs;

      state = state.copyWith(
        pairs: updatedPairs,
        correctMatches: newCorrect,
        isComplete: isComplete,
        lastFeedback: 'correct',
        lastMatchedId: phraseId,
        clearSelectedPhrase: true,
        clearSelectedReference: true,
        completionTime: isComplete ? DateTime.now().difference(state.startTime) : null,
      );
    } else {
      // Incorrect match
      state = state.copyWith(
        incorrectAttempts: state.incorrectAttempts + 1,
        lastFeedback: 'incorrect',
        clearSelectedPhrase: true,
        clearSelectedReference: true,
      );
    }
  }

  bool _isPairMatched(String scriptureId) {
    return state.pairs.any((p) => p.scripture.id == scriptureId && p.isMatched);
  }

  /// Clear feedback state (called after animation completes).
  void clearFeedback() {
    state = state.copyWith(clearFeedback: true, clearLastMatched: true);
  }

  /// Get scripture by ID from the current game pairs.
  Scripture? getScripture(String id) {
    try {
      return state.pairs.firstWhere((p) => p.scripture.id == id).scripture;
    } catch (_) {
      return null;
    }
  }

  /// Check if a specific pair has been matched.
  bool isMatched(String scriptureId) {
    return state.pairs.any((p) => p.scripture.id == scriptureId && p.isMatched);
  }
}

/// The provider for matching game state.
final matchingGameProvider =
    StateNotifierProvider<MatchingGameNotifier, MatchingGameState>((ref) {
  return MatchingGameNotifier();
});
