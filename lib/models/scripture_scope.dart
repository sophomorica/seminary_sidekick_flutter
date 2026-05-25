import 'enums.dart';
import 'scripture.dart';
import 'scripture_mastery.dart';

/// String keys for the persistence layer in [ScriptureScopeNotifier].
///
/// Deliberately a plain-string namespace (not an enum) so adding a new
/// game type later doesn't require a Hive migration.
abstract class ScopeUsageContext {
  static const String quickQuiz = 'quickQuiz';
  static const String scriptureMatch = 'scriptureMatch';
  static const String groupQuiz = 'groupQuiz';
  static const String groupScriptureBuilder = 'groupScriptureBuilder';
}

/// Looks up a [ScriptureMastery] for a given scripture id, or returns null
/// if the scripture has no mastery record yet.
typedef MasteryLookup = ScriptureMastery? Function(String scriptureId);

/// Threshold subProgress (0..1) below the Mastered tier that qualifies a
/// scripture as "nearly mastered". Lives here so the picker label and the
/// resolved filter stay in sync.
const double kNearlyMasteredThreshold = 0.5;

/// "Which scriptures are eligible for this session" — a value object used
/// by the shared scope picker and the providers that consume its output.
///
/// Variants:
///   * [ScopeAll] — all 100 scriptures
///   * [ScopeBooks] — every scripture in the listed volumes
///   * [ScopeScriptureIds] — a hand-picked list of scripture ids
///   * [ScopeNeedsReview] — scriptures flagged `needsReview` by the mastery system
///   * [ScopeNearlyMastered] — scriptures below Mastered with subProgress
///     >= [kNearlyMasteredThreshold]
sealed class ScriptureScope {
  const ScriptureScope();

  /// JSON discriminator stored under `type`.
  String get type;

  Map<String, dynamic> toJson();

  /// Resolve to the concrete list of scriptures eligible for this session.
  ///
  /// The [masteryLookup] is only consulted for the dynamic scopes
  /// ([ScopeNeedsReview], [ScopeNearlyMastered]). When null, those scopes
  /// resolve to an empty list — callers should fall back to [ScopeAll] if
  /// they need a non-empty default.
  List<Scripture> resolve(
    List<Scripture> all, {
    MasteryLookup? masteryLookup,
  });

  /// A short, human-friendly label for the current selection.
  /// Used by the picker preview and call-site summaries.
  String shortLabel(List<Scripture> all);

  factory ScriptureScope.fromJson(Map<String, dynamic> json) {
    final t = json['type'] as String?;
    switch (t) {
      case 'all':
        return const ScopeAll();
      case 'books':
        return ScopeBooks.fromJson(json);
      case 'ids':
        return ScopeScriptureIds.fromJson(json);
      case 'needsReview':
        return const ScopeNeedsReview();
      case 'nearlyMastered':
        return const ScopeNearlyMastered();
      default:
        return const ScopeAll();
    }
  }
}

/// Selects every scripture in the corpus.
class ScopeAll extends ScriptureScope {
  const ScopeAll();

  @override
  String get type => 'all';

  @override
  Map<String, dynamic> toJson() => {'type': type};

  @override
  List<Scripture> resolve(
    List<Scripture> all, {
    MasteryLookup? masteryLookup,
  }) =>
      List<Scripture>.from(all);

  @override
  String shortLabel(List<Scripture> all) => 'All ${all.length}';

  @override
  bool operator ==(Object other) => other is ScopeAll;

  @override
  int get hashCode => type.hashCode;
}

/// Selects every scripture whose [Scripture.book] is in [books].
///
/// An empty set means "no books", which resolves to an empty list. Callers
/// that want "all books" should use [ScopeAll] instead.
class ScopeBooks extends ScriptureScope {
  final Set<ScriptureBook> books;

  const ScopeBooks(this.books);

