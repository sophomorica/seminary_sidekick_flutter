import 'dart:math';

import '../data/scriptures_data.dart';
import '../models/enums.dart';
import '../models/scripture.dart';

/// Question type — kept identical to the legacy `QuizQuestionType` in
/// `quiz_game_provider.dart`. Both files import this enum.
///
/// Stored as `name` in JSON so any reordering survives.
enum QuizQuestionTypeKind {
  /// Show a key phrase, pick the correct reference.
  phraseToReference,

  /// Show a reference, pick the correct key phrase.
  referenceToPhrase,

  /// Show a passage excerpt, pick the correct reference.
  passageToReference,
}

/// A "raw" generated question — not tied to either the solo provider or the
/// group play models. Both consumers wrap or convert this as needed.
class GeneratedQuestion {
  final Scripture scripture;
  final QuizQuestionTypeKind type;
  final String prompt;
  final List<String> options;
  final String correctAnswer;

  const GeneratedQuestion({
    required this.scripture,
    required this.type,
    required this.prompt,
    required this.options,
    required this.correctAnswer,
  });

  int get correctIndex => options.indexOf(correctAnswer);
}

/// Pure helper for generating quiz question sets.
///
/// **Used by both solo Quick Quiz and Group Play.** Behavior is unchanged
/// from what `QuizGameNotifier` did before extraction — the legacy provider
/// now delegates here so we don't fork question logic across two code paths.
///
/// All randomness is sourced from a `Random` instance you pass in (so tests
/// can seed it). The factory holds no state.
class QuizQuestionFactory {
  final Random _random;

  /// Pass a seeded `Random` for deterministic tests.
  QuizQuestionFactory({Random? random}) : _random = random ?? Random();

  /// Generate [count] questions from the given scripture pool.
  ///
  /// Behavior:
  ///   1. If [scriptures] is provided and non-empty, use it directly.
  ///   2. Else, draw proportionally from each book in [bookFilters]
  ///      (or all books if empty).
  ///   3. Cap at the actual pool size — never invent questions.
  ///   4. Distractors come from scriptures NOT in the selected set.
  ///   5. Question types rotate through the three kinds in order, then
  ///      the final list is shuffled so books interleave.
  List<GeneratedQuestion> buildQuestions({
    required int count,
    List<ScriptureBook> bookFilters = const [],
    List<Scripture>? scriptures,
  }) {
    final selected = _selectScriptures(
      count: count,
      bookFilters: bookFilters,
      explicit: scriptures,
    );

    // Distractor pool: scriptures whose references / key phrases are eligible
    // as wrong-answer options.
    //
    // Three cases:
    //   1. **Book-filtered quiz** → keep distractors IN-SCOPE so a student
    //      who knows the books can't eliminate three answers immediately by
    //      "those aren't from this book." We deliberately do NOT exclude the
    //      selected set here: for a small scope (e.g. all of D&C with a Master
    //      40-question quiz on a 25-scripture book) the selected set equals
    //      the scope, and excluding it would leave zero distractors. Allowing
    //      a question's correct answer to also appear as a wrong-answer option
    //      in another question is fine — that's recall pressure, not a bug.
    //   2. **Explicit scripture list** (e.g. saved-roster-style targeted drill)
    //      → keep the original "exclude selected from pool" behavior. The
    //      narrow list is intentional and we want plausible-looking distractors
    //      from outside it.
    //   3. **No filter, no explicit list** ("All 100") → original behavior.
    final List<Scripture> distractorPool;
    if (bookFilters.isNotEmpty) {
      distractorPool =
          allScriptures.where((s) => bookFilters.contains(s.book)).toList();
    } else {
      distractorPool =
          allScriptures.where((s) => !selected.contains(s)).toList();
    }

    final questions = <GeneratedQuestion>[];
    const types = QuizQuestionTypeKind.values;
    for (int i = 0; i < selected.length; i++) {
      final scripture = selected[i];
      final type = types[i % types.length];
      questions.add(_buildQuestion(scripture, type, distractorPool));
    }

    questions.shuffle(_random);
    return questions;
  }

