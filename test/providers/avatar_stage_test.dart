import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/models/enums.dart';
import 'package:seminary_sidekick/providers/progress_provider.dart';

void main() {
  group('UserStats.avatarStageForMastered thresholds', () {
    test('0–2 → Quick to Observe', () {
      expect(UserStats.avatarStageForMastered(0), AvatarStage.quickToObserve);
      expect(UserStats.avatarStageForMastered(2), AvatarStage.quickToObserve);
    });

    test('3–9 → Stalwart', () {
      expect(UserStats.avatarStageForMastered(3), AvatarStage.stalwart);
      expect(UserStats.avatarStageForMastered(9), AvatarStage.stalwart);
    });

    test('10–24 → Stripling Warrior', () {
      expect(
          UserStats.avatarStageForMastered(10), AvatarStage.striplingWarrior);
      expect(
          UserStats.avatarStageForMastered(24), AvatarStage.striplingWarrior);
    });

    test('25+ → Standard Bearer', () {
      expect(
          UserStats.avatarStageForMastered(25), AvatarStage.standardBearer);
      expect(
          UserStats.avatarStageForMastered(100), AvatarStage.standardBearer);
    });

    test('UserStats.avatarStage getter uses totalMastered', () {
      final stats = UserStats(
        totalAttempted: 10,
        totalMemorized: 4,
        totalMastered: 3,
        needsReview: 0,
        currentStreak: 1,
        overallAccuracy: 80,
      );
      expect(stats.avatarStage, AvatarStage.stalwart);
    });
  });

  group('AvatarStage.forMasteryLevel (per-scripture staging)', () {
    test('maps the six mastery levels onto the four stages', () {
      expect(AvatarStage.forMasteryLevel(MasteryLevel.newScripture),
          AvatarStage.quickToObserve);
      expect(AvatarStage.forMasteryLevel(MasteryLevel.learning),
          AvatarStage.quickToObserve);
      expect(AvatarStage.forMasteryLevel(MasteryLevel.familiar),
          AvatarStage.stalwart);
      expect(AvatarStage.forMasteryLevel(MasteryLevel.memorized),
          AvatarStage.striplingWarrior);
      expect(AvatarStage.forMasteryLevel(MasteryLevel.mastered),
          AvatarStage.standardBearer);
      expect(AvatarStage.forMasteryLevel(MasteryLevel.eternal),
          AvatarStage.standardBearer);
    });
  });

  group('AvatarStage metadata', () {
    test('has four stages numbered 1–4', () {
      expect(AvatarStage.values.length, 4);
      expect(AvatarStage.quickToObserve.stageNumber, 1);
      expect(AvatarStage.standardBearer.stageNumber, 4);
      expect(AvatarStage.stalwart.stageOfLabel, 'Stage 2 of 4');
    });
  });
}