  @override
  String get type => 'books';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'books': books.map((b) => b.name).toList(),
      };

  factory ScopeBooks.fromJson(Map<String, dynamic> json) {
    final names = (json['books'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const <String>[];
    final books = <ScriptureBook>{};
    for (final name in names) {
      for (final b in ScriptureBook.values) {
        if (b.name == name) {
          books.add(b);
          break;
        }
      }
    }
    return ScopeBooks(books);
  }

  @override
  List<Scripture> resolve(
    List<Scripture> all, {
    MasteryLookup? masteryLookup,
  }) {
    if (books.isEmpty) return const [];
    return all.where((s) => books.contains(s.book)).toList();
  }

  @override
  String shortLabel(List<Scripture> all) {
    if (books.isEmpty) return 'No books';
    if (books.length == 1) return books.first.displayName;
    if (books.length == ScriptureBook.values.length) {
      return 'All ${all.length}';
    }
    return '${books.length} books';
  }

  @override
  bool operator ==(Object other) {
    if (other is! ScopeBooks) return false;
    if (other.books.length != books.length) return false;
    return other.books.containsAll(books);
  }

  @override
  int get hashCode => Object.hashAllUnordered(books.map((b) => b.name));
}

/// Selects a hand-picked list of scripture ids, preserving the order they
/// were chosen in. Unknown ids are silently dropped on [resolve].
class ScopeScriptureIds extends ScriptureScope {
  final List<String> ids;

  const ScopeScriptureIds(this.ids);

  @override
  String get type => 'ids';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'ids': ids,
      };

  factory ScopeScriptureIds.fromJson(Map<String, dynamic> json) {
    final raw = (json['ids'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const <String>[];
    return ScopeScriptureIds(raw);
  }

  @override
  List<Scripture> resolve(
    List<Scripture> all, {
    MasteryLookup? masteryLookup,
  }) {
    final byId = {for (final s in all) s.id: s};
    final out = <Scripture>[];
    for (final id in ids) {
      final s = byId[id];
      if (s != null) out.add(s);
    }
    return out;
  }

  @override
  String shortLabel(List<Scripture> all) {
    if (ids.isEmpty) return 'None selected';
    if (ids.length == 1) {
      final byId = {for (final s in all) s.id: s};
      final s = byId[ids.first];
      return s?.reference ?? '1 scripture';
    }
    return '${ids.length} scriptures';
  }

  @override
  bool operator ==(Object other) {
    if (other is! ScopeScriptureIds) return false;
    if (other.ids.length != ids.length) return false;
    for (int i = 0; i < ids.length; i++) {
      if (other.ids[i] != ids[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(ids);
}

/// Selects scriptures the mastery system has flagged for review (decay).
class ScopeNeedsReview extends ScriptureScope {
  const ScopeNeedsReview();

  @override
  String get type => 'needsReview';

  @override
  Map<String, dynamic> toJson() => {'type': type};

  @override
  List<Scripture> resolve(
    List<Scripture> all, {
    MasteryLookup? masteryLookup,
  }) {
    if (masteryLookup == null) return const [];
    return all.where((s) {
      final m = masteryLookup(s.id);
      return m != null && m.needsReview;
    }).toList();
  }

  @override
  String shortLabel(List<Scripture> all) => 'Needs Review';

  @override
  bool operator ==(Object other) => other is ScopeNeedsReview;

  @override
  int get hashCode => type.hashCode;
}

/// Selects scriptures the user is making progress on but hasn't yet
/// reached the Mastered tier — anything at or above [kNearlyMasteredThreshold]
/// of its tier's sub-progress that isn't already Mastered.
class ScopeNearlyMastered extends ScriptureScope {
  const ScopeNearlyMastered();

  @override
  String get type => 'nearlyMastered';

  @override
  Map<String, dynamic> toJson() => {'type': type};

  @override
  List<Scripture> resolve(
    List<Scripture> all, {
    MasteryLookup? masteryLookup,
  }) {
    if (masteryLookup == null) return const [];
    return all.where((s) {
      final m = masteryLookup(s.id);
      if (m == null) return false;
      if (m.level == MasteryLevel.mastered ||
          m.level == MasteryLevel.eternal) {
        return false;
      }
      return m.subProgress >= kNearlyMasteredThreshold;
    }).toList();
  }

  @override
  String shortLabel(List<Scripture> all) => 'Nearly Mastered';

  @override
  bool operator ==(Object other) => other is ScopeNearlyMastered;

  @override
  int get hashCode => type.hashCode;
}
