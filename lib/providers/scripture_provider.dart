import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/scripture.dart';
import '../models/enums.dart';
import '../data/scriptures_data.dart';

/// Provider that returns all scriptures
final scripturesProvider = Provider<List<Scripture>>((ref) {
  return allScriptures;
});

/// Family provider that filters scriptures by book
final scripturesByBookProvider = Provider.family<List<Scripture>, ScriptureBook>(
  (ref, book) {
    final all = ref.watch(scripturesProvider);
    return all.where((s) => s.book == book).toList();
  },
);

/// Family provider that finds a scripture by id
final scriptureByIdProvider = Provider.family<Scripture?, String>(
  (ref, id) {
    final all = ref.watch(scripturesProvider);
    try {
      return all.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  },
);

/// Family provider that searches scriptures by query string
/// Searches across name, reference, and keyPhrase
final searchScripturesProvider = Provider.family<List<Scripture>, String>(
  (ref, query) {
    final all = ref.watch(scripturesProvider);
    final lowerQuery = query.toLowerCase();

    if (query.isEmpty) {
      return all;
    }

    return all
        .where((s) =>
            s.name.toLowerCase().contains(lowerQuery) ||
            s.reference.toLowerCase().contains(lowerQuery) ||
            s.keyPhrase.toLowerCase().contains(lowerQuery))
        .toList();
  },
);
