import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/providers/goals_provider.dart';
import 'package:seminary_sidekick/models/sidekick_response.dart';

void main() {
  // ─── Goal model ───────────────────────────────────────────────────────

  group('Goal', () {
    final now = DateTime(2026, 4, 9, 12, 0, 0);

    Goal makeGoal({
      String id = 'goal-1',
      String title = 'Master 5 verses',
      String description = 'Focus on BOM this week',
      List<String> relatedScriptureIds = const [],
      bool isSidekickSuggestion = false,
      bool isAccepted = true,
      bool isCompleted = false,
      DateTime? completedAt,
    }) {
      return Goal(
        id: id,
        title: title,
        description: description,
        relatedScriptureIds: relatedScriptureIds,
        isSidekickSuggestion: isSidekickSuggestion,
        isAccepted: isAccepted,
        isCompleted: isCompleted,
        createdAt: now,
        completedAt: completedAt,
      );
    }

    group('construction', () {
      test('creates with required fields', () {
        final goal = makeGoal();
        expect(goal.id, 'goal-1');
        expect(goal.title, 'Master 5 verses');
        expect(goal.description, 'Focus on BOM this week');
        expect(goal.relatedScriptureIds, isEmpty);
        expect(goal.isSidekickSuggestion, false);
        expect(goal.isAccepted, true);
        expect(goal.isCompleted, false);
        expect(goal.createdAt, now);
        expect(goal.completedAt, isNull);
      });
    });

    group('copyWith', () {
      test('copies with title change', () {
        final copy = makeGoal().copyWith(title: 'New title');
        expect(copy.title, 'New title');
        expect(copy.id, 'goal-1'); // unchanged
      });

      test('copies with completion', () {
        final completedTime = now.add(const Duration(hours: 2));
        final copy = makeGoal().copyWith(
          isCompleted: true,
          completedAt: completedTime,
        );
        expect(copy.isCompleted, true);
        expect(copy.completedAt, completedTime);
      });

      test('preserves isSidekickSuggestion (not copyable)', () {
        final goal = makeGoal(isSidekickSuggestion: true);
        final copy = goal.copyWith(title: 'Changed');
        expect(copy.isSidekickSuggestion, true);
      });

      test('copies acceptance', () {
        final goal = makeGoal(isAccepted: false);
        final copy = goal.copyWith(isAccepted: true);
        expect(copy.isAccepted, true);
      });
    });

    group('JSON serialization', () {
      test('toJson includes all fields', () {
        final completed = now.add(const Duration(days: 1));
        final json = makeGoal(
          relatedScriptureIds: ['1', '2'],
          isSidekickSuggestion: true,
          isCompleted: true,
          completedAt: completed,
        ).toJson();

        expect(json['id'], 'goal-1');
        expect(json['title'], 'Master 5 verses');
        expect(json['description'], 'Focus on BOM this week');
        expect(json['relatedScriptureIds'], ['1', '2']);
        expect(json['isSidekickSuggestion'], true);
        expect(json['isCompleted'], true);
        expect(json['completedAt'], completed.toIso8601String());
      });

      test('toJson omits null completedAt', () {
        final json = makeGoal().toJson();
        expect(json.containsKey('completedAt'), false);
      });

      test('fromJson parses all fields', () {
        final json = {
          'id': 'g1',
          'title': 'Study',
          'description': 'Desc',
          'relatedScriptureIds': ['3'],
          'isSidekickSuggestion': true,
          'isAccepted': true,
          'isCompleted': false,
          'createdAt': now.toIso8601String(),
        };
        final goal = Goal.fromJson(json);
        expect(goal.id, 'g1');
        expect(goal.title, 'Study');
        expect(goal.relatedScriptureIds, ['3']);
        expect(goal.isSidekickSuggestion, true);
      });

      test('fromJson handles missing optional fields', () {
        final json = {
          'id': 'g1',
          'title': 'T',
          'createdAt': now.toIso8601String(),
        };
        final goal = Goal.fromJson(json);
        expect(goal.description, '');
        expect(goal.relatedScriptureIds, isEmpty);
        expect(goal.isSidekickSuggestion, false);
        expect(goal.isAccepted, false);
        expect(goal.isCompleted, false);
        expect(goal.completedAt, isNull);
      });

      test('roundtrip preserves data', () {
        final original = makeGoal(
          relatedScriptureIds: ['5'],
          isSidekickSuggestion: true,
          isCompleted: true,
          completedAt: now.add(const Duration(hours: 1)),
        );
        final parsed = Goal.fromJson(original.toJson());
        expect(parsed.id, original.id);
        expect(parsed.title, original.title);
        expect(parsed.description, original.description);
        expect(parsed.relatedScriptureIds, original.relatedScriptureIds);
        expect(parsed.isSidekickSuggestion, original.isSidekickSuggestion);
        expect(parsed.isCompleted, original.isCompleted);
      });
    });

    group('fromSidekickGoal', () {
      test('creates goal from SidekickGoal', () {
        const sidekickGoal = SidekickGoal(
          title: 'Master D&C passages',
          description: 'Focus on D&C this week',
          relatedScriptureIds: ['50', '51'],
        );
        final goal = Goal.fromSidekickGoal(sidekickGoal);

        expect(goal.title, 'Master D&C passages');
        expect(goal.description, 'Focus on D&C this week');
        expect(goal.relatedScriptureIds, ['50', '51']);
        expect(goal.isSidekickSuggestion, true);
        expect(goal.isAccepted, false);
        expect(goal.isCompleted, false);
        expect(goal.id, startsWith('sidekick_'));
      });
    });
  });

  // ─── GoalsState ───────────────────────────────────────────────────────

  group('GoalsState', () {
    final now = DateTime(2026, 4, 9);

    Goal makeGoal({
      String id = 'g1',
      bool isAccepted = true,
      bool isCompleted = false,
      DateTime? completedAt,
    }) {
      return Goal(
        id: id,
        title: 'Goal $id',
        description: '',
        isAccepted: isAccepted,
        isCompleted: isCompleted,
        createdAt: now,
        completedAt: completedAt,
      );
    }

    test('defaults', () {
      const state = GoalsState();
      expect(state.goals, isEmpty);
      expect(state.pendingSuggestion, isNull);
      expect(state.timelineInsight, isNull);
      expect(state.reminder, isNull);
      expect(state.reminderDismissed, false);
    });

    test('activeGoals returns only accepted, non-completed goals', () {
      final state = GoalsState(goals: [
        makeGoal(id: 'a', isAccepted: true, isCompleted: false),
        makeGoal(id: 'b', isAccepted: false, isCompleted: false),
        makeGoal(id: 'c', isAccepted: true, isCompleted: true),
        makeGoal(id: 'd', isAccepted: true, isCompleted: false),
      ]);

      final active = state.activeGoals;
      expect(active, hasLength(2));
      expect(active.map((g) => g.id), containsAll(['a', 'd']));
    });

    test('completedGoals returns only completed goals, newest first', () {
      final state = GoalsState(goals: [
        makeGoal(id: 'a', isCompleted: true, completedAt: now),
        makeGoal(
            id: 'b',
            isCompleted: true,
            completedAt: now.add(const Duration(days: 1))),
        makeGoal(id: 'c', isCompleted: false),
      ]);

      final completed = state.completedGoals;
      expect(completed, hasLength(2));
      expect(completed.first.id, 'b'); // newer first
    });

    group('copyWith', () {
      test('clearPendingSuggestion', () {
        final goal = makeGoal(id: 'pending', isAccepted: false);
        final state = GoalsState(pendingSuggestion: goal);
        final copy = state.copyWith(clearPendingSuggestion: true);
        expect(copy.pendingSuggestion, isNull);
      });

      test('clearReminder', () {
        const state = GoalsState(reminder: 'Review today');
        final copy = state.copyWith(clearReminder: true);
        expect(copy.reminder, isNull);
      });

      test('clearTimeline', () {
        const state = GoalsState(timelineInsight: 'On track');
        final copy = state.copyWith(clearTimeline: true);
        expect(copy.timelineInsight, isNull);
      });

      test('sets reminderDismissed', () {
        const state = GoalsState(reminder: 'Hey');
        final copy = state.copyWith(reminderDismissed: true);
        expect(copy.reminderDismissed, true);
        expect(copy.reminder, 'Hey'); // still there, just dismissed
      });
    });
  });
}
