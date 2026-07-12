import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/models/sidekick_response.dart';

void main() {
  group('SidekickResponse', () {
    group('fromJson', () {
      test('parses full response', () {
        final json = {
          'dailyPrompt': 'Keep studying!',
          'suggestedGoal': {
            'title': 'Master 3 BOM passages',
            'description': 'Focus on Book of Mormon this week',
            'relatedScriptureIds': ['1', '2', '3'],
          },
          'quickWin': {
            'suggestion': 'Review 1 Nephi 3:7',
            'scriptureId': '1',
            'actionType': 'scriptureBuilder',
          },
          'timelineInsight': 'At your pace, you\'ll master all by June.',
          'reminder': 'Romans 1:16 hasn\'t been reviewed in 12 days.',
          'reflectionPrompts': ['How does this apply?', 'Who can you teach?'],
          'encouragement': 'Great work this week!',
          'connections': [
            {
              'fromReference': '1 Nephi 3:7',
              'toReference': 'Philippians 4:13',
              'insight': 'Both speak to trusting God\'s strength.',
            },
          ],
          'generatedAt': '2026-04-09T12:00:00.000',
        };

        final response = SidekickResponse.fromJson(json);
        expect(response.dailyPrompt, 'Keep studying!');
        expect(response.suggestedGoal, isNotNull);
        expect(response.suggestedGoal!.title, 'Master 3 BOM passages');
        expect(response.suggestedGoal!.relatedScriptureIds, ['1', '2', '3']);
        expect(response.quickWin, isNotNull);
        expect(response.quickWin!.suggestion, 'Review 1 Nephi 3:7');
        expect(response.quickWin!.scriptureId, '1');
        expect(response.quickWin!.actionType, 'scriptureBuilder');
        expect(response.timelineInsight, contains('June'));
        expect(response.reminder, contains('Romans 1:16'));
        expect(response.reflectionPrompts, hasLength(2));
        expect(response.encouragement, 'Great work this week!');
        expect(response.connections, hasLength(1));
        expect(response.connections.first.insight, contains('trusting'));
        expect(response.generatedAt, '2026-04-09T12:00:00.000');
      });

      test('parses minimal response (all optional fields missing)', () {
        final json = <String, dynamic>{};
        final response = SidekickResponse.fromJson(json);

        expect(response.dailyPrompt, isNull);
        expect(response.suggestedGoal, isNull);
        expect(response.quickWin, isNull);
        expect(response.timelineInsight, isNull);
        expect(response.reminder, isNull);
        expect(response.reflectionPrompts, isEmpty);
        expect(response.encouragement, isNull);
        expect(response.connections, isEmpty);
        expect(response.generatedAt, isNotEmpty); // defaults to now
      });

      test('gracefully handles null lists', () {
        final json = {
          'reflectionPrompts': null,
          'connections': null,
          'generatedAt': '2026-04-09T00:00:00.000',
        };
        final response = SidekickResponse.fromJson(json);
        expect(response.reflectionPrompts, isEmpty);
        expect(response.connections, isEmpty);
      });
    });

    group('toJson', () {
      test('includes only present fields', () {
        const response = SidekickResponse(
          dailyPrompt: 'Hello',
          generatedAt: '2026-04-09T00:00:00.000',
        );
        final json = response.toJson();

        expect(json['dailyPrompt'], 'Hello');
        expect(json['generatedAt'], '2026-04-09T00:00:00.000');
        expect(json.containsKey('suggestedGoal'), false);
        expect(json.containsKey('quickWin'), false);
        expect(json.containsKey('timelineInsight'), false);
        expect(json.containsKey('reminder'), false);
        expect(
            json.containsKey('reflectionPrompts'), false); // empty list omitted
        expect(json.containsKey('encouragement'), false);
        expect(json.containsKey('connections'), false);
      });

      test('includes non-empty lists', () {
        const response = SidekickResponse(
          reflectionPrompts: ['Prompt 1'],
          connections: [
            ScriptureConnection(
              fromReference: 'A',
              toReference: 'B',
              insight: 'Connection',
            ),
          ],
          generatedAt: '2026-04-09T00:00:00.000',
        );
        final json = response.toJson();
        expect(json['reflectionPrompts'], ['Prompt 1']);
        expect((json['connections'] as List).length, 1);
      });

      test('roundtrip preserves data', () {
        const original = SidekickResponse(
          dailyPrompt: 'Daily',
          suggestedGoal: SidekickGoal(
            title: 'Goal',
            description: 'Desc',
            relatedScriptureIds: ['5'],
          ),
          quickWin: QuickWin(
            suggestion: 'Do this',
            scriptureId: '10',
            actionType: 'review',
          ),
          timelineInsight: 'Timeline',
          reminder: 'Reminder',
          reflectionPrompts: ['P1', 'P2'],
          encouragement: 'Nice!',
          connections: [
            ScriptureConnection(
              fromReference: 'A',
              toReference: 'B',
              insight: 'Linked',
            ),
          ],
          generatedAt: '2026-04-09T12:00:00.000',
        );

        final roundtripped = SidekickResponse.fromJson(original.toJson());
        expect(roundtripped.dailyPrompt, original.dailyPrompt);
        expect(roundtripped.suggestedGoal!.title, 'Goal');
        expect(roundtripped.quickWin!.suggestion, 'Do this');
        expect(roundtripped.timelineInsight, 'Timeline');
        expect(roundtripped.reminder, 'Reminder');
        expect(roundtripped.reflectionPrompts, ['P1', 'P2']);
        expect(roundtripped.encouragement, 'Nice!');
        expect(roundtripped.connections.first.insight, 'Linked');
      });
    });

    group('offlineFallback', () {
      test('returns valid response with defaults', () {
        final fallback = SidekickResponse.offlineFallback();
        expect(fallback.dailyPrompt, isNotNull);
        expect(fallback.dailyPrompt, isNotEmpty);
        expect(fallback.encouragement, isNotNull);
        expect(fallback.generatedAt, isNotEmpty);
      });

      test('has no goals, quick wins, or connections', () {
        final fallback = SidekickResponse.offlineFallback();
        expect(fallback.suggestedGoal, isNull);
        expect(fallback.quickWin, isNull);
        expect(fallback.connections, isEmpty);
        expect(fallback.reflectionPrompts, isEmpty);
      });
    });
  });

  group('SidekickGoal', () {
    test('fromJson with all fields', () {
      final goal = SidekickGoal.fromJson({
        'title': 'Master 5 verses',
        'description': 'This week focus on NT',
        'relatedScriptureIds': ['10', '11'],
      });
      expect(goal.title, 'Master 5 verses');
      expect(goal.description, 'This week focus on NT');
      expect(goal.relatedScriptureIds, ['10', '11']);
    });

    test('fromJson with missing fields defaults gracefully', () {
      final goal = SidekickGoal.fromJson({});
      expect(goal.title, '');
      expect(goal.description, '');
      expect(goal.relatedScriptureIds, isEmpty);
    });

    test('toJson roundtrip', () {
      const original = SidekickGoal(
        title: 'T',
        description: 'D',
        relatedScriptureIds: ['1'],
      );
      final parsed = SidekickGoal.fromJson(original.toJson());
      expect(parsed.title, 'T');
      expect(parsed.description, 'D');
      expect(parsed.relatedScriptureIds, ['1']);
    });

    test('toJson omits empty relatedScriptureIds', () {
      const goal = SidekickGoal(title: 'T', description: 'D');
      final json = goal.toJson();
      expect(json.containsKey('relatedScriptureIds'), false);
    });
  });

  group('QuickWin', () {
    test('fromJson with all fields', () {
      final qw = QuickWin.fromJson({
        'suggestion': 'Review this',
        'scriptureId': '42',
        'actionType': 'scriptureBuilder',
      });
      expect(qw.suggestion, 'Review this');
      expect(qw.scriptureId, '42');
      expect(qw.actionType, 'scriptureBuilder');
    });

    test('fromJson with missing optional fields', () {
      final qw = QuickWin.fromJson({'suggestion': 'Do something'});
      expect(qw.suggestion, 'Do something');
      expect(qw.scriptureId, isNull);
      expect(qw.actionType, isNull);
    });

    test('toJson omits null fields', () {
      const qw = QuickWin(suggestion: 'Test');
      final json = qw.toJson();
      expect(json['suggestion'], 'Test');
      expect(json.containsKey('scriptureId'), false);
      expect(json.containsKey('actionType'), false);
    });

    test('toJson roundtrip', () {
      const original = QuickWin(
        suggestion: 'S',
        scriptureId: '5',
        actionType: 'review',
      );
      final parsed = QuickWin.fromJson(original.toJson());
      expect(parsed.suggestion, 'S');
      expect(parsed.scriptureId, '5');
      expect(parsed.actionType, 'review');
    });
  });

  group('ScriptureConnection', () {
    test('fromJson with all fields', () {
      final conn = ScriptureConnection.fromJson({
        'fromReference': '1 Nephi 3:7',
        'toReference': 'Philippians 4:13',
        'insight': 'Both about trusting God',
      });
      expect(conn.fromReference, '1 Nephi 3:7');
      expect(conn.toReference, 'Philippians 4:13');
      expect(conn.insight, 'Both about trusting God');
    });

    test('fromJson defaults empty for missing fields', () {
      final conn = ScriptureConnection.fromJson({});
      expect(conn.fromReference, '');
      expect(conn.toReference, '');
      expect(conn.insight, '');
    });

    test('toJson roundtrip', () {
      const original = ScriptureConnection(
        fromReference: 'A',
        toReference: 'B',
        insight: 'C',
      );
      final parsed = ScriptureConnection.fromJson(original.toJson());
      expect(parsed.fromReference, 'A');
      expect(parsed.toReference, 'B');
      expect(parsed.insight, 'C');
    });
  });

  group('SidekickMessage', () {
    final ts = DateTime(2026, 4, 9, 12, 0, 0);

    test('construction', () {
      final msg =
          SidekickMessage(role: 'user', content: 'Hello', timestamp: ts);
      expect(msg.role, 'user');
      expect(msg.content, 'Hello');
      expect(msg.timestamp, ts);
    });

    test('toApiMessage returns role and content only', () {
      final msg =
          SidekickMessage(role: 'assistant', content: 'Hi', timestamp: ts);
      final api = msg.toApiMessage();
      expect(api, {'role': 'assistant', 'content': 'Hi'});
      expect(api.containsKey('timestamp'), false);
    });

    test('toJson includes timestamp', () {
      final msg = SidekickMessage(role: 'user', content: 'Test', timestamp: ts);
      final json = msg.toJson();
      expect(json['role'], 'user');
      expect(json['content'], 'Test');
      expect(json['timestamp'], ts.toIso8601String());
    });

    test('fromJson roundtrip', () {
      final original =
          SidekickMessage(role: 'user', content: 'Q', timestamp: ts);
      final parsed = SidekickMessage.fromJson(original.toJson());
      expect(parsed.role, 'user');
      expect(parsed.content, 'Q');
      expect(parsed.timestamp, ts);
    });
  });

  group('sanitized (AI-hallucinated scripture IDs)', () {
    const validIds = {'1', '2', '42'};

    test('nulls quickWin.scriptureId when not a real ID, keeps suggestion',
        () {
      final response = SidekickResponse.fromJson({
        'quickWin': {
          'suggestion': 'Spend 2 minutes reviewing Mosiah 3:19',
          'scriptureId': 'Mosiah 3:19', // hallucinated reference, not an ID
          'actionType': 'review',
        },
      }).sanitized(validIds);

      expect(response.quickWin, isNotNull);
      expect(response.quickWin!.suggestion, contains('Mosiah'));
      expect(response.quickWin!.scriptureId, isNull);
      expect(response.quickWin!.actionType, 'review');
    });

    test('keeps quickWin.scriptureId when valid', () {
      final response = SidekickResponse.fromJson({
        'quickWin': {'suggestion': 'Review it', 'scriptureId': '42'},
      }).sanitized(validIds);

      expect(response.quickWin!.scriptureId, '42');
    });

    test('filters invalid relatedScriptureIds from suggestedGoal', () {
      final response = SidekickResponse.fromJson({
        'suggestedGoal': {
          'title': 'Goal',
          'description': 'Desc',
          'relatedScriptureIds': ['1', '999', 'John 3:16'],
        },
      }).sanitized(validIds);

      expect(response.suggestedGoal!.relatedScriptureIds, ['1']);
    });

    test('drops starterQuestions with invalid IDs', () {
      final response = SidekickResponse.fromJson({
        'starterQuestions': [
          {'scriptureId': '2', 'question': 'Valid?'},
          {'scriptureId': '101', 'question': 'Invalid.'},
        ],
      }).sanitized(validIds);

      expect(response.starterQuestions, hasLength(1));
      expect(response.starterQuestions.first.scriptureId, '2');
    });

    test('passes through untouched fields', () {
      final response = SidekickResponse.fromJson({
        'dailyPrompt': 'Hi',
        'reminder': 'Review soon',
        'reflectionPrompts': ['Think about it'],
        'encouragement': 'Nice work',
        'generatedAt': '2026-07-11T08:00:00.000',
      }).sanitized(validIds);

      expect(response.dailyPrompt, 'Hi');
      expect(response.reminder, 'Review soon');
      expect(response.reflectionPrompts, ['Think about it']);
      expect(response.encouragement, 'Nice work');
      expect(response.generatedAt, '2026-07-11T08:00:00.000');
    });

    test('fromJson tolerates numeric scriptureId (coerces to string)', () {
      final response = SidekickResponse.fromJson({
        'quickWin': {'suggestion': 'Review', 'scriptureId': 42},
        'starterQuestions': [
          {'scriptureId': 2, 'question': 'Q?'},
        ],
        'suggestedGoal': {
          'title': 'T',
          'description': 'D',
          'relatedScriptureIds': [1, '2'],
        },
      });

      expect(response.quickWin!.scriptureId, '42');
      expect(response.starterQuestions.first.scriptureId, '2');
      expect(response.suggestedGoal!.relatedScriptureIds, ['1', '2']);
    });
  });
}
