import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scripture.dart';
import '../models/enums.dart';
import '../data/scriptures_data.dart';

/// The type of quiz question being asked.
enum QuizQuestionType {
  /// Show a key phrase, pick the correct reference.
  phraseToReference,

  /// Show a reference, pick the correct key phrase.
  referenceToPhrase,

  /// Show a passage excerpt, pick the correct reference.
  passageToReference,
}

/// A single quiz question.
class QuizQuestion {
  final Scripture scripture;
  final QuizQuestionType type;
  final List<String> options; // 4 options (shuffled)
  final String correctAnswer;
  final String prompt; // The text shown as the question

  const QuizQuestion({
    required this.scripture,
    required this.type,
    required this.options,
    required this.correctAnswer,
    required this.prompt,
  });
}

/// Full state for a quiz game session.
class QuizGameState {
  final DifficultyLevel difficulty;
  final List<ScriptureBook> bookFilters;
  final List<QuizQuestion> questions;
  final int currentIndex;
  final int correctAnswers;
  final int incorrectAnswers;
  final String? selectedAnswer; // Current selection (null = not answered yet)
  final bool isAnswered; // Whether current question has been submitted
  final bool isCorrect; // Whether current answer was correct
  final bool isComplete;
  final DateTime startTime;
  final Duration? completionTime;

  const QuizGameState({
    required this.difficulty,
    this.bookFilters = const [],
    this.questions = const [],
    this.currentIndex = 0,
    this.correctAnswers = 0,
    this.incorrectAnswers = 0,
    this.selectedAnswer,
    this.isAnswered = false,
    this.isCorrect = false,
    this.isComplete = false,
    required this.startTime,
    this.completionTime,
  });

  int get totalQuestions => questions.length;

  QuizQuestion? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  int get starRating {
    if (totalQuestions == 0) return 1;
    final pct = correctAnswers / totalQuestions;
    if (pct >= 0.9) return 3;
    if (pct >= 0.7) return 2;
    return 1;
  }

  QuizGameState copyWith({
    DifficultyLevel? difficulty,
    List<ScriptureBook>? bookFilters,
    List<QuizQuestion>? questions,
    int? currentIndex,
    int? correctAnswers,
    int? incorrectAnswers,
    String? selectedAnswer,
    bool? isAnswered,
    bool? isCorrect,
    bool? isComplete,
    DateTime? startTime,
    Duration? completionTime,
    bool clearSelectedAnswer = false,
  }) {
    return QuizGameState(
      difficulty: difficulty ?? this.difficulty,
      bookFilters: bookFilters ?? this.bookFilters,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      incorrectAnswers: incorrectAnswers ?? this.incorrectAnswers,
      selectedAnswer:
          clearSelectedAnswer ? null : (selectedAnswer ?? this.selectedAnswer),
      isAnswered: isAnswered ?? this.isAnswered,
      isCorrect: isCorrect ?? this.isCorrect,
      isComplete: isComplete ?? this.isComplete,
      startTime: startTime ?? this.startTime,
      completionTime: completionTime ?? this.completionTime,
    );
  }
}

/// Manages the quiz game logic.
class QuizGameNotifier extends StateNotifier<QuizGameState> {
  QuizGameNotifier()
      : super(QuizGameState(
          difficulty: DifficultyLevel.beginner,
          startTime: DateTime.now(),
        ));

  final _random = Random();

  /// The three question types to rotate through.
  static const _questionTypes = QuizQuestionType.values;

  /// Start a new quiz game.
  ///
  /// [bookFilters] — empty list means all books. Questions are distributed
  /// proportionally to the number of scriptures each selected book has.
  void startGame({
    required DifficultyLevel difficulty,
    List<ScriptureBook> bookFilters = const [],
    List<Scripture>? scriptures,
  }) {
    final targetCount = difficulty.quizQuestionCount;

    List<Scripture> selected;
    if (scriptures != null && scriptures.isNotEmpty) {
      selected = List.from(scriptures);
    } else {
      // Determine which books to draw from
      final effectiveBooks = bookFilters.isEmpty
          ? ScriptureBook.values.toList()
          : bookFilters;

      // Group available scriptures by book
      final byBook = <ScriptureBook, List<Scripture>>{};
      for (final book in effectiveBooks) {
        byBook[book] = allScriptures.where((s) => s.book == book).toList();
      }

      // Total available across selected books
      final totalAvailable =
          byBook.values.fold<int>(0, (sum, list) => sum + list.length);
      final count = min(targetCount, totalAvailable);

      // Distribute proportionally, then shuffle-pick from each book
      selected = _selectProportionally(byBook, count);
    }

    // Build a pool of distractors from all scriptures not selected
    final distractorPool =
        allScriptures.where((s) => !selected.contains(s)).toList();

    final questions = <QuizQuestion>[];
    for (int i = 0; i < selected.length; i++) {
      final scripture = selected[i];
      final type = _questionTypes[i % _questionTypes.length];
      questions.add(_buildQuestion(scripture, type, distractorPool));
    }

    // Shuffle the final question order so books are interleaved
    questions.shuffle(_random);

    state = QuizGameState(
      difficulty: difficulty,
      bookFilters: bookFilters,
      questions: questions,
      startTime: DateTime.now(),
    );
  }

