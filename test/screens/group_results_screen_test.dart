import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:seminary_sidekick/models/group_answer.dart';
import 'package:seminary_sidekick/models/group_play_state.dart';
import 'package:seminary_sidekick/models/group_player.dart';
import 'package:seminary_sidekick/models/group_question.dart';
import 'package:seminary_sidekick/models/group_room.dart';
import 'package:seminary_sidekick/models/group_sb_config.dart';
import 'package:seminary_sidekick/models/group_sb_finish.dart';
import 'package:seminary_sidekick/providers/group_play_provider.dart';
import 'package:seminary_sidekick/providers/subscription_provider.dart';
import 'package:seminary_sidekick/screens/group_play/group_results_screen.dart';
import 'package:seminary_sidekick/screens/group_play/widgets/podium_view.dart';
import 'package:seminary_sidekick/services/group_play_service.dart';
import 'package:seminary_sidekick/services/haptic_service.dart';
import 'package:seminary_sidekick/widgets/compressed_score_story.dart';
import 'package:seminary_sidekick/widgets/score_meter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeService extends GroupPlayService {
  _FakeService._(this._supabase) : super(client: _supabase);

  final SupabaseClient _supabase;

  factory _FakeService() {
    final client = SupabaseClient(
      'http://localhost:54321',
      'fake-anon-key',
    );
    // Prevent GoTrue's periodic auto-refresh timer from failing widget tests.
    client.auth.stopAutoRefresh();
    return _FakeService._(client);
  }

  void dispose() {
    _supabase.auth.stopAutoRefresh();
  }

  @override
  String? get currentUserId => 'me-uid';

  @override
  Stream<GroupRoom?> watchRoom(String roomId, {bool asHost = false}) =>
      const Stream.empty();
  @override
  Stream<List<GroupPlayer>> watchPlayers(String roomId) =>
      const Stream.empty();
  @override
  Stream<List<GroupAnswer>> watchAnswers(String roomId) =>
      const Stream.empty();
  @override
  Stream<List<GroupSbFinish>> watchSbFinishes(String roomId) =>
      const Stream.empty();
  @override
  Stream<({String event, Map<String, dynamic> payload})> listenForEvents(
    String roomCode,
  ) =>
      const Stream.empty();
}

class _SeededNotifier extends GroupPlayNotifier {
  _SeededNotifier(GroupPlayService service, GroupPlayState seed)
      : super(service, () => true) {
    state = seed;
  }
}

