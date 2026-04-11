import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// User preferences state — persisted via Hive.
class UserPreferences {
  final String displayName;
  final bool soundEnabled;
  final bool hapticsEnabled;
  final double fontScale; // 1.0 = normal, 0.85 = small, 1.15 = large
  final bool notificationsEnabled;
  final bool dailyReminderEnabled;
  final int dailyReminderHour; // 0–23
  final int dailyReminderMinute; // 0–59

  const UserPreferences({
    this.displayName = '',
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.fontScale = 1.0,
    this.notificationsEnabled = true,
    this.dailyReminderEnabled = false,
    this.dailyReminderHour = 7,
    this.dailyReminderMinute = 0,
  });

  UserPreferences copyWith({
    String? displayName,
    bool? soundEnabled,
    bool? hapticsEnabled,
    double? fontScale,
    bool? notificationsEnabled,
    bool? dailyReminderEnabled,
    int? dailyReminderHour,
    int? dailyReminderMinute,
  }) {
    return UserPreferences(
      displayName: displayName ?? this.displayName,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      fontScale: fontScale ?? this.fontScale,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderHour: dailyReminderHour ?? this.dailyReminderHour,
      dailyReminderMinute: dailyReminderMinute ?? this.dailyReminderMinute,
    );
  }

  /// User's first name for greetings (or 'Friend' as fallback).
  String get greetingName =>
      displayName.trim().isEmpty ? 'Friend' : displayName.trim().split(' ').first;

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'soundEnabled': soundEnabled,
        'hapticsEnabled': hapticsEnabled,
        'fontScale': fontScale,
        'notificationsEnabled': notificationsEnabled,
        'dailyReminderEnabled': dailyReminderEnabled,
        'dailyReminderHour': dailyReminderHour,
        'dailyReminderMinute': dailyReminderMinute,
      };

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      displayName: json['displayName'] as String? ?? '',
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
      fontScale: (json['fontScale'] as num?)?.toDouble() ?? 1.0,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      dailyReminderEnabled: json['dailyReminderEnabled'] as bool? ?? false,
      dailyReminderHour: json['dailyReminderHour'] as int? ?? 7,
      dailyReminderMinute: json['dailyReminderMinute'] as int? ?? 0,
    );
  }
}

/// Hive-backed StateNotifier for user preferences.
class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  static const _boxName = 'user_preferences';
  static const _key = 'prefs';
  Box? _box;

  UserPreferencesNotifier() : super(const UserPreferences());

  /// Load persisted preferences from Hive.
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    final raw = _box?.get(_key);
    if (raw != null && raw is Map) {
      state = UserPreferences.fromJson(Map<String, dynamic>.from(raw));
    }
  }

  void _persist() {
    _box?.put(_key, state.toJson());
  }

  void setDisplayName(String name) {
    state = state.copyWith(displayName: name);
    _persist();
  }

  void setSoundEnabled(bool enabled) {
    state = state.copyWith(soundEnabled: enabled);
    _persist();
  }

  void setHapticsEnabled(bool enabled) {
    state = state.copyWith(hapticsEnabled: enabled);
    _persist();
  }

  void setFontScale(double scale) {
    state = state.copyWith(fontScale: scale);
    _persist();
  }

  void setNotificationsEnabled(bool enabled) {
    state = state.copyWith(notificationsEnabled: enabled);
    _persist();
  }

  void setDailyReminder({required bool enabled, int? hour, int? minute}) {
    state = state.copyWith(
      dailyReminderEnabled: enabled,
      dailyReminderHour: hour,
      dailyReminderMinute: minute,
    );
    _persist();
  }

  /// Reset all preferences to defaults.
  Future<void> resetAll() async {
    state = const UserPreferences();
    _persist();
  }
}

final userPreferencesProvider =
    StateNotifierProvider<UserPreferencesNotifier, UserPreferences>(
  (ref) => UserPreferencesNotifier(),
);

/// Convenience: greeting name (first name or 'Friend').
final greetingNameProvider = Provider<String>((ref) {
  return ref.watch(userPreferencesProvider).greetingName;
});
