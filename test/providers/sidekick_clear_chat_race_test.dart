import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/models/sidekick_response.dart';
import 'package:seminary_sidekick/models/sidekick_snapshot.dart';
import 'package:seminary_sidekick/providers/sidekick_provider.dart';
import 'package:seminary_sidekick/services/sidekick_service.dart';

/// Controllable SidekickService for in-flight / clearChat races.
class _FakeSidekickService extends SidekickService {
  final List<Completer<String>> _pending = [];

  int chatCallCount = 0;
  List<String> lastUserMessages = [];

  /// Enqueue a hanging reply the next [chat] call will await.
  Completer<String> enqueueHang() {
    final c = Completer<String>();
    _pending.add(c);
    return c;
  }

  /// Enqueue an immediately-completing reply.
  void enqueueReply(String reply) {
    _pending.add(Completer<String>()..complete(reply));
  }

  @override
  Future<String> chat({
    required SidekickSnapshot snapshot,
    required List<SidekickMessage> history,
    required String userMessage,
  }) async {
    chatCallCount++;
    lastUserMessages.add(userMessage);
    if (_pending.isEmpty) return 'fallback-reply';
    return _pending.removeAt(0).future;
  }
}

void main() {
  group('SidekickNotifier clearChat vs in-flight send', () {
    late ProviderContainer container;
    late _FakeSidekickService fake;
    late SidekickNotifier notifier;

    setUp(() {
      fake = _FakeSidekickService();
      container = ProviderContainer(
        overrides: [
          sidekickProvider.overrideWith(
            (ref) => SidekickNotifier(ref, service: fake),
          ),
        ],
      );
      notifier = container.read(sidekickProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test(
        'clearChat during in-flight send discards stale completion '
        'and allows a fresh hot-button send', () async {
      final stale = fake.enqueueHang();
      fake.enqueueReply('fresh sidekick reply');

      // Start an in-flight send (optimistic user bubble + loading).
      final staleFuture = notifier.sendMessage('old question');
      await Future<void>.delayed(Duration.zero);
      expect(container.read(sidekickProvider).isLoadingChat, isTrue);
      expect(
        container.read(sidekickProvider).chatHistory.single.content,
        'old question',
      );
      final epochBeforeClear = notifier.chatEpoch;

      // Hot-button path: clear then send starter.
      notifier.clearChat();
      expect(notifier.chatEpoch, epochBeforeClear + 1);
      expect(container.read(sidekickProvider).chatHistory, isEmpty);
      expect(container.read(sidekickProvider).isLoadingChat, isFalse);

      final freshFuture = notifier.sendMessage('hot button starter');
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(sidekickProvider).chatHistory.first.content,
        'hot button starter',
      );
      expect(
        container
            .read(sidekickProvider)
            .chatHistory
            .any((m) => m.content == 'old question'),
        isFalse,
      );

      // Stale in-flight completes — must not resurrect old thread.
      stale.complete('stale sidekick reply');
      await staleFuture;
      expect(
        container.read(sidekickProvider).chatHistory.any(
              (m) => m.content.contains('old') || m.content.contains('stale'),
            ),
        isFalse,
      );

      await freshFuture;
      final history = container.read(sidekickProvider).chatHistory;
      expect(history, hasLength(2));
      expect(history[0].content, 'hot button starter');
      expect(history[0].role, 'user');
      expect(history[1].content, 'fresh sidekick reply');
      expect(history[1].role, 'assistant');
      expect(container.read(sidekickProvider).isLoadingChat, isFalse);
      expect(fake.chatCallCount, 2);
      expect(fake.lastUserMessages, ['old question', 'hot button starter']);
    });

    test('clearChat bumps epoch even when idle', () {
      expect(notifier.chatEpoch, 0);
      notifier.clearChat();
      expect(notifier.chatEpoch, 1);
      expect(container.read(sidekickProvider).chatHistory, isEmpty);
    });
  });
}
