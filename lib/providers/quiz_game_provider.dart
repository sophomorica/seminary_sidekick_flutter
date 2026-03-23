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
  final ScriptureBook? bookFilter;
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
  final List<bool> questionResults; // per-question: true=correct, false=wrong

  const QuizGameState({
    required this.difficulty,
    this.bookFilter,
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
    this.questionResults = const [],
  });

  int get totalQuestions => questions.length;

  QuizQuestion? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  int get starRating {
    if (incorrectAnswers == 0) return 3;
    if (incorrectAnswers <= 2) return 2;
    return 1;
  }

  QuizGameState copyWith({
    DifficultyLevel? difficulty,
    ScriptureBook? bookFilter,
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
    List<bool>? questionResults,
    bool clearSelectedAnswer = false,
  }) {
    return QuizGameState(
      difficulty: difficulty ?? this.difficulty,
      bookFilter: bookFilter ?? this.bookFilter,
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
      questionResults: questionResults ?? this.questionResults,
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
  void startGame({
    required DifficultyLevel difficulty,
    ScriptureBook? bookFilter,
  }) {
    List<Scripture> available = List.from(allScriptures);
    if (bookFilter != null) {
      available = available.where((s) => s.book == bookFilter).toList();
    }
    available.shuffle(_random);

    final count = min(difficulty.scriptureCount, available.length);
    final selected = available.take(count).toList();

    // Build a pool of distractors from all scriptures not selected
    final distractorPool =
        allScriptures.where((s) => !selected.contains(s)).toList();

    final questions = <QuizQuestion>[];
    for (int i = 0; i < selected.length; i++) {
      final scripture = selected[i];
      final type = _questionTypes[i % _questionTypes.length];
      questions.add(_buildQuestion(scripture, type, distractorPool));
    }

    state = QuizGameState(
      difficulty: difficulty,
      bookFilter: bookFilter,
      questions: questions,
      startTime: DateTime.now(),
    );
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
      questionResults: [...state.questionResults, correct],
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
