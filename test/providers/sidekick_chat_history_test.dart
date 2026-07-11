import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/models/sidekick_response.dart';
import 'package:seminary_sidekick/providers/sidekick_provider.dart';
import 'package:seminary_sidekick/services/sidekick_service.dart';

SidekickMessage _msg(String role, String content, {int index = 0}) {
  return SidekickMessage(
    role: role,
    content: content,
    timestamp: DateTime.utc(2026, 7, 11, 12, 0, index),
  );
}

List<SidekickMessage> _nMessages(int n) {
  return List.generate(
    n,
    (i) => _msg(i.isEven ? 'user' : 'assistant', 'm$i', index: i),
  );
}

void main() {
  group('selectRecentChatHistory (API window)', () {
    test('returns all messages when under the window', () {
      final history = _nMessages(5);
      final recent = selectRecentChatHistory(history, window: 20);
      expect(recent, hasLength(5));
      expect(recent.first.content, 'm0');
      expect(recent.last.content, 'm4');
    });

    test('returns the last N messages, not the first N', () {
      final history = _nMessages(25);
      final recent = selectRecentChatHistory(history, window: 20);
      expect(recent, hasLength(20));
      expect(recent.first.content, 'm5'); // 25 - 20 = 5
      expect(recent.last.content, 'm24');
    });

    test('default window matches SidekickService.apiHistoryWindow', () {
      final history = _nMessages(SidekickService.apiHistoryWindow + 3);
      final recent = selectRecentChatHistory(history);
      expect(recent, hasLength(SidekickService.apiHistoryWindow));
      expect(recent.first.content, 'm3');
      expect(recent.last.content, 'm${SidekickService.apiHistoryWindow + 2}');
    });

    test('empty history stays empty', () {
      expect(selectRecentChatHistory(const []), isEmpty);
    });
  });

  group('trimChatHistory (storage cap)', () {
    test('returns all messages when under the cap', () {
      final history = _nMessages(10);
      final trimmed = trimChatHistory(history, max: 50);
      expect(trimmed, hasLength(10));
      expect(trimmed.first.content, 'm0');
    });

    test('keeps only the most recent max messages', () {
      final history = _nMessages(60);
      final trimmed = trimChatHistory(history, max: 50);
      expect(trimmed, hasLength(50));
      expect(trimmed.first.content, 'm10');
      expect(trimmed.last.content, 'm59');
    });

    test('default max matches SidekickNotifier.maxStoredMessages', () {
      final history = _nMessages(SidekickNotifier.maxStoredMessages + 5);
      final trimmed = trimChatHistory(history);
      expect(trimmed, hasLength(SidekickNotifier.maxStoredMessages));
      expect(trimmed.first.content, 'm5');
    });
  });
}
