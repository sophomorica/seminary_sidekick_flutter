import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/scripture_scope.dart';

/// Hive-backed store of "last used scope per game type".
///
/// Each consumer (Quick Quiz, Scripture Match, group Quiz, group Scripture Builder
/// race) writes under its own [ScopeUsageContext] key and reads back its own
/// scope on next session start. Scopes never bleed between contexts.
class ScriptureScopeNotifier
    extends StateNotifier<Map<String, ScriptureScope>> {
  static const _boxName = 'scripture_scope_prefs';
  Box? _box;

  ScriptureScopeNotifier() : super(const {});

  /// Load persisted scopes from Hive.
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    final loaded = <String, ScriptureScope>{};
    for (final key in _box!.keys) {
      if (key is! String) continue;
      final raw = _box!.get(key);
      if (raw is Map) {
        try {
          loaded[key] = ScriptureScope.fromJson(
            Map<String, dynamic>.from(raw),
          );
        } catch (_) {
          // Ignore corrupted entries — next save will overwrite.
        }
      }
    }
    state = loaded;
  }

  /// Last-used scope for the given [context], or null if nothing saved yet.
  ScriptureScope? lastUsedScope(String context) => state[context];

  /// Persist [scope] under [context]. Subsequent [lastUsedScope] calls
  /// (and a re-mount after restart) will return this value.
  Future<void> saveScope(String context, ScriptureScope scope) async {
    state = {...state, context: scope};
    await _box?.put(context, scope.toJson());
  }

  /// Remove the saved scope for [context], if any.
  Future<void> clearScope(String context) async {
    final next = Map<String, ScriptureScope>.from(state)..remove(context);
    state = next;
    await _box?.delete(context);
  }
}

final scriptureScopeProvider = StateNotifierProvider<ScriptureScopeNotifier,
    Map<String, ScriptureScope>>(
  (ref) => ScriptureScopeNotifier(),
);

/// Convenience family — returns the last-used scope for a given context,
/// or null if nothing has been saved yet.
final lastUsedScopeProvider =
    Provider.family<ScriptureScope?, String>((ref, context) {
  return ref.watch(scriptureScopeProvider)[context];
});
