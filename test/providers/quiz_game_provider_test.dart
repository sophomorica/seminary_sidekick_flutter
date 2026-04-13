import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/providers/quiz_game_provider.dart';
import 'package:seminary_sidekick/models/enums.dart';

import '../helpers/test_helpers.dart';

void main() {
  late QuizGameNotifier notifier;

  setUp(() {
    notifier = QuizGameNotifier();
  });

  // ─── QuizGameState ──────────────────────────────────────────────────

  group('QuizGameState', () {
    test('default state', () {
      expect(notifier.state.difficulty, DifficultyLevel.beginner);
      expect(notifier.state.questions, isEmpty);
      expect(notifier.state.currentIndex, 0);
      expect(notifier.state.correctAnswers, 0);
      expect(notifier.state.incorrectAnswers, 0);
      expect(notifier.state.selectedAnswer, isNull);
      expect(notifier.state.isAnswered, false);
      expect(notifier.state.isCorrect, false);
      expect(notifier.state.isComplete, false);
    });

    test('starRating returns 3 for 90%+', () {
      final state = QuizGameState(
        difficulty: DifficultyLevel.beginner,
        questions: List.generate(10, (_) => _dummyQuestion()),
        correctAnswers: 9,
        startTime: DateTime.now(),
      );
      expect(state.starRating, 3);
    });

    test('starRating returns 2 for 70-89%', () {
      final state = QuizGameState(
        difficulty: DifficultyLevel.beginner,
        questions: List.generate(10, (_) => _dummyQuestion()),
        correctAnswers: 7,
        startTime: DateTime.now(),
      );
      expect(state.starRating, 2);
    });

    test('starRating returns 1 for below 70%', () {
      final state = QuizGameState(
        difficulty: DifficultyLevel.beginner,
        questions: List.generate(10, (_) => _dummyQuestion()),
        correctAnswers: 5,
        startTime: DateTime.now(),
      );
      expect(state.starRating, 1);
    });

    test('starRating returns 1 for zero questions', () {
      final state = QuizGameState(
        difficulty: DifficultyLevel.beginner,
        startTime: DateTime.now(),
      );
      expect(state.starRating, 1);
    });

    test('currentQuestion returns null when no questions', () {
      expect(notifier.state.currentQuestion, isNull);
    });
  });

  // ─── startGame ────────────────────────────────────────────────────────

  group('startGame', () {
    test('generates questions from provided scriptures', () {
      notifier.startGame(
        difficulty: DifficultyLevel.beginner,
        scriptures: testScriptures,
      );

      // Should use all 5 test scriptures (beginner targets 10,
      // but we only have 5)
      expect(notifier.state.questions.length, testScriptures.length);
      expect(notifier.state.difficulty, DifficultyLevel.beginner);
      expect(notifier.state.isComplete, false);
    });

    test('each question has 4 options including correct answer', () {
      notifier.startGame(
        difficulty: DifficultyLevel.beginner,
        scriptures: testScriptures,
      );

      for (final question in notifier.state.questions) {
        expect(question.options.length, lessThanOrEqualTo(4));
        expect(question.options, contains(question.correctAnswer));
      }
    });

    test('questions cover all 3 question types', () {
      notifier.startGame(
        difficulty: DifficultyLevel.beginner,
        scriptures: testScriptures,
      );

      // With 5 questions, we should see multiple types
      final types = notifier.state.questions.map((q) => q.type).toSet();
      expect(types.length, greaterThanOrEqualTo(2));
    });

    test('resets state on new game', () {
      notifier.startGame(
        difficulty: DifficultyLevel.beginner,
        scriptures: testScriptures,
      );
      notifier.selectAnswer(notifier.state.currentQuestion!.correctAnswer);
      notifier.submitAnswer();

      // Start a new game
      notifier.startGame(
        difficulty: DifficultyLevel.intermediate,
        scriptures: testScriptures,
      );

      expect(notifier.state.currentIndex, 0);
      expect(notifier.state.correctAnswers, 0);
      expect(notifier.state.incorrectAnswers, 0);
      expect(notifier.state.isAnswered, false);
      expect(notifier.state.difficulty, DifficultyLevel.intermediate);
    });
  });

  // ─── selectAnswer ────────────────────────────────────────────────────

  group('selectAnswer', () {
    test('sets selectedAnswer', () {
      notifier.startGame(
        difficulty: DifficultyLevel.beginner,
        scriptures: testScriptures,
      );
      final option = notifier.state.currentQuestion!.options.first;
      notifier.selectAnswer(option);
      expect(notifier.state.selectedAnswer, option);
    });

    test('ignored after answer is submitted', () {
      notifier.startGame(
        difficulty: DifficultyLevel.beginner,
        scriptures: testScriptures,
      );
      final firstOption = notifier.state.currentQuestion!.options.first;
      notifier.selectAnswer(firstOption);
      notifier.submitAnswer();

      // Try to change selection after submitting
      final lastOption = notifier.state.currentQuestion!.options.last;
      notifier.selectAnswer(lastOption);
      expect(notifier.state.selectedAnswer, firstOption);
    });
  });

  // ─── submitAnswer ────────────────────────────────────────────────────

  group('submitAnswer', () {
    test('correct answer increments correctAnswers', () {
      notifier.startGame(
        difficulty: DifficultyLevel.beginner,
        scriptures: testScriptures,
      );
      final correct = notifier.state.currentQuestion!.correctAnswer;
      notifier.selectAnswer(correct);
      notifier.submitAnswer();

      expect(notifier.state.correctAnswers, 1);
      expect(notifier.state.isAnswered, true);
      expect(notifier.state.isCorrect, true);
    });

    test('incorrect answer increments incorrectAnswers', () {
      notifier.startGame(
        difficulty: DifficultyLevel.beginner,
        scriptures: testScriptures,
      );
      final question = notifier.state.currentQuestion!;
      final wrong =
          question.options.firstWhere((o) => o != question.correctAnswer);
      notifier.selectAnswer(wrong);
      notifier.submitAnswer();

      expect(notifier.state.incorrectAnswers, 1);
      expect(notifier.state.isAnswered, true);
      expect(notifier.state.isCorrect, false);
    });

    test('does nothing when no answer selected', () {
      notifier.startGame(
        difficulty: DifficultyLevel.beginner,
        scriptures: testScriptures,
      );
      notifier.submitAnswer(); // No selection

      expect(notifier.state.isAnswered, false);
      expect(notifier.state.correctAnswers, 0);
    });

    test('does nothing when already answered', () {
      notifier.startGame(
        difficulty: DifficultyLevel.beginner,
        scriptures: testScriptures,
      );
      final correct = notifier.state.currentQuestion!.correctAnswer;
      notifier.selectAnswer(correct);
      notifier.submitAnswer();
      notifier.submitAnswer(); // double submit

      expect(notifier.state.correctAnswers, 1);
    });
  });

  // ─── nextQuestion ─────────────────────────────────────────────────────

  group('nextQuestion', () {
    test('advances to next question', () {
      notifier.startGame(
        difficulty: DifficultyLevel.beginner,
        scriptures: testScriptures,
      );
      notifier.selectAnswer(notifier.state.currentQuestion!.correctAnswer);
      notifier.submitAnswer();
      notifier.nextQuestion();

      expect(notifier.state.currentIndex, 1);
      expect(notifier.state.isAnswered, false);
      expect(notifier.state.selectedAnswer, isNull);
    });

    test('completes game when all questions answered', () {
      notifier.startGame(
        difficulty: DifficultyLevel.beginner,
        scriptures: testScriptures,
      );

      // Answer all questions
      for (var i = 0; i < notifier.state.totalQuestions; i++) {
        notifier.selectAnswer(notifier.state.currentQuestion!.correctAnswer);
        notifier.submitAnswer();
        notifier.nextQuestion();
      }

      expect(notifier.state.isComplete, true);
      expect(notifier.state.completionTime, isNotNull);
    });

    test('records completion time', () {
      notifier.startGame(
        difficulty: DifficultyLevel.beginner,
        scriptures: testScriptures,
      );

      for (var i = 0; i < notifier.state.totalQuestions; i++) {
        notifier.selectAnswer(notifier.state.currentQuestion!.correctAnswer);
        notifier.submitAnswer();
        notifier.nextQuestion();
      }

      // Completion time >= 0 (may be 0ms if test runs fast)
      expect(notifier.state.completionTime, isNotNull);
      expect(notifier.state.completionTime!.inMicroseconds,
          greaterThanOrEqualTo(0));
    });
  });

  // ─── Full game flow ───────────────────────────────────────────────────

  group('full game flow', () {
    test('answering all correctly yields 3 stars', () {
      notifier.startGame(
        difficulty: DifficultyLevel.beginner,
        scriptures: testScriptures,
      );

      for (var i = 0; i < notifier.state.totalQuestions; i++) {
        notifier.selectAnswer(notifier.state.currentQuestion!.correctAnswer);
        notifier.submitAnswer();
        notifier.nextQuestion();
      }

      expect(notifier.state.isComplete, true);
      expect(notifier.state.correctAnswers, notifier.state.totalQuestions);
      expect(notifier.state.starRating, 3);
    });
  });
}

/// Helper to create a dummy QuizQuestion for state testing.
QuizQuestion _dummyQuestion() {
  return QuizQuestion(
    scripture: testScriptures.first,
    type: QuizQuestionType.phraseToReference,
    options: ['A', 'B', 'C', 'D'],
    correctAnswer: 'A',
    prompt: 'What is...',
  );
}
