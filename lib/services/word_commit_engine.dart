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
  /// Must stay in sync with `TypedDisplayRules.punctuation` in
  /// `lib/screens/games/scripture_builder/typed_display_rules.dart`.
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

  /// Lowercase and strip everything that is not a letter or digit, leaving
  /// only the characters the user is actually responsible for typing.
  static String normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  /// Attempt to commit [buffer] against [target] at [position] (the number
  /// of characters already committed, i.e. `typedChars.length`).
  ///
  /// The buffer is accepted if its normalized form equals the normalized
  /// next token (up to the next whitespace or dash) or the normalized next
  /// whitespace-delimited word (so "stiff-necked" typed as one word or as
  /// "stiff" + "necked" both work). On a match, [WordCommitResult.committedText]
  /// contains the exact target characters to append — leading auto-fill,
  /// the matched span in the target's own casing/punctuation, and any
  /// trailing auto-fill — keeping the display canonical.
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

    // Token span: up to the next whitespace or dash.
    var tokenEnd = start;
    while (tokenEnd < target.length && !_isTokenBoundary(target[tokenEnd])) {
      tokenEnd++;
    }
    // Word span: up to the next whitespace only (spans dashes).
    var wordEnd = start;
    while (wordEnd < target.length && !_isWhitespace(target[wordEnd])) {
      wordEnd++;
    }

    var matchEnd = -1;
    if (typed == normalize(target.substring(start, tokenEnd))) {
      matchEnd = tokenEnd;
    } else if (wordEnd != tokenEnd &&
        typed == normalize(target.substring(start, wordEnd))) {
      matchEnd = wordEnd;
    }
    if (matchEnd < 0) {
      return const WordCommitResult._(WordCommitStatus.wrongWord, '');
    }

    // Absorb trailing auto-fill (punctuation, dashes, spaces) so the next
    // expected position always lands on a typeable character.
    var end = matchEnd;
    while (end < target.length && isAutoFill(target[end])) {
      end++;
    }
    return WordCommitResult._(
      WordCommitStatus.committed,
      target.substring(position, end),
    );
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