void main() {
  final now = DateTime.utc(2026, 7, 15);

  GroupPlayer player({
    required String id,
    required String userId,
    required String nick,
    int score = 0,
    bool isHost = false,
  }) {
    return GroupPlayer(
      id: id,
      roomId: 'room-1',
      userId: userId,
      nickname: nick,
      score: score,
      isHost: isHost,
      joinedAt: now,
      lastSeenAt: now,
    );
  }

  GroupQuestion question(int index) {
    return GroupQuestion(
      index: index,
      scriptureId: 's-$index',
      scriptureReference: 'Ref $index',
      typeName: 'referenceToText',
      prompt: 'Prompt $index',
      options: const ['A', 'B', 'C', 'D'],
      correctIndex: 0,
    );
  }

  GroupAnswer answer({
    required String id,
    required String playerId,
    required int index,
    required bool correct,
    int points = 800,
  }) {
    return GroupAnswer(
      id: id,
      roomId: 'room-1',
      playerId: playerId,
      questionIndex: index,
      selectedChoice: correct ? 0 : 1,
      isCorrect: correct,
      responseTimeMs: 1200,
      pointsEarned: correct ? points : 0,
      submittedAt: now,
    );
  }

  GroupPlayState quizState() {
    final me = player(
      id: 'p-me',
      userId: 'me-uid',
      nick: 'Pat',
      score: 1600,
    );
    final other = player(
      id: 'p-other',
      userId: 'other-uid',
      nick: 'Sam',
      score: 900,
    );
    final questions = [question(0), question(1)];
    return GroupPlayState(
      phase: GroupPlayPhase.viewingResults,
      room: GroupRoom(
        id: 'room-1',
        code: 'ABCD',
        hostId: 'me-uid',
        status: GroupRoomStatus.ended,
        scope: const GroupRoomScope(
          difficultyName: 'beginner',
          questionCount: 2,
        ),
        createdAt: now,
        endedAt: now,
      ),
      players: [me, other],
      me: me,
      questions: questions,
      answers: [
        answer(id: 'a1', playerId: 'p-me', index: 0, correct: true),
        answer(id: 'a2', playerId: 'p-me', index: 1, correct: true),
        answer(
          id: 'a3',
          playerId: 'p-other',
          index: 0,
          correct: true,
          points: 900,
        ),
        answer(
          id: 'a4',
          playerId: 'p-other',
          index: 1,
          correct: false,
          points: 0,
        ),
      ],
    );
  }

  GroupPlayState sbState() {
    final host = player(
      id: 'p-host',
      userId: 'me-uid',
      nick: 'Host',
      isHost: true,
    );
    final racer = player(
      id: 'p-racer',
      userId: 'racer-uid',
      nick: 'Racer',
      score: 1,
    );
    const sbConfig = GroupSbConfig(
      playMode: GroupSbPlayMode.roundByRound,
      chunkDifficulty: GroupSbChunkDifficulty.beginner,
      scriptureIds: ['s-1'],
    );
    return GroupPlayState(
      phase: GroupPlayPhase.viewingResults,
      room: GroupRoom(
        id: 'room-1',
        code: 'SB01',
        hostId: 'me-uid',
        status: GroupRoomStatus.ended,
        scope: const GroupRoomScope(
          mode: GroupGameMode.scriptureBuilder,
          difficultyName: 'beginner',
          questionCount: 1,
          scriptureBuilderConfig: sbConfig,
        ),
        createdAt: now,
        endedAt: now,
      ),
      players: [host, racer],
      me: host,
      sbConfig: sbConfig,
      sbFinishes: [
        GroupSbFinish(
          id: 'f1',
          roomId: 'room-1',
          playerId: 'p-racer',
          scriptureIndex: 0,
          elapsedMs: 5000,
          mistakeCount: 0,
          completedAt: now,
        ),
      ],
    );
  }

  Widget harness(GroupPlayState seed) {
    final fake = _FakeService();
    addTearDown(fake.dispose);
    return ProviderScope(
      overrides: [
        hapticProvider.overrideWithValue(const HapticService.disabled()),
        groupPlayServiceProvider.overrideWithValue(fake),
        isPremiumProvider.overrideWith((ref) => true),
        groupPlayProvider.overrideWith(
          (ref) => _SeededNotifier(fake, seed),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/group-play/results/ABCD',
          routes: [
            GoRoute(
              path: '/group-play/results/:code',
              builder: (_, state) => GroupResultsScreen(
                code: state.pathParameters['code']!,
              ),
            ),
            GoRoute(
              path: '/group-play/host',
              builder: (_, __) => const Scaffold(body: Text('Host Lobby')),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('quiz mode shows personal ScoreMeter moment before podium',
      (tester) async {
    await tester.pumpWidget(harness(quizState()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(CompressedScoreStory), findsOneWidget);
    expect(find.byType(PodiumView), findsNothing);
    expect(find.text('Your round'), findsOneWidget);

    await tester.tap(find.byKey(const Key('group-score-story-skip')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(PodiumView), findsOneWidget);
    // Personal meter remains (compact) above the podium after the moment.
    expect(find.byType(ScoreMeter), findsOneWidget);
    // ListView may not have built below-the-fold children yet.
    expect(
      find.text('FULL LEADERBOARD', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets(
      'quiz with local player but no questions skips meter and shows podium',
      (tester) async {
    final now = DateTime.utc(2026, 7, 15);
    final me = player(
      id: 'p-me',
      userId: 'me-uid',
      nick: 'Pat',
      score: 0,
    );
    // questionCount 0 + empty questions ⇒ _quizStory null (confetti regression).
    final seed = GroupPlayState(
      phase: GroupPlayPhase.viewingResults,
      room: GroupRoom(
        id: 'room-1',
        code: 'ABCD',
        hostId: 'me-uid',
        status: GroupRoomStatus.ended,
        scope: const GroupRoomScope(
          difficultyName: 'beginner',
          questionCount: 0,
        ),
        createdAt: now,
        endedAt: now,
      ),
      players: [me],
      me: me,
      questions: const [],
      answers: const [],
    );

    await tester.pumpWidget(harness(seed));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(CompressedScoreStory), findsNothing);
    expect(find.byType(PodiumView), findsOneWidget);

    // Flush gold-reveal confetti delay so the test ends cleanly.
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('SB race results show podium immediately without meter moment',
      (tester) async {
    await tester.pumpWidget(harness(sbState()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(CompressedScoreStory), findsNothing);
    expect(find.byKey(const Key('group-score-story-skip')), findsNothing);
    expect(find.byType(PodiumView), findsOneWidget);
    expect(
      find.text('FULL LEADERBOARD', skipOffstage: false),
      findsOneWidget,
    );

    // Flush podium/confetti timers so the test ends cleanly.
    await tester.pump(const Duration(seconds: 4));
  });
}
