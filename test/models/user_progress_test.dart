import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/models/user_progress.dart';
import 'package:seminary_sidekick/models/enums.dart';

void main() {
  group('UserProgress — default construction', () {
    test('default values are correct', () {
      const progress = UserProgress(
        scriptureId: 'test-1',
        gameType: GameType.matching,
      );
      expect(progress.scriptureId, equals('test-1'));
      expect(progress.gameType, equals(GameType.matching));
      expect(progress.highestDifficultyCompleted,
          equals(DifficultyLevel.beginner));
      expect(progress.totalAttempts, equals(0));
      expect(progress.correctAttempts, equals(0));
      expect(progress.currentStreak, equals(0));
      expect(progress.bestStreak, equals(0));
      expect(progress.bestTime, isNull);
      expect(progress.lastPracticed, isNull);
      expect(progress.accuracy, equals(0.0));
      expect(progress.masteryLevel, equals(MasteryLevel.newScripture));
      expect(progress.needsReview, isTrue);
    });

    test('explicit values are preserved', () {
      final now = DateTime.now();
      final progress = UserProgress(
        scriptureId: 'test-2',
        gameType: GameType.quiz,
        highestDifficultyCompleted: DifficultyLevel.advanced,
        totalAttempts: 10,
        correctAttempts: 8,
        currentStreak: 3,
        bestStreak: 5,
        bestTime: 45,
        lastPracticed: now,
        accuracy: 80.0,
        masteryLevel: MasteryLevel.memorized,
        needsReview: false,
      );
      expect(progress.scriptureId, equals('test-2'));
      expect(progress.gameType, equals(GameType.quiz));
      expect(progress.highestDifficultyCompleted,
          equals(DifficultyLevel.advanced));
      expect(progress.totalAttempts, equals(10));
      expect(progress.correctAttempts, equals(8));
      expect(progress.currentStreak, equals(3));
      expect(progress.bestStreak, equals(5));
      expect(progress.bestTime, equals(45));
      expect(progress.lastPracticed, equals(now));
      expect(progress.accuracy, equals(80.0));
      expect(progress.masteryLevel, equals(MasteryLevel.memorized));
      expect(progress.needsReview, isFalse);
    });
  });

  group('UserProgress — storageKey', () {
    test('storageKey format is scriptureId_gameTypeName', () {
      const progress = UserProgress(
        scriptureId: 'test-1',
        gameType: GameType.matching,
      );
      expect(progress.storageKey, equals('test-1_matching'));
    });

    test('storageKey for wordOrder', () {
      const progress = UserProgress(
        scriptureId: '42',
        gameType: GameType.wordOrder,
      );
      expect(progress.storageKey, equals('42_wordOrder'));
    });

    test('storageKey for quiz', () {
      const progress = UserProgress(
        scriptureId: 'test-5',
        gameType: GameType.quiz,
      );
      expect(progress.storageKey, equals('test-5_quiz'));
    });
  });

  group('UserProgress — toJson / fromJson', () {
    test('round-trip serialization preserves all fields', () {
      final now = DateTime.now();
      final original = UserProgress(
        scriptureId: 'test-1',
        gameType: GameType.matching,
        highestDifficultyCompleted: DifficultyLevel.intermediate,
        totalAttempts: 15,
        correctAttempts: 12,
        currentStreak: 4,
        bestStreak: 7,
        bestTime: 30,
        lastPracticed: now,
        accuracy: 80.0,
        masteryLevel: MasteryLevel.memorized,
        needsReview: false,
        consecutivePerfectMaster: 2,
      );

      final json = original.toJson();
      final restored = UserProgress.fromJson(json);

      expect(restored.scriptureId, equals(original.scriptureId));
      expect(restored.gameType, equals(original.gameType));
      expect(restored.highestDifficultyCompleted,
          equals(original.highestDifficultyCompleted));
      expect(restored.totalAttempts, equals(original.totalAttempts));
      expect(restored.correctAttempts, equals(original.correctAttempts));
      expect(restored.currentStreak, equals(original.currentStreak));
      expect(restored.bestStreak, equals(original.bestStreak));
      expect(restored.bestTime, equals(original.bestTime));
      expect(restored.accuracy, equals(original.accuracy));
      expect(restored.masteryLevel, equals(original.masteryLevel));
      expect(restored.needsReview, equals(original.needsReview));
      expect(restored.consecutivePerfectMaster,
          equals(original.consecutivePerfectMaster));
    });

    test('toJson produces expected keys', () {
      const progress = UserProgress(
        scriptureId: 'test-1',
        gameType: GameType.matching,
      );
      final json = progress.toJson();

      expect(json, containsPair('scriptureId', 'test-1'));
      expect(json, containsPair('gameType', 'matching'));
      expect(json, containsPair('highestDifficultyCompleted', 'beginner'));
      expect(json, containsPair('totalAttempts', 0));
      expect(json, containsPair('correctAttempts', 0));
      expect(json, containsPair('currentStreak', 0));
      expect(json, containsPair('bestStreak', 0));
      expect(json, containsPair('bestTime', null));
      expect(json, containsPair('accuracy', 0.0));
      expect(json, containsPair('masteryLevel', 'newScripture'));
      expect(json, containsPair('needsReview', true));
    });

    test('fromJson with null bestTime and lastPracticed', () {
      final json = {
        'scriptureId': 'test-2',
        'gameType': 'quiz',
        'highestDifficultyCompleted': 'beginner',
        'totalAttempts': 0,
        'correctAttempts': 0,
        'currentStreak': 0,
        'bestStreak': 0,
        'bestTime': null,
        'lastPracticed': null,
        'accuracy': 0.0,
        'masteryLevel': 'newScripture',
        'needsReview': true,
      };

      final progress = UserProgress.fromJson(json);
      expect(progress.bestTime, isNull);
      expect(progress.lastPracticed, isNull);
    });

    test('fromJson defaults consecutivePerfectMaster to 0 when missing (backward compat)', () {
      final json = {
        'scriptureId': 'test-1',
        'gameType': 'matching',
        'highestDifficultyCompleted': 'beginner',
        'totalAttempts': 5,
        'correctAttempts': 3,
        'currentStreak': 1,
        'bestStreak': 2,
        'bestTime': null,
        'lastPracticed': null,
        'accuracy': 60.0,
        'masteryLevel': 'learning',
        'needsReview': true,
        // NOTE: no 'consecutivePerfectMaster' key — simulates old Hive data
      };

      final progress = UserProgress.fromJson(json);
      expect(progress.consecutivePerfectMaster, equals(0));
    });

    test('toJson includes consecutivePerfectMaster', () {
      const progress = UserProgress(
        scriptureId: 'test-1',
        gameType: GameType.wordOrder,
        consecutivePerfectMaster: 3,
      );
      final json = progress.toJson();
      expect(json, containsPair('consecutivePerfectMaster', 3));
    });

    test('fromJson handles integer accuracy as num', () {
      final json = {
        'scriptureId': 'test-1',
        'gameType': 'matching',
        'highestDifficultyCompleted': 'beginner',
        'totalAttempts': 1,
        'correctAttempts': 1,
        'currentStreak': 1,
        'bestStreak': 1,
        'bestTime': null,
        'lastPracticed': null,
        'accuracy': 100, // integer, not double
        'masteryLevel': 'mastered',
        'needsReview': false,
      };

      final progress = UserProgress.fromJson(json);
      expect(progress.accuracy, equals(100.0));
    });
  });
}
