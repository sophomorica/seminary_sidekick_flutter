/// Pure display rules for the Scripture Builder typing-mode passage view.
///
/// Extracted from the screen so the display contract is unit-testable
/// without pumping widgets: Advanced may reveal only first-letter-of-word
/// hints, Master reveals nothing, and no untyped position ever discloses
/// a hidden letter (MAINT-007).
class TypedDisplayRules {
  TypedDisplayRules._();

  /// Punctuation the provider auto-fills — the user never types it.
  /// Must stay in sync with `WordCommitEngine.punctuation` in
  /// `lib/services/word_commit_engine.dart`.
  static final punctuation =
      RegExp(r'''[,;:!?\-\—\–\.\'\"\'\'\"\"\(\)\[\]]''');

  static bool _isBoundary(String ch) => ch == ' ' || ch == '\n';

  /// Indices of the first actual letter/digit of each word — the only
  /// untyped characters Advanced difficulty is allowed to reveal.
  ///
  /// Newlines count as word boundaries, and auto-filled punctuation is
  /// never a hint: leading punctuation (an opening quote or paren) is
  /// skipped so the hint lands on the word's first real letter, while
  /// mid-word punctuation (hyphens, apostrophes) does not start a new word.
  static Set<int> firstLetterIndices(String target) {
    final indices = <int>{};
    var atWordStart = true;
    for (var i = 0; i < target.length; i++) {
      final ch = target[i];
      if (_isBoundary(ch)) {
        atWordStart = true;
      } else if (!punctuation.hasMatch(ch)) {
        if (atWordStart) indices.add(i);
        atWordStart = false;
      }
    }
    return indices;
  }

  /// Index of the next letter/digit the user must type, skipping spaces
  /// and auto-filled punctuation. Returns -1 when only auto-fill
  /// characters remain, so no cursor chrome lands on a slot the user
  /// never types.
  static int nextLetterIndex(String target, int from) {
    var i = from;
    while (i < target.length) {
      final ch = target[i];
      if (!_isBoundary(ch) && !punctuation.hasMatch(ch)) return i;
      i++;
    }
    return -1;
  }

  /// The glyph rendered at an untyped position — the single choke point
  /// for what the display may disclose: spaces/newlines verbatim,
  /// first-letter hints on non-Master difficulties, `_` for everything else.
  static String untypedGlyph(
    String target,
    int index, {
    required bool isMaster,
    required Set<int> hintIndices,
  }) {
    final ch = target[index];
    if (_isBoundary(ch)) return ch;
    if (!isMaster && hintIndices.contains(index)) return ch;
    return '_';
  }
}
