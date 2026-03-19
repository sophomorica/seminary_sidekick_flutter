import 'enums.dart';

/// A single Doctrinal Mastery scripture passage.
///
/// This is the core data object — immutable, with pre-computed fields
/// for game use (word list, word count, difficulty weighting).
class Scripture {
  final String id;
  final ScriptureBook book;
  final String volume;       // e.g., "1 Nephi", "Matthew", "D&C"
  final String reference;    // e.g., "1 Nephi 3:7"
  final String name;         // Topic name, e.g., "Obedience to Commandments"
  final String keyPhrase;    // Short memorable phrase
  final String fullText;     // Complete scripture text for memorization
  final List<String> words;  // Pre-split words for word order game
  final int wordCount;
  final String? userNotes;   // User-added notes/comments

  Scripture({
    required this.id,
    required this.book,
    required this.volume,
    required this.reference,
    required this.name,
    required this.keyPhrase,
    required this.fullText,
    this.userNotes,
  })  : words = _splitIntoWords(fullText),
        wordCount = _splitIntoWords(fullText).length;

  /// Split text into clean words, preserving punctuation attached to words
  /// but removing verse numbers and paragraph markers.
  static List<String> _splitIntoWords(String text) {
    return text
        .replaceAll(RegExp(r'^\d+\s*', multiLine: true), '') // verse numbers
        .replaceAll(RegExp(r'[¶]'), '')                       // paragraph marks
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  /// Inherent difficulty score (1-10) based on length and complexity.
  int get difficultyScore {
    if (wordCount <= 15) return 1;
    if (wordCount <= 30) return 3;
    if (wordCount <= 50) return 5;
    if (wordCount <= 75) return 7;
    return 10;
  }

  /// Create a copy with user notes updated.
  Scripture copyWith({String? userNotes}) {
    return Scripture(
      id: id,
      book: book,
      volume: volume,
      reference: reference,
      name: name,
      keyPhrase: keyPhrase,
      fullText: fullText,
      userNotes: userNotes ?? this.userNotes,
    );
  }

  @override
  String toString() => 'Scripture($reference: "$name")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Scripture && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