  /// Select [count] scriptures proportionally from each book's pool.
  List<Scripture> _selectProportionally(
    Map<ScriptureBook, List<Scripture>> byBook,
    int count,
  ) {
    final totalAvailable =
        byBook.values.fold<int>(0, (sum, list) => sum + list.length);
    if (totalAvailable == 0) return [];

    final selected = <Scripture>[];
    var remaining = count;

    // Calculate each book's share and pick that many
    final books = byBook.keys.toList();
    for (int i = 0; i < books.length; i++) {
      final book = books[i];
      final pool = List<Scripture>.from(byBook[book]!);
      pool.shuffle(_random);

      int bookCount;
      if (i == books.length - 1) {
        // Last book gets whatever is left to avoid rounding gaps
        bookCount = remaining;
      } else {
        bookCount = (count * pool.length / totalAvailable).round();
        // Ensure we don't exceed what's available in this book
        bookCount = min(bookCount, pool.length);
      }
      bookCount = min(bookCount, pool.length);
      bookCount = min(bookCount, remaining);

      selected.addAll(pool.take(bookCount));
      remaining -= bookCount;
    }

    return selected;
  }

  /// Build a single quiz question with 4 options.
  QuizQuestion _buildQuestion(
    Scripture scripture,
    QuizQuestionType type,
    List<Scripture> distractorPool,
  ) {
    String prompt;
    String correctAnswer;
    List<String> distractorAnswers;

    switch (type) {
      case QuizQuestionType.phraseToReference:
        prompt = scripture.keyPhrase;
        correctAnswer = scripture.reference;
        distractorAnswers = _pickDistractors(
          distractorPool,
          (s) => s.reference,
          exclude: correctAnswer,
        );
        break;
      case QuizQuestionType.referenceToPhrase:
        prompt = scripture.reference;
        correctAnswer = scripture.keyPhrase;
        distractorAnswers = _pickDistractors(
          distractorPool,
          (s) => s.keyPhrase,
          exclude: correctAnswer,
        );
        break;
      case QuizQuestionType.passageToReference:
        // Show first ~15 words of the passage
        final words = scripture.words;
        final excerptWords = words.take(min(15, words.length)).toList();
        prompt = '${excerptWords.join(' ')}...';
        correctAnswer = scripture.reference;
        distractorAnswers = _pickDistractors(
          distractorPool,
          (s) => s.reference,
          exclude: correctAnswer,
        );
        break;
    }

    final options = [correctAnswer, ...distractorAnswers]..shuffle(_random);

    return QuizQuestion(
      scripture: scripture,
      type: type,
      options: options,
      correctAnswer: correctAnswer,
      prompt: prompt,
    );
  }

  /// Pick 3 unique distractor answers from the pool.
  List<String> _pickDistractors(
    List<Scripture> pool,
    String Function(Scripture) extractor, {
    required String exclude,
  }) {
    final candidates =
        pool.map(extractor).where((a) => a != exclude).toSet().toList();
    candidates.shuffle(_random);
    return candidates.take(3).toList();
  }

  /// Select an answer option (before submitting).
  void selectAnswer(String answer) {
    if (state.isAnswered) return;
    state = state.copyWith(selectedAnswer: answer);
  }

  /// Submit the selected answer.
  void submitAnswer() {
    if (state.isAnswered || state.selectedAnswer == null) return;

    final question = state.currentQuestion;
    if (question == null) return;

    final correct = state.selectedAnswer == question.correctAnswer;

    state = state.copyWith(
      isAnswered: true,
      isCorrect: correct,
      correctAnswers:
          correct ? state.correctAnswers + 1 : null,
      incorrectAnswers:
          !correct ? state.incorrectAnswers + 1 : null,
    );
  }

  /// Advance to the next question (or complete the game).
  void nextQuestion() {
    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.totalQuestions) {
      state = state.copyWith(
        isComplete: true,
        completionTime: DateTime.now().difference(state.startTime),
      );
    } else {
      state = state.copyWith(
        currentIndex: nextIndex,
        isAnswered: false,
        isCorrect: false,
        clearSelectedAnswer: true,
      );
    }
  }
}

/// The provider for quiz game state.
final quizGameProvider =
    StateNotifierProvider<QuizGameNotifier, QuizGameState>((ref) {
  return QuizGameNotifier();
});
