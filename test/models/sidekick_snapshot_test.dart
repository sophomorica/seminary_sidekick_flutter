import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/models/sidekick_snapshot.dart';

void main() {
  group('MasteryStats', () {
    test('construction with all fields', () {
      final stats = MasteryStats(
        total: 100,
        eternal: 5,
        mastered: 10,
        memorized: 15,
        familiar: 20,
        learning: 25,
        notStarted: 25,
        needsReview: 3,
        overallAccuracy: 85.5,
      );

      expect(stats.total, 100);
      expect(stats.eternal, 5);
      expect(stats.mastered, 10);
      expect(stats.memorized, 15);
      expect(stats.familiar, 20);
      expect(stats.learning, 25);
      expect(stats.notStarted, 25);
      expect(stats.needsReview, 3);
      expect(stats.overallAccuracy, 85.5);
    });

    test('toJson includes all fields', () {
      final stats = MasteryStats(
        total: 100,
        eternal: 0,
        mastered: 1,
        memorized: 2,
        familiar: 3,
        learning: 4,
        notStarted: 90,
        needsReview: 0,
        overallAccuracy: 72.3,
      );
      final json = stats.toJson();

      expect(json['total'], 100);
      expect(json['eternal'], 0);
      expect(json['mastered'], 1);
      expect(json['memorized'], 2);
      expect(json['familiar'], 3);
      expect(json['learning'], 4);
      expect(json['notStarted'], 90);
      expect(json['needsReview'], 0);
      expect(json['overallAccuracy'], 72.3);
    });
  });

  group('ScriptureProgressSummary', () {
    test('construction', () {
      final summary = ScriptureProgressSummary(
        scriptureId: '42',
        reference: 'Mosiah 3:19',
        topic: 'The Natural Man',
        masteryLevel: 'familiar',
        accuracy: 78.0,
        needsReview: true,
        daysSinceLastPractice: 15,
      );

      expect(summary.scriptureId, '42');
      expect(summary.reference, 'Mosiah 3:19');
      expect(summary.topic, 'The Natural Man');
      expect(summary.masteryLevel, 'familiar');
      expect(summary.accuracy, 78.0);
      expect(summary.needsReview, true);
      expect(summary.daysSinceLastPractice, 15);
    });

    test('toJson includes all fields', () {
      final json = ScriptureProgressSummary(
        scriptureId: '1',
        reference: 'Ref',
        topic: 'Topic',
        masteryLevel: 'learning',
        accuracy: 50.0,
        needsReview: false,
        daysSinceLastPractice: 3,
      ).toJson();

      expect(json['scriptureId'], '1');
      expect(json['reference'], 'Ref');
      expect(json['topic'], 'Topic');
      expect(json['masteryLevel'], 'learning');
      expect(json['accuracy'], 50.0);
      expect(json['needsReview'], false);
      expect(json['daysSinceLastPractice'], 3);
    });
  });

  group('SidekickSnapshot', () {
    SidekickSnapshot makeSnapshot({
      MasteryStats? stats,
      List<ScriptureProgressSummary>? needsAttention,
      List<String>? recentActivity,
      List<String>? goals,
      int curriculumWeek = 12,
      int daysActive = 30,
      int currentStreak = 5,
    }) {
      return SidekickSnapshot(
        masteryStats: stats ??
            MasteryStats(
              total: 100,
              eternal: 0,
              mastered: 0,
              memorized: 0,
              familiar: 0,
              learning: 0,
              notStarted: 100,
              needsReview: 0,
              overallAccuracy: 0.0,
            ),
        needsAttention: needsAttention ?? [],
        recentActivity: recentActivity ?? ['Practiced 1 Nephi 3:7'],
        curriculumWeek: curriculumWeek,
        goals: goals ?? [],
        daysActive: daysActive,
        currentStreak: currentStreak,
        generatedAt: '2026-04-09T12:00:00.000',
      );
    }

    test('construction with defaults', () {
      final snapshot = makeSnapshot();
      expect(snapshot.curriculumWeek, 12);
      expect(snapshot.daysActive, 30);
      expect(snapshot.currentStreak, 5);
      expect(snapshot.goals, isEmpty);
      expect(snapshot.recentActivity, hasLength(1));
    });

    test('toJson includes all fields', () {
      final snapshot = makeSnapshot(
        goals: ['Master BOM', 'Daily review'],
        needsAttention: [
          ScriptureProgressSummary(
            scriptureId: '42',
            reference: 'Mosiah 3:19',
            topic: 'Natural Man',
            masteryLevel: 'familiar',
            accuracy: 78.0,
            needsReview: true,
            daysSinceLastPractice: 15,
          ),
        ],
      );
      final json = snapshot.toJson();

      expect(json['curriculumWeek'], 12);
      expect(json['daysActive'], 30);
      expect(json['currentStreak'], 5);
      expect(json['goals'], ['Master BOM', 'Daily review']);
      expect(json['generatedAt'], '2026-04-09T12:00:00.000');
      expect(json['recentActivity'], hasLength(1));
      expect(json['needsAttention'], hasLength(1));
      expect((json['needsAttention'] as List).first['scriptureId'], '42');

      // Nested masteryStats
      final statsJson = json['masteryStats'] as Map<String, dynamic>;
      expect(statsJson['total'], 100);
      expect(statsJson['notStarted'], 100);
    });

    test('toJson with empty lists', () {
      final json = makeSnapshot(goals: [], needsAttention: []).toJson();
      expect(json['goals'], isEmpty);
      expect(json['needsAttention'], isEmpty);
    });
  });
}
