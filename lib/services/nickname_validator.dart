import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Sealed result of validating a nickname.
sealed class NicknameResult {
  const NicknameResult();
}

class NicknameValid extends NicknameResult {
  const NicknameValid();
}

class NicknameTooShort extends NicknameResult {
  const NicknameTooShort();
}

class NicknameTooLong extends NicknameResult {
  const NicknameTooLong();
}

class NicknameInvalidChars extends NicknameResult {
  const NicknameInvalidChars();
}

class NicknameProfanity extends NicknameResult {
  const NicknameProfanity();
}

/// Pure, sync nickname validator with a profanity check.
///
/// Length: 2–14 chars (after trim). Allowed chars: alphanumeric + spaces.
///
/// The profanity wordlist lives in `assets/data/profanity_seed.txt`.
/// Call [preload] at app start to load it into memory; afterwards, [validate]
/// runs synchronously. If [validate] is invoked before the wordlist finishes
/// loading, the length/charset checks still run but the profanity match is
/// skipped (fail-open) — so the worst case is a missed-profanity hit, never
/// a blocked legitimate nickname.
class NicknameValidator {
  static const int minLength = 2;
  static const int maxLength = 14;
  static const String _wordlistAsset = 'assets/data/profanity_seed.txt';

  static final RegExp _validCharsRegex = RegExp(r'^[A-Za-z0-9 ]+$');
  static final RegExp _whitespaceRegex = RegExp(r'\s+');

  static Set<String>? _words;
  static Future<void>? _loadingFuture;

  /// Loads the profanity wordlist once. Call from `main()` so [validate] can
  /// catch profanity from the very first lobby visit. Idempotent — repeat
  /// calls return the same future.
  static Future<void> preload({AssetBundle? bundle}) {
    return _loadingFuture ??= _load(bundle ?? rootBundle);
  }

  static Future<void> _load(AssetBundle bundle) async {
    final raw = await bundle.loadString(_wordlistAsset);
    _words = _parseWordlist(raw);
  }

  static Set<String> _parseWordlist(String raw) {
    return raw
        .split('\n')
        .map((line) => line.trim().toLowerCase())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .toSet();
  }

  /// Validates [input] synchronously and returns a sealed [NicknameResult].
  ///
  /// Order is: length → profanity → charset. The profanity check runs before
  /// charset rejection so l33t-speak bypasses that lean on special chars
  /// (e.g. `B@dW0rd` → `badword`) get caught for what they really are. A
  /// nickname that's *not* a bypass attempt but still has a stray punctuation
  /// mark falls through to the charset rule.
  static NicknameResult validate(String input) {
    final trimmed = input.trim();
    if (trimmed.length < minLength) return const NicknameTooShort();
    if (trimmed.length > maxLength) return const NicknameTooLong();

    final words = _words;
    if (words != null && words.isNotEmpty) {
      final normalized = _normalize(trimmed);
      final stripped = normalized.replaceAll(_whitespaceRegex, '');
      if (words.contains(stripped)) return const NicknameProfanity();
      for (final token in normalized.split(_whitespaceRegex)) {
        if (token.isEmpty) continue;
        if (words.contains(token)) return const NicknameProfanity();
      }
    }

    if (!_validCharsRegex.hasMatch(trimmed)) {
      return const NicknameInvalidChars();
    }
    return const NicknameValid();
  }

  /// Lowercase + l33t-speak replacement: 0→o, 1→l, 3→e, 4→a, 5→s, 7→t, @→a.
  static String _normalize(String input) {
    final lower = input.toLowerCase();
    final buf = StringBuffer();
    for (final ch in lower.codeUnits) {
      switch (ch) {
        case 0x30:
          buf.writeCharCode(0x6f);
          break;
        case 0x31:
          buf.writeCharCode(0x6c);
          break;
        case 0x33:
          buf.writeCharCode(0x65);
          break;
        case 0x34:
          buf.writeCharCode(0x61);
          break;
        case 0x35:
          buf.writeCharCode(0x73);
          break;
        case 0x37:
          buf.writeCharCode(0x74);
          break;
        case 0x40:
          buf.writeCharCode(0x61);
          break;
        default:
          buf.writeCharCode(ch);
      }
    }
    return buf.toString();
  }

  @visibleForTesting
  static void loadWordsForTesting(String raw) {
    _words = _parseWordlist(raw);
  }

  @visibleForTesting
  static void resetForTesting() {
    _words = null;
    _loadingFuture = null;
  }
}