  // ─── Selection ────────────────────────────────────────────────────────────

  List<Scripture> _selectScriptures({
    required int count,
    required List<ScriptureBook> bookFilters,
    List<Scripture>? explicit,
  }) {
    if (explicit != null && explicit.isNotEmpty) {
      return List.from(explicit);
    }

    final effectiveBooks =
        bookFilters.isEmpty ? ScriptureBook.values.toList() : bookFilters;

    final byBook = <ScriptureBook, List<Scripture>>{};
    for (final book in effectiveBooks) {
      byBook[book] = allScriptures.where((s) => s.book == book).toList();
    }

    final totalAvailable =
        byBook.values.fold<int>(0, (sum, list) => sum + list.length);
    final cappedCount = min(count, totalAvailable);
    return _selectProportionally(byBook, cappedCount);
  }

  /// Distribute [count] picks across the books proportionally to each book's
  /// share of the total available pool. Last book gets the remainder so we
  /// don't drop scriptures to rounding.
  List<Scripture> _selectProportionally(
    Map<ScriptureBook, List<Scripture>> byBook,
    int count,
  ) {
    final totalAvailable =
        byBook.values.fold<int>(0, (sum, list) => sum + list.length);
    if (totalAvailable == 0) return [];

    final selected = <Scripture>[];
    var remaining = count;

    final books = byBook.keys.toList();
    for (int i = 0; i < books.length; i++) {
      final book = books[i];
      final pool = List<Scripture>.from(byBook[book]!);
      pool.shuffle(_random);

      int bookCount;
      if (i == books.length - 1) {
        bookCount = remaining;
      } else {
        bookCount = (count * pool.length / totalAvailable).round();
        bookCount = min(bookCount, pool.length);
      }
      bookCount = min(bookCount, pool.length);
      bookCount = min(bookCount, remaining);

      selected.addAll(pool.take(bookCount));
      remaining -= bookCount;
    }

    return selected;
  }

  // ─── Question construction ───────────────────────────────────────────────

  GeneratedQuestion _buildQuestion(
    Scripture scripture,
    QuizQuestionTypeKind type,
    List<Scripture> distractorPool,
  ) {
    String prompt;
    String correctAnswer;
    List<String> distractorAnswers;

    switch (type) {
      case QuizQuestionTypeKind.phraseToReference:
        prompt = scripture.keyPhrase;
        correctAnswer = scripture.reference;
        distractorAnswers = _pickDistractors(
          distractorPool,
          (s) => s.reference,
          exclude: correctAnswer,
        );
        break;
      case QuizQuestionTypeKind.referenceToPhrase:
        prompt = scripture.reference;
        correctAnswer = scripture.keyPhrase;
        distractorAnswers = _pickDistractors(
          distractorPool,
          (s) => s.keyPhrase,
          exclude: correctAnswer,
        );
        break;
      case QuizQuestionTypeKind.passageToReference:
        final words = scripture.words;
        final excerptWords = words.take(min(15, words.length)).toList();
        prompt = '${excerptWords.join(' ')}...';
        correctAnswer = scripture.reference;
        distractorAnswers = _pickDistractors(
          distractorPool,
          (s) => s.reference,
          exclude: correctAnswer,
        );
        break;
    }

    final options = [correctAnswer, ...distractorAnswers]..shuffle(_random);

    return GeneratedQuestion(
      scripture: scripture,
      type: type,
      prompt: prompt,
      options: options,
      correctAnswer: correctAnswer,
    );
  }

  List<String> _pickDistractors(
    List<Scripture> pool,
    String Function(Scripture) extractor, {
    required String exclude,
  }) {
    final candidates =
        pool.map(extractor).where((a) => a != exclude).toSet().toList();
    candidates.shuffle(_random);
    return candidates.take(3).toList();
  }
}
