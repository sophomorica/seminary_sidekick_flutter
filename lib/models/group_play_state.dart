import 'group_answer.dart';
import 'group_player.dart';
import 'group_question.dart';
import 'group_room.dart';
import 'group_wb_config.dart';
import 'group_wb_finish.dart';

/// High-level phase of the group play flow. Used by the UI to decide what
/// screen to show and what controls to expose.
enum GroupPlayPhase {
  /// Nothing in flight. Default state.
  idle,

  /// Host is composing a room (setup view).
  hosting,

  /// Player is on the join screen entering a code.
  joining,

  /// Connected to a room, lobby view (waiting for host to start).
  inLobby,

  /// Game has started; current question on screen.
  inQuiz,

  /// Game ended; results view.
  viewingResults,

  /// Something blew up (network, RLS, room not found, etc).
  error,
}

/// Aggregate state owned by `GroupPlayNotifier`.
///
/// All fields are nullable / optional so the notifier can transition between
/// phases without needing to set every field.
class GroupPlayState {
  final GroupPlayPhase phase;

  /// The room we're currently in (host or player). Null when idle.
  final GroupRoom? room;

  /// All players currently in the room, ordered by score descending.
  final List<GroupPlayer> players;

  /// The current player's row in the room (you). Null if not joined yet.
  final GroupPlayer? me;

  /// Frozen question set for the active room.
  final List<GroupQuestion> questions;

  /// Answers submitted in this session (newest first). Used by the live
  /// leaderboard and the post-game breakdown.
  final List<GroupAnswer> answers;

  /// Whether the current question (during inQuiz) has been answered locally.
  final bool currentQuestionAnswered;

  /// The choice the local player just selected, if any.
  final int? mySelectedChoice;

  /// Word Builder race finishes (one row per player per scripture).
  /// Empty for quiz-mode rooms.
  final List<GroupWbFinish> wbFinishes;

  /// Resolved Word Builder config for the current room, or null for quiz
  /// rooms. Pulled out of `room.scope.wordBuilderConfig` once on entry so
  /// consumers don't have to keep unwrapping the optional.
  final GroupWbConfig? wbConfig;

  /// Last error message, surfaced to the UI.
  final String? error;

  /// True while a network call is in flight that the UI should show feedback for.
  final bool isLoading;

  const GroupPlayState({
    this.phase = GroupPlayPhase.idle,
    this.room,
    this.players = const [],
    this.me,
    this.questions = const [],
    this.answers = const [],
    this.currentQuestionAnswered = false,
    this.mySelectedChoice,
    this.wbFinishes = const [],
    this.wbConfig,
    this.error,
    this.isLoading = false,
  });

  bool get isHost => me?.isHost ?? false;
  bool get isInRoom =>
      phase == GroupPlayPhase.inLobby ||
      phase == GroupPlayPhase.inQuiz ||
      phase == GroupPlayPhase.viewingResults;

  /// The question currently on screen (during inQuiz). Null otherwise.
  GroupQuestion? get currentQuestion {
    final idx = room?.currentQuestionIndex ?? -1;
    if (idx < 0 || idx >= questions.length) return null;
    return questions[idx];
  }

  /// Players sorted by score descending. Convenience for leaderboard widgets.
  List<GroupPlayer> get leaderboard {
    final sorted = [...players]..sort((a, b) => b.score.compareTo(a.score));
    return sorted;
  }

  GroupPlayState copyWith({
    GroupPlayPhase? phase,
    GroupRoom? room,
    List<GroupPlayer>? players,
    GroupPlayer? me,
    List<GroupQuestion>? questions,
    List<GroupAnswer>? answers,
    bool? currentQuestionAnswered,
    int? mySelectedChoice,
    List<GroupWbFinish>? wbFinishes,
    GroupWbConfig? wbConfig,
    String? error,
    bool? isLoading,
    bool clearError = false,
    bool clearMySelection = false,
    bool clearRoom = false,
    bool clearWbConfig = false,
  }) {
    return GroupPlayState(
      phase: phase ?? this.phase,
      room: clearRoom ? null : (room ?? this.room),
      players: players ?? this.players,
      me: me ?? this.me,
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      currentQuestionAnswered:
          currentQuestionAnswered ?? this.currentQuestionAnswered,
      mySelectedChoice:
          clearMySelection ? null : (mySelectedChoice ?? this.mySelectedChoice),
      wbFinishes: wbFinishes ?? this.wbFinishes,
      wbConfig: clearWbConfig ? null : (wbConfig ?? this.wbConfig),
      error: clearError ? null : (error ?? this.error),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
