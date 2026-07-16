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
  static const String soloScriptureBuilder = 'soloScriptureBuilder';
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

/// Preferred chip order for the scope picker (books, then status filters).
const List<ScriptureBook> kScopeBookOrder = [
  ScriptureBook.bookOfMormon,
  ScriptureBook.oldTestament,
  ScriptureBook.newTestament,
  ScriptureBook.doctrineAndCovenants,
];

/// Composable "which scriptures are eligible" filter.
///
/// Everything multi-selects and combines:
///   * [books] — empty means all volumes; otherwise union of selected volumes
///   * [needsReview] / [nearlyMastered] — when either is on, keep scriptures
///     matching *any* selected status (AND'd with the book filter)
///   * [specificIds] — optional hand-picked subset of the filtered pool;
///     empty means "use the whole filtered pool"
///
/// An empty [ScriptureScope] (no books, no status, no ids) = all scriptures.
class ScriptureScope {
  final Set<ScriptureBook> books;
  final bool needsReview;
  final bool nearlyMastered;
  final List<String> specificIds;

  const ScriptureScope({
    this.books = const {},
    this.needsReview = false,
    this.nearlyMastered = false,
    this.specificIds = const [],
  });

  /// No filters and no hand-picks — the full corpus.
  bool get isUnfiltered =>
      books.isEmpty &&
      !needsReview &&
      !nearlyMastered &&
      specificIds.isEmpty;

  bool get hasStatusFilter => needsReview || nearlyMastered;

  bool get hasSpecificIds => specificIds.isNotEmpty;

  /// JSON discriminator. Always `'filter'` for new writes; [fromJson] still
  /// accepts the legacy exclusive types and migrates them.
  String get type => 'filter';

  Map<String, dynamic> toJson() => {
        'type': type,
        // Sorted so the emitted JSON is deterministic (books is a Set).
        'books': books.map((b) => b.name).toList()..sort(),
        'needsReview': needsReview,
        'nearlyMastered': nearlyMastered,
        'ids': specificIds,
      };

  factory ScriptureScope.fromJson(Map<String, dynamic> json) {
    final t = json['type'] as String?;
    switch (t) {
      case 'filter':
        return ScriptureScope(
          books: _booksFromJson(json['books']),
          needsReview: json['needsReview'] as bool? ?? false,
          nearlyMastered: json['nearlyMastered'] as bool? ?? false,
          specificIds: _idsFromJson(json['ids']),
        );
      // Legacy exclusive scopes → equivalent filter.
      case 'all':
        return const ScriptureScope();
      case 'books':
        return ScriptureScope(books: _booksFromJson(json['books']));
      case 'ids':
        return ScriptureScope(specificIds: _idsFromJson(json['ids']));
      case 'needsReview':
        return const ScriptureScope(needsReview: true);
      case 'nearlyMastered':
        return const ScriptureScope(nearlyMastered: true);
      default:
        return const ScriptureScope();
    }
  }

  static Set<ScriptureBook> _booksFromJson(dynamic raw) {
    final names = (raw as List<dynamic>?)?.map((e) => e as String).toList() ??
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
    return books;
  }

  static List<String> _idsFromJson(dynamic raw) {
    return (raw as List<dynamic>?)?.map((e) => e as String).toList() ??
        const <String>[];
  }

  ScriptureScope copyWith({
    Set<ScriptureBook>? books,
    bool? needsReview,
    bool? nearlyMastered,
    List<String>? specificIds,
  }) {
    return ScriptureScope(
      books: books ?? this.books,
      needsReview: needsReview ?? this.needsReview,
      nearlyMastered: nearlyMastered ?? this.nearlyMastered,
      specificIds: specificIds ?? this.specificIds,
    );
  }

  /// Pool after book + status filters, before any hand-pick.
  List<Scripture> filterPool(
    List<Scripture> all, {
    MasteryLookup? masteryLookup,
  }) {
    Iterable<Scripture> pool = all;

    if (books.isNotEmpty) {
      pool = pool.where((s) => books.contains(s.book));
    }

    if (hasStatusFilter) {
      pool = pool.where((s) {
        final m = masteryLookup?.call(s.id);
        final matchesReview = needsReview && m != null && m.needsReview;
        final matchesNearly =
            nearlyMastered && m != null && _isNearlyMastered(m);
        return matchesReview || matchesNearly;
      });
    }

    return pool.toList();
  }

  /// Resolve to the concrete list of scriptures eligible for this session.
  ///
  /// [masteryLookup] is required for status filters to match anything; when
  /// null, Needs Review / Nearly Mastered contribute no matches.
  List<Scripture> resolve(
    List<Scripture> all, {
    MasteryLookup? masteryLookup,
  }) {
    final pool = filterPool(all, masteryLookup: masteryLookup);
    if (!hasSpecificIds) return pool;

    final inPool = {for (final s in pool) s.id: s};
    final out = <Scripture>[];
    for (final id in specificIds) {
      final s = inPool[id];
      if (s != null) out.add(s);
    }
    return out;
  }

  /// Drop hand-picked ids that no longer sit inside [filterPool].
  ScriptureScope prunedToFilter(
    List<Scripture> all, {
    MasteryLookup? masteryLookup,
  }) {
    if (!hasSpecificIds) return this;
    final allowed =
        filterPool(all, masteryLookup: masteryLookup).map((s) => s.id).toSet();
    final kept = specificIds.where(allowed.contains).toList();
    if (kept.length == specificIds.length) return this;
    return copyWith(specificIds: kept);
  }

  /// A short, human-friendly label for the current selection.
  String shortLabel(List<Scripture> all) {
    if (hasSpecificIds) {
      final n = specificIds.length;
      if (n == 1) {
        final byId = {for (final s in all) s.id: s};
        return byId[specificIds.first]?.reference ?? '1 scripture';
      }
      return '$n scriptures';
    }

    final parts = <String>[];
    if (books.isNotEmpty) {
      if (books.length == 1) {
        parts.add(books.first.displayName);
      } else if (books.length == ScriptureBook.values.length) {
        parts.add('All books');
      } else {
        parts.add('${books.length} books');
      }
    }
    if (needsReview) parts.add('Needs Review');
    if (nearlyMastered) parts.add('Nearly Mastered');
    if (parts.isEmpty) return 'All ${all.length}';
    return parts.join(' · ');
  }

  static bool _isNearlyMastered(ScriptureMastery m) {
    if (m.level == MasteryLevel.mastered || m.level == MasteryLevel.eternal) {
      return false;
    }
    return m.subProgress >= kNearlyMasteredThreshold;
  }

  @override
  bool operator ==(Object other) {
    if (other is! ScriptureScope) return false;
    if (needsReview != other.needsReview) return false;
    if (nearlyMastered != other.nearlyMastered) return false;
    if (books.length != other.books.length) return false;
    if (!other.books.containsAll(books)) return false;
    if (specificIds.length != other.specificIds.length) return false;
    for (int i = 0; i < specificIds.length; i++) {
      if (specificIds[i] != other.specificIds[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        needsReview,
        nearlyMastered,
        Object.hashAllUnordered(books.map((b) => b.name)),
        Object.hashAll(specificIds),
      );
}
