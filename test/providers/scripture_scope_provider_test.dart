import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:seminary_sidekick/models/enums.dart';
import 'package:seminary_sidekick/models/scripture_scope.dart';
import 'package:seminary_sidekick/providers/scripture_scope_provider.dart';

void main() {
  late ScriptureScopeNotifier notifier;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_scope_test_');
    Hive.init(tempDir.path);
    notifier = ScriptureScopeNotifier();
    await notifier.init();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('initial state', () {
    test('lastUsedScope returns null when nothing saved', () {
      expect(notifier.lastUsedScope(ScopeUsageContext.quickQuiz), isNull);
      expect(notifier.lastUsedScope(ScopeUsageContext.groupQuiz), isNull);
    });
  });

  group('save + load', () {
    test('saveScope persists per context', () async {
      const scope = ScopeBooks({ScriptureBook.bookOfMormon});
      await notifier.saveScope(ScopeUsageContext.quickQuiz, scope);
      final loaded = notifier.lastUsedScope(ScopeUsageContext.quickQuiz);
      expect(loaded, isA<ScopeBooks>());
      expect((loaded as ScopeBooks).books,
          equals({ScriptureBook.bookOfMormon}));
    });

    test('scopes do not bleed between contexts', () async {
      const quizScope = ScopeBooks({ScriptureBook.oldTestament});
      const matchScope = ScopeAll();
      await notifier.saveScope(ScopeUsageContext.quickQuiz, quizScope);
      await notifier.saveScope(ScopeUsageContext.scriptureMatch, matchScope);

      expect(
        notifier.lastUsedScope(ScopeUsageContext.quickQuiz),
        isA<ScopeBooks>(),
      );
      expect(
        notifier.lastUsedScope(ScopeUsageContext.scriptureMatch),
        isA<ScopeAll>(),
      );
      expect(
        notifier.lastUsedScope(ScopeUsageContext.groupQuiz),
        isNull,
      );
    });

    test('saveScope overwrites the prior value under the same context',
        () async {
      await notifier.saveScope(
        ScopeUsageContext.quickQuiz,
        const ScopeBooks({ScriptureBook.bookOfMormon}),
      );
      await notifier.saveScope(
        ScopeUsageContext.quickQuiz,
        const ScopeScriptureIds(['1', '2', '3']),
      );
      final loaded = notifier.lastUsedScope(ScopeUsageContext.quickQuiz);
      expect(loaded, isA<ScopeScriptureIds>());
      expect((loaded as ScopeScriptureIds).ids, ['1', '2', '3']);
    });

    test('clearScope removes the entry', () async {
      await notifier.saveScope(
        ScopeUsageContext.quickQuiz,
        const ScopeNeedsReview(),
      );
      expect(notifier.lastUsedScope(ScopeUsageContext.quickQuiz), isNotNull);
      await notifier.clearScope(ScopeUsageContext.quickQuiz);
      expect(notifier.lastUsedScope(ScopeUsageContext.quickQuiz), isNull);
    });
  });

  group('persistence across notifier restarts', () {
    test('a new notifier with the same Hive dir restores saved scopes',
        () async {
      await notifier.saveScope(
        ScopeUsageContext.groupQuiz,
        const ScopeBooks({ScriptureBook.doctrineAndCovenants}),
      );
      // Close any open boxes so the second notifier can reopen them cleanly.
      await Hive.close();
      Hive.init(tempDir.path);

      final reloaded = ScriptureScopeNotifier();
      await reloaded.init();

      final loaded = reloaded.lastUsedScope(ScopeUsageContext.groupQuiz);
      expect(loaded, isA<ScopeBooks>());
      expect(
        (loaded as ScopeBooks).books,
        equals({ScriptureBook.doctrineAndCovenants}),
      );
    });
  });
}
