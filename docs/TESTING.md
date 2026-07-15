## Testing

### Setup

Dev dependencies: `mockito ^5.4.4`, `fake_async ^1.3.1` (already added).

```
test/
├── models/
│   ├── scripture_test.dart
│   ├── user_progress_test.dart
│   ├── enums_test.dart
│   └── scripture_mastery_test.dart  # Holistic mastery: linear path, decay, Eternal, requirements
├── providers/
│   ├── scripture_provider_test.dart
│   ├── progress_provider_test.dart  # Includes consecutivePerfectMaster tracking tests
│   ├── matching_game_provider_test.dart
│   └── scripture_builder_provider_test.dart
├── screens/
│   └── (widget tests — lower priority)
└── helpers/
    └── test_helpers.dart       # 5 shared test scriptures
```

### Test Priorities

1. **Models** (fast, no deps): word splitting, verse stripping, difficulty tiers, copyWith, equality, enum values
2. **Scripture mastery model** (core mastery logic): linear path levels, Scripture Builder-driven computation, gentle decay, Eternal tier, sub-progress, requirements generation
3. **Progress provider** (core business logic): recordAttempt, accuracy, streaks, mastery thresholds, game type isolation, consecutivePerfectMaster tracking
4. **Scripture provider** (read-only queries): all 100 scriptures, by book, by ID, search
5. **Matching game provider**: game init, selection, matching, completion, internal `starRating` getter (results UI uses score meter grades)
6. **Word builder provider** (most complex): chunk-tap mode + typing mode across all 4 difficulty tiers
7. **Widget tests** (lowest priority): MemorizeScreen, GamesHubScreen, GameResultsScreen

### Testing StateNotifiers Directly

```dart
late ProgressNotifier notifier;
setUp(() { notifier = ProgressNotifier(); });

test('first correct attempt creates progress', () {
  notifier.recordAttempt(scriptureId: 'test-1', gameType: GameType.matching, correct: true);
  final progress = notifier.getProgress('test-1', GameType.matching);
  expect(progress!.totalAttempts, 1);
  expect(progress.accuracy, 100.0);
});
```

### Testing Providers with ProviderContainer

```dart
late ProviderContainer container;
setUp(() { container = ProviderContainer(); });
tearDown(() { container.dispose(); });

test('scripturesProvider returns all 100', () {
  expect(container.read(scripturesProvider).length, 100);
});
```

### Test Conventions

- One test file per source file
- Group related tests with `group()`
- Test names describe behavior: `'recordAttempt with correct answer increments streak'`
- Fresh notifier in `setUp`, no shared state
- Use fixtures from `test_helpers.dart`
- Assert state, not implementation

### Running Tests

```bash
flutter test                    # All tests
flutter test test/providers/    # Specific directory
flutter test --coverage         # With coverage
flutter analyze                 # Must pass with no errors
```
