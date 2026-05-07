import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/data/scriptures_data.dart';
import 'package:seminary_sidekick/models/enums.dart';
import 'package:seminary_sidekick/services/quiz_question_factory.dart';

void main() {
  // Determinism: pin the Random so option order and selection are reproducible.
  // We're testing structural properties (book of distractors, count of options)
  // not specific orderings, but a seeded RNG keeps test failures explainable.
  QuizQuestionFactory factory() => QuizQuestionFactory(random: Random(42));

  group('QuizQuestionFactory.buildQuestions', () {
    test('returns the requested count when pool is large enough', () {
      final qs = factory().buildQuestions(count: 10);
      expect(qs.length, 10);
    });

    test('caps count at the actual pool size', () {
      // Pool size for the master tier on every scripture is 100 — capped fine.
      final qs = factory().buildQuestions(count: 99999);
      expect(qs.length, allScriptures.length);
    });

    test('every question has 4 options including the correct answer', () {
      for (final q in factory().buildQuestions(count: 20)) {
        expect(q.options.length, 4);
        expect(q.options, contains(q.correctAnswer));
        expect(q.correctIndex, q.options.indexOf(q.correctAnswer));
      }
    });

    test('no question repeats the correct answer in its own distractors', () {
      for (final q in factory().buildQuestions(count: 30)) {
        // Options is a Set if we dedupe; correct should appear exactly once.
        final occurrences =
            q.options.where((o) => o == q.correctAnswer).length;
        expect(occurrences, 1, reason: 'Answer "${q.correctAnswer}" appeared ${occurrences}x');
      }
    });
  });

  group('Distractor scope (the scope-leak fix)', () {
    test(
        'when bookFilters is set, distractors stay within those books — '
        'a student who knows the books cannot eliminate by book alone',
        () {
      // Book of Mormon only.
      final scope = [ScriptureBook.bookOfMormon];
      final bomReferences = allScriptures
          .where((s) => s.book == ScriptureBook.bookOfMormon)
          .map((s) => s.reference)
          .toSet();
      final bomKeyPhrases = allScriptures
          .where((s) => s.book == ScriptureBook.bookOfMormon)
          .map((s) => s.keyPhrase)
          .toSet();

      final qs = factory().buildQuestions(
        count: 20,
        bookFilters: scope,
      );

      for (final q in qs) {
        expect(
          q.scripture.book,
          ScriptureBook.bookOfMormon,
          reason: 'Question scripture leaked outside scope',
        );
        // Every option (correct + distractors) must be a reference or key
        // phrase from a Book of Mormon scripture. Which pool we check
        // depends on the question type.
        final allowed = switch (q.type) {
          QuizQuestionTypeKind.phraseToReference => bomReferences,
          QuizQuestionTypeKind.referenceToPhrase => bomKeyPhrases,
          QuizQuestionTypeKind.passageToReference => bomReferences,
        };
        for (final opt in q.options) {
          expect(
            allowed,
            contains(opt),
            reason:
                'Option "$opt" leaked outside Book of Mormon scope (type ${q.type.name})',
          );
        }
      }
    });

    test('multi-book filter keeps distractors in-scope across selected books',
        () {
      final scope = [
        ScriptureBook.bookOfMormon,
        ScriptureBook.doctrineAndCovenants,
      ];
      final allowedBooks = scope.toSet();

      final qs = factory().buildQuestions(
        count: 15,
        bookFilters: scope,
      );

      // Walk every option, look up the source scripture, confirm in-scope.
      for (final q in qs) {
        for (final opt in q.options) {
          // Find source scriptures whose reference OR key phrase matches.
          final sourceCandidates = allScriptures.where(
            (s) => s.reference == opt || s.keyPhrase == opt,
          );
          // At least one source should be in-scope. (A given string might
          // match scriptures in multiple books only if there are duplicates,
          // which there aren't in the curriculum.)
          expect(
            sourceCandidates.any((s) => allowedBooks.contains(s.book)),
            isTrue,
            reason: 'Option "$opt" has no source in selected books',
          );
        }
      }
    });

    test(
        'unfiltered "All 100" preserves the original "no overlap with selected" '
        'distractor rule', () {
      final qs = factory().buildQuestions(count: 5);
      final selectedRefs = qs.map((q) => q.scripture.reference).toSet();

      // For every phraseToReference question, the distractors (i.e. options
      // minus correct) must NOT be the reference of another selected
      // scripture. This locks in the original solo-quiz behavior.
      for (final q in qs) {
        if (q.type != QuizQuestionTypeKind.phraseToReference &&
            q.type != QuizQuestionTypeKind.passageToReference) {
          continue;
        }
        final distractors = q.options.where((o) => o != q.correctAnswer);
        for (final d in distractors) {
          expect(
            selectedRefs.contains(d) && d != q.correctAnswer,
            isFalse,
            reason:
                'Unfiltered quiz leaked a selected reference "$d" into distractors',
          );
        }
      }
    });
  });

  group('Explicit scripture list', () {
    test('when scriptures are passed explicitly, count matches', () {
      final picks = allScriptures.take(7).toList();
      final qs = factory().buildQuestions(count: 999, scriptures: picks);
      expect(qs.length, 7);
    });

    test('explicit list goes through the broader-catalog distractor path', () {
      // When you pass a tiny explicit list, you DON'T want distractors confined
      // to those 3 scriptures (you'd run out and the quiz feels canned).
      // Distractors should pull from the full catalog minus the selected set.
      final picks = allScriptures.take(3).toList();
      final pickedRefs = picks.map((s) => s.reference).toSet();

      final qs = factory().buildQuestions(count: 999, scriptures: picks);

      // At least one phrase→reference question's distractors should include
      // a reference that isn't in the picked set. (Probabilistic but with 100
      // scriptures and seed Random(42) this is essentially guaranteed.)
      var sawOutside = false;
      for (final q in qs) {
        if (q.type != QuizQuestionTypeKind.phraseToReference &&
            q.type != QuizQuestionTypeKind.passageToReference) {
          continue;
        }
        for (final opt in q.options) {
          if (opt == q.correctAnswer) continue;
          if (!pickedRefs.contains(opt)) sawOutside = true;
        }
      }
      expect(sawOutside, isTrue,
          reason:
              'Explicit-list quizzes should pull distractors from the full catalog');
    });
  });
}
