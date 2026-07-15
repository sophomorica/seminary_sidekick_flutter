import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/models/enums.dart';
import 'package:seminary_sidekick/services/score_story_engine.dart';

void main() {
  ScoreStory build({
    int correct = 5,
    int incorrect = 1,
    int totalPairs = 5,
    Duration time = const Duration(seconds: 30),
    GameType gameType = GameType.scriptureBuilder,
    DifficultyLevel difficulty = DifficultyLevel.beginner,
  }) {
    return ScoreStoryEngine.build(
      gameType: gameType,
      difficulty: difficulty,
      correctMatches: correct,
      incorrectAttempts: incorrect,
      totalPairs: totalPairs,
      completionTime: time,
    );
  }

  group('ScoreStoryEngine.build', () {
    test('event order is Accuracy → Speed → Misses/Flawless → Finish', () {
      final withMisses = build(incorrect: 2);
      expect(
        withMisses.events.map((e) => e.label).toList(),
        ['Accuracy', 'Speed bonus', 'Misses', 'Finish bonus'],
      );

      final flawless = build(incorrect: 0);
      expect(
        flawless.events.map((e) => e.label).toList(),
        ['Accuracy', 'Speed bonus', 'Flawless', 'Finish bonus'],
      );
    });

    test('accuracy is 600 * correct / (correct + incorrect)', () {
      final story = build(correct: 5, incorrect: 1);
      expect(story.events.first.label, 'Accuracy');
      expect(story.events.first.points, (600 * 5 / 6).round());
    });

    test('0 misses emits Flawless +50 instead of Misses', () {
      final story = build(incorrect: 0);
      final flawless = story.events.firstWhere((e) => e.label == 'Flawless');
      expect(flawless.points, 50);
      expect(flawless.isMiss, isFalse);
      expect(story.events.any((e) => e.label == 'Misses'), isFalse);
    });

    test('miss penalty is -20 per miss capped at -150', () {
      expect(
        build(incorrect: 3).events.firstWhere((e) => e.isMiss).points,
        -60,
      );
      expect(
        build(incorrect: 20).events.firstWhere((e) => e.isMiss).points,
        -150,
      );
    });

    test('finish bonus is flat +150', () {
      final story = build();
      expect(story.events.last.label, 'Finish bonus');
      expect(story.events.last.points, 150);
    });

    test('final score clamps to 0–1000 and matches event sum when in range', () {
      final story = build(correct: 5, incorrect: 0, time: Duration.zero);
      final sum = story.events.fold<int>(0, (s, e) => s + e.points);
      expect(story.finalScore, sum.clamp(0, 1000));
      expect(story.finalScore, inInclusiveRange(0, 1000));
    });

    test('grade thresholds', () {
      expect(ScoreStoryEngine.gradeForScore(900), ScoreGrade.masterful);
      expect(ScoreStoryEngine.gradeForScore(899), ScoreGrade.strong);
      expect(ScoreStoryEngine.gradeForScore(750), ScoreGrade.strong);
      expect(ScoreStoryEngine.gradeForScore(749), ScoreGrade.gettingThere);
      expect(ScoreStoryEngine.gradeForScore(500), ScoreGrade.gettingThere);
      expect(ScoreStoryEngine.gradeForScore(499), ScoreGrade.keepPracticing);
    });

    test('speed bonus is full under par and falls off after', () {
      final underPar = build(time: const Duration(seconds: 10));
      final speedFull =
          underPar.events.firstWhere((e) => e.label == 'Speed bonus');
      expect(speedFull.points, 250);

      final slow = build(time: const Duration(seconds: 1000));
      final speedSlow =
          slow.events.firstWhere((e) => e.label == 'Speed bonus');
      expect(speedSlow.points, 0);
    });

    test('determinism — same inputs produce identical stories', () {
      final a = build();
      final b = build();
      expect(a.finalScore, b.finalScore);
      expect(a.grade, b.grade);
      expect(a.events.length, b.events.length);
      for (var i = 0; i < a.events.length; i++) {
        expect(a.events[i].label, b.events[i].label);
        expect(a.events[i].points, b.events[i].points);
        expect(a.events[i].isMiss, b.events[i].isMiss);
      }
    });
  });

  group('ScoreStoryEngine.buildGroupQuiz', () {
    test('normalizes raw score against maxPossible to 0–1000', () {
      final story = ScoreStoryEngine.buildGroupQuiz(
        rawScore: 5000,
        maxPossible: 10000,
        correctCount: 5,
        incorrectCount: 1,
        questionCount: 6,
      );
      expect(story.finalScore, 500);
      expect(story.events.length, inInclusiveRange(2, 3));
      expect(story.events.any((e) => e.isMiss), isTrue);
    });

    test('event sum adjusted so running story lands on normalized final', () {
      final story = ScoreStoryEngine.buildGroupQuiz(
        rawScore: 8000,
        maxPossible: 10000,
        correctCount: 8,
        incorrectCount: 2,
        questionCount: 10,
      );
      final sum = story.events.fold<int>(0, (s, e) => s + e.points);
      expect(sum.clamp(0, 1000), story.finalScore);
    });
  });
}
