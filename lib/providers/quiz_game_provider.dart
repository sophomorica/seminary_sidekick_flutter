import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/scripture.dart';
import '../models/enums.dart';
import '../services/quiz_question_factory.dart';

/// The type of quiz question being asked.
///
/// This is a thin alias over [QuizQuestionTypeKind] in the shared factory.
/// Kept for backward compatibility with existing screens that import this
/// file. Both names refer to the same enum values.
typedef QuizQuestionType = QuizQuestionTypeKind;

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

  /// Adapt a factory-generated question to the legacy provider type.
  factory QuizQuestion.fromGenerated(GeneratedQuestion g) => QuizQuestion(
        scripture: g.scripture,
        type: g.type,
        options: g.options,
        correctAnswer: g.correctAnswer,
        prompt: g.prompt,
      );
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
///
/// Question generation is delegated to [QuizQuestionFactory] so the same
/// logic powers Group Play (see `lib/services/group_play_service.dart`).
class QuizGameNotifier extends StateNotifier<QuizGameState> {
  QuizGameNotifier({QuizQuestionFactory? factory})
      : _factory = factory ?? QuizQuestionFactory(),
        super(QuizGameState(
          difficulty: DifficultyLevel.beginner,
          startTime: DateTime.now(),
        ));

  final QuizQuestionFactory _factory;

  /// Start a new quiz game.
  ///
  /// [bookFilters] — empty list means all books. Questions are distributed
  /// proportionally to the number of scriptures each selected book has.
  ///
  /// [targetQuestionCount] overrides the per-difficulty default
  /// (`difficulty.quizQuestionCount`). Used by the shared scope picker when
  /// the user opts into "Every scripture in scope".
  void startGame({
    required DifficultyLevel difficulty,
    List<ScriptureBook> bookFilters = const [],
    List<Scripture>? scriptures,
    int? targetQuestionCount,
  }) {
    final count = targetQuestionCount ?? difficulty.quizQuestionCount;
    final generated = _factory.buildQuestions(
      count: count,
      bookFilters: bookFilters,
      scriptures: scriptures,
    );
    final questions = generated.map(QuizQuestion.fromGenerated).toList();

    state = QuizGameState(
      difficulty: difficulty,
      bookFilters: bookFilters,
      questions: questions,
      startTime: DateTime.now(),
    );
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
      correctAnswers: correct ? state.correctAnswers + 1 : null,
      incorrectAnswers: !correct ? state.incorrectAnswers + 1 : null,
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
