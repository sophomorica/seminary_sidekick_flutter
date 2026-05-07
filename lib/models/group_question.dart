/// A single question in a group play session.
///
/// This is a backend-friendly mirror of `QuizQuestion` from
/// `lib/providers/quiz_game_provider.dart` — the existing solo Quick Quiz
/// model — but serializable so the entire question set can live in
/// `rooms.question_set` (JSONB) and travel to clients via Realtime.
///
/// The frozen question set is generated once at room start by
/// [QuizQuestionFactory] (see `lib/services/quiz_question_factory.dart`)
/// so all clients see exactly the same questions in the same order.
class GroupQuestion {
  /// Index in the room's question_set (0-based).
  final int index;

  /// Scripture id this question is about (for analytics / deep links).
  final String scriptureId;

  /// Human-readable scripture reference (for the post-game breakdown).
  final String scriptureReference;

  /// Question type — matches `QuizQuestionType` in the solo provider.
  /// Stored as a name so JSON survives any enum reordering.
  final String typeName;

  /// The text shown to players as the question (the prompt).
  final String prompt;

  /// Four options, in display order.
  final List<String> options;

  /// Index of the correct option in [options].
  final int correctIndex;

  const GroupQuestion({
    required this.index,
    required this.scriptureId,
    required this.scriptureReference,
    required this.typeName,
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });

  /// The textual correct answer (convenience).
  String get correctAnswer => options[correctIndex];

  Map<String, dynamic> toJson() => {
        'index': index,
        'scriptureId': scriptureId,
        'scriptureReference': scriptureReference,
        'typeName': typeName,
        'prompt': prompt,
        'options': options,
        'correctIndex': correctIndex,
      };

  factory GroupQuestion.fromJson(Map<String, dynamic> json) {
    return GroupQuestion(
      index: json['index'] as int,
      scriptureId: json['scriptureId'] as String,
      scriptureReference: json['scriptureReference'] as String,
      typeName: json['typeName'] as String,
      prompt: json['prompt'] as String,
      options:
          (json['options'] as List<dynamic>).map((e) => e as String).toList(),
      correctIndex: json['correctIndex'] as int,
    );
  }
}
