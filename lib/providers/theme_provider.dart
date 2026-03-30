import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Persisted theme mode provider.
///
/// Stores the user's light/dark preference in Hive so it survives
/// app restarts. Defaults to [ThemeMode.system].
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(),
);

class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const _boxName = 'settings';
  static const _key = 'themeMode';
  Box? _box;

  ThemeNotifier() : super(ThemeMode.system);

  /// Open Hive box and load the persisted theme choice.
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    final stored = _box?.get(_key, defaultValue: 'system') as String;
    state = _fromString(stored);
  }

  /// Cycle through: system → light → dark → system
  void toggle() {
    switch (state) {
      case ThemeMode.system:
        state = ThemeMode.light;
      case ThemeMode.light:
        state = ThemeMode.dark;
      case ThemeMode.dark:
        state = ThemeMode.system;
    }
    _persist();
  }

  /// Set a specific theme mode.
  void setThemeMode(ThemeMode mode) {
    state = mode;
    _persist();
  }

  void _persist() {
    _box?.put(_key, _toString(state));
  }

  static ThemeMode _fromString(String value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static String _toString(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }
}
