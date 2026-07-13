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
String? findScriptureIdByReference(String refText) {
  final normalised = refText.trim().toLowerCase();
  for (final s in allScriptures) {
    if (s.reference.toLowerCase() == normalised) return s.id;
    if (s.reference.toLowerCase().startsWith(normalised) ||
        normalised.startsWith(s.reference.toLowerCase())) {
      return s.id;
    }
  }
  return null;
}

/// Resolves a scripture ID from an explicit ID and/or free-form suggestion text.
///
/// The Sidekick sometimes omits [scriptureId] or sends a reference string that
/// gets stripped during sanitization — but the suggestion still names the verse.
String? resolveScriptureId({
  String? scriptureId,
  String? suggestionText,
}) {
  if (scriptureId != null) {
    final byId = allScriptures
        .where((s) => s.id == scriptureId)
        .map((s) => s.id)
        .firstOrNull;
    if (byId != null) return byId;
  }

  final text = suggestionText?.trim();
  if (text == null || text.isEmpty) return null;

  final match = scriptureRefPattern.firstMatch(text);
  if (match != null) {
    final fromRef = findScriptureIdByReference(match.group(0)!);
    if (fromRef != null) return fromRef;
  }

  return null;
}
