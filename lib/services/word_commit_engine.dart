/// Word-commit validation for Scripture Builder's Master typing mode.
///
/// Judgment happens at word boundaries, not per keystroke: the user types a
/// word (with the OS keyboard's autocorrect free to fix typos), and the word
/// is only checked when they commit it with the spacebar. This is the single
/// source of truth for that rule — pure Dart, no Flutter/Riverpod imports —
/// so a future Group Play typing tier can reuse identical matching behavior.
///
/// Matching is deliberately forgiving about everything except the words
/// themselves: case-insensitive, and all punctuation is stripped before
/// comparison ("Lord's" matches "lords", "world," matches "world"). Target
/// punctuation and spaces are auto-filled into the committed text, so the
/// user only ever supplies letters and digits — same contract as the
/// per-character Advanced mode.
class WordCommitEngine {
  WordCommitEngine._();

  /// Punctuation that is auto-filled (never typed by the user).
  /// Single source of truth for the auto-fill set —
  /// `TypedDisplayRules.punctuation` references this directly, so display
  /// and judgment can never drift apart.
  static final punctuation =
      RegExp(r'''[,;:!?\-\—\–\.\'\"\'\'\"\"\(\)\[\]]''');

  static bool _isWhitespace(String ch) => ch == ' ' || ch == '\n';

  /// True if this character is auto-filled in typing mode (spaces, newlines,
  /// and all punctuation).
  static bool isAutoFill(String ch) =>
      _isWhitespace(ch) || punctuation.hasMatch(ch);

  /// Dashes join words without spaces in scripture text ("faith—faith").
  /// They end a token the same way whitespace does, so each joined word can
  /// be typed — and judged — separately.
  static bool _isTokenBoundary(String ch) =>
      _isWhitespace(ch) || ch == '-' || ch == '—' || ch == '–';

  static final _nonAlphanumeric = RegExp(r'[^a-z0-9]');

  /// Lowercase and strip everything that is not a letter or digit, leaving
  /// only the characters the user is actually responsible for typing.
  static String normalize(String s) =>
      s.toLowerCase().replaceAll(_nonAlphanumeric, '');

  /// The most tokens one commit may span. Covers autocorrect splitting a
  /// typo into two words ("ofthe" → "of the ") and dash-joined chains typed
  /// as one word, while keeping paste-per-commit granularity small.
  static const maxTokensPerCommit = 4;

  /// Attempt to commit [buffer] against [target] at [position] (the number
  /// of characters already committed, i.e. `typedChars.length`).
  ///
  /// The buffer is accepted if its normalized form equals the normalized
  /// span of the next 1..[maxTokensPerCommit] tokens (dash- or
  /// whitespace-delimited), shortest span first. So "stiff-necked" typed as
  /// one word or as "stiff" + "necked" both work, and an autocorrect rewrite
  /// that splits a typo into two words still commits. On a match,
  /// [WordCommitResult.committedText] contains the exact target characters
  /// to append — leading auto-fill, the matched span in the target's own
  /// casing/punctuation, and any trailing auto-fill — keeping the display
  /// canonical.
  static WordCommitResult tryCommit({
    required String target,
    required int position,
    required String buffer,
  }) {
    final typed = normalize(buffer);
    if (typed.isEmpty || position >= target.length) {
      return const WordCommitResult._(WordCommitStatus.nothingToCommit, '');
    }

    // Skip leading auto-fill (opening quotes, spaces after a prior commit).
    var start = position;
    while (start < target.length && isAutoFill(target[start])) {
      start++;
    }
    if (start >= target.length) {
      return const WordCommitResult._(WordCommitStatus.nothingToCommit, '');
    }

    // Grow the candidate span one token at a time, comparing after each.
    var spanEnd = start;
    for (var k = 0; k < maxTokensPerCommit; k++) {
      // Skip auto-fill separating this token from the previous one.
      while (spanEnd < target.length && isAutoFill(target[spanEnd])) {
        spanEnd++;
      }
      if (spanEnd >= target.length) break;
      // Consume one token.
      while (spanEnd < target.length && !_isTokenBoundary(target[spanEnd])) {
        spanEnd++;
      }

      final span = normalize(target.substring(start, spanEnd));
      if (typed == span) {
        // Absorb trailing auto-fill (punctuation, dashes, spaces) so the
        // next expected position always lands on a typeable character.
        var end = spanEnd;
        while (end < target.length && isAutoFill(target[end])) {
          end++;
        }
        return WordCommitResult._(
          WordCommitStatus.committed,
          target.substring(position, end),
        );
      }
      // Spans only grow — once the span outruns the buffer, no match exists.
      if (span.length > typed.length) break;
    }
    return const WordCommitResult._(WordCommitStatus.wrongWord, '');
  }
}

/// Outcome of a [WordCommitEngine.tryCommit] attempt.
enum WordCommitStatus {
  /// The buffer matched — commit [WordCommitResult.committedText].
  committed,

  /// The buffer had typeable content that does not match the next word.
  wrongWord,

  /// Nothing to judge: the buffer held no letters/digits, or the target
  /// is already fully committed.
  nothingToCommit,
}

class WordCommitResult {
  final WordCommitStatus status;

  /// Target characters to append on a successful commit (empty otherwise).
  final String committedText;

  const WordCommitResult._(this.status, this.committedText);
}
