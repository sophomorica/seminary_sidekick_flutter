import '../data/scriptures_data.dart';

/// Regex pattern that matches common scripture references in the 100 DM list.
final scriptureRefPattern = RegExp(
  r'\b('
  r'[1-4]\s?(?:Nephi|John|Corinthians|Thessalonians|Timothy|Peter|Samuel|Kings|Chronicles)'
  r'|'
  r'(?:Genesis|Exodus|Leviticus|Deuteronomy|Joshua|Judges|Ruth|Psalms?|Proverbs|Ecclesiastes|Isaiah|Jeremiah|Ezekiel|Daniel|Hosea|Joel|Amos|Obadiah|Jonah|Micah|Nahum|Habakkuk|Zephaniah|Haggai|Zechariah|Malachi'
  r'|Matthew|Mark|Luke|John|Acts|Romans|Galatians|Ephesians|Philippians|Colossians|Hebrews|James|Jude|Revelation'
  r'|Mosiah|Alma|Helaman|Mormon|Ether|Moroni|Jacob|Enos|Jarom|Omni|Words of Mormon'
  r'|Moses|Abraham|Joseph Smith[—–\-]History|JS[—–\-]H|Articles of Faith'
  r'|D&C|Doctrine and Covenants)'
  r')'
  r'\s+\d+:\d+(?:\s?[–—\-]\s?\d+)?'
  r'\b',
  caseSensitive: false,
);

/// Looks up a scripture ID by its human-readable reference (e.g. "Alma 39:9").
///
/// Exact matches win before prefix matches, and a prefix only counts when it
/// ends on a non-digit boundary — otherwise "D&C 130:22–23" would resolve to
/// the "D&C 13" entry that precedes it in [allScriptures].
String? findScriptureIdByReference(String refText) {
  final normalised = refText.trim().toLowerCase();
  for (final s in allScriptures) {
    if (s.reference.toLowerCase() == normalised) return s.id;
  }
  for (final s in allScriptures) {
    final ref = s.reference.toLowerCase();
    if (_isPrefixOnBoundary(ref, normalised) ||
        _isPrefixOnBoundary(normalised, ref)) {
      return s.id;
    }
  }
  return null;
}

/// True when [full] starts with [prefix] and the next character is not a
/// digit, so "d&c 13" does not swallow "d&c 130:22–23".
bool _isPrefixOnBoundary(String full, String prefix) {
  if (!full.startsWith(prefix)) return false;
  if (full.length == prefix.length) return true;
  final next = full.codeUnitAt(prefix.length);
  return next < 0x30 || next > 0x39;
}

/// Finds the first known scripture reference in free-form [text] and returns
/// its ID (e.g. "Spend 2 minutes on Alma 39:9" → the ID for Alma 39:9).
String? findScriptureIdInText(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  final match = scriptureRefPattern.firstMatch(trimmed);
  if (match == null) return null;
  return findScriptureIdByReference(match.group(0)!);
}

/// Resolves a scripture ID from an explicit ID and/or free-form suggestion
/// text. Only the first reference in [suggestionText] is considered.
///
/// The Sidekick sometimes omits [scriptureId] or sends a reference string that
/// gets stripped during sanitization — but the suggestion still names the verse.
String? resolveScriptureId({
  String? scriptureId,
  String? suggestionText,
}) {
  if (scriptureId != null && allScriptures.any((s) => s.id == scriptureId)) {
    return scriptureId;
  }
  if (suggestionText == null) return null;
  return findScriptureIdInText(suggestionText);
}
