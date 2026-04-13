import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:seminary_sidekick/providers/user_preferences_provider.dart';

void main() {
  late UserPreferencesNotifier notifier;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_prefs_test_');
    Hive.init(tempDir.path);
    notifier = UserPreferencesNotifier();
    await notifier.init();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  // -------------------------------------------------------
  // Default state
  // -------------------------------------------------------
  group('default state', () {
    test('has empty display name', () {
      expect(notifier.state.displayName, '');
    });

    test('sound is enabled by default', () {
      expect(notifier.state.soundEnabled, true);
    });

    test('haptics are enabled by default', () {
      expect(notifier.state.hapticsEnabled, true);
    });

    test('font scale defaults to 1.0', () {
      expect(notifier.state.fontScale, 1.0);
    });

    test('notifications enabled by default', () {
      expect(notifier.state.notificationsEnabled, true);
    });

    test('daily reminder disabled by default', () {
      expect(notifier.state.dailyReminderEnabled, false);
    });

    test('daily reminder defaults to 7:00', () {
      expect(notifier.state.dailyReminderHour, 7);
      expect(notifier.state.dailyReminderMinute, 0);
    });
  });

  // -------------------------------------------------------
  // greetingName
  // -------------------------------------------------------
  group('greetingName', () {
    test('returns Friend when display name is empty', () {
      expect(notifier.state.greetingName, 'Friend');
    });

    test('returns Friend when display name is whitespace', () {
      notifier.setDisplayName('   ');
      expect(notifier.state.greetingName, 'Friend');
    });

    test('returns first name from full name', () {
      notifier.setDisplayName('Patrick Lamoureux');
      expect(notifier.state.greetingName, 'Patrick');
    });

    test('returns single name as-is', () {
      notifier.setDisplayName('Patrick');
      expect(notifier.state.greetingName, 'Patrick');
    });

    test('trims whitespace before extracting first name', () {
      notifier.setDisplayName('  Patrick  ');
      expect(notifier.state.greetingName, 'Patrick');
    });
  });

  // -------------------------------------------------------
  // setDisplayName
  // -------------------------------------------------------
  group('setDisplayName', () {
    test('updates display name', () {
      notifier.setDisplayName('Elder Smith');
      expect(notifier.state.displayName, 'Elder Smith');
    });

    test('persists across reinit', () async {
      notifier.setDisplayName('Elder Smith');

      // Re-init to simulate app restart
      final notifier2 = UserPreferencesNotifier();
      await notifier2.init();
      expect(notifier2.state.displayName, 'Elder Smith');
    });
  });

  // -------------------------------------------------------
  // setSoundEnabled
  // -------------------------------------------------------
  group('setSoundEnabled', () {
    test('can disable sound', () {
      notifier.setSoundEnabled(false);
      expect(notifier.state.soundEnabled, false);
    });

    test('persists across reinit', () async {
      notifier.setSoundEnabled(false);

      final notifier2 = UserPreferencesNotifier();
      await notifier2.init();
      expect(notifier2.state.soundEnabled, false);
    });
  });

  // -------------------------------------------------------
  // setHapticsEnabled
  // -------------------------------------------------------
  group('setHapticsEnabled', () {
    test('can disable haptics', () {
      notifier.setHapticsEnabled(false);
      expect(notifier.state.hapticsEnabled, false);
    });

    test('can re-enable haptics', () {
      notifier.setHapticsEnabled(false);
      notifier.setHapticsEnabled(true);
      expect(notifier.state.hapticsEnabled, true);
    });

    test('persists across reinit', () async {
      notifier.setHapticsEnabled(false);

      final notifier2 = UserPreferencesNotifier();
      await notifier2.init();
      expect(notifier2.state.hapticsEnabled, false);
    });
  });

  // -------------------------------------------------------
  // setFontScale
  // -------------------------------------------------------
  group('setFontScale', () {
    test('can set small font', () {
      notifier.setFontScale(0.85);
      expect(notifier.state.fontScale, 0.85);
    });

    test('can set large font', () {
      notifier.setFontScale(1.3);
      expect(notifier.state.fontScale, 1.3);
    });

    test('persists across reinit', () async {
      notifier.setFontScale(1.15);

      final notifier2 = UserPreferencesNotifier();
      await notifier2.init();
      expect(notifier2.state.fontScale, 1.15);
    });
  });

  // -------------------------------------------------------
  // setDailyReminder
  // -------------------------------------------------------
  group('setDailyReminder', () {
    test('can enable with custom time', () {
      notifier.setDailyReminder(enabled: true, hour: 19, minute: 30);
      expect(notifier.state.dailyReminderEnabled, true);
      expect(notifier.state.dailyReminderHour, 19);
      expect(notifier.state.dailyReminderMinute, 30);
    });

    test('can disable without changing time', () {
      notifier.setDailyReminder(enabled: true, hour: 8, minute: 15);
      notifier.setDailyReminder(enabled: false);
      expect(notifier.state.dailyReminderEnabled, false);
      expect(notifier.state.dailyReminderHour, 8);
      expect(notifier.state.dailyReminderMinute, 15);
    });
  });

  // -------------------------------------------------------
  // resetAll
  // -------------------------------------------------------
  group('resetAll', () {
    test('restores all defaults', () async {
      notifier.setDisplayName('Elder Smith');
      notifier.setSoundEnabled(false);
      notifier.setHapticsEnabled(false);
      notifier.setFontScale(1.3);
      notifier.setNotificationsEnabled(false);

      await notifier.resetAll();

      expect(notifier.state.displayName, '');
      expect(notifier.state.soundEnabled, true);
      expect(notifier.state.hapticsEnabled, true);
      expect(notifier.state.fontScale, 1.0);
      expect(notifier.state.notificationsEnabled, true);
    });

    test('reset persists across reinit', () async {
      notifier.setDisplayName('Elder Smith');
      await notifier.resetAll();

      final notifier2 = UserPreferencesNotifier();
      await notifier2.init();
      expect(notifier2.state.displayName, '');
    });
  });

  // -------------------------------------------------------
  // copyWith
  // -------------------------------------------------------
  group('UserPreferences.copyWith', () {
    test('copies with single field override', () {
      const original = UserPreferences(displayName: 'Test');
      final copy = original.copyWith(soundEnabled: false);

      expect(copy.displayName, 'Test');
      expect(copy.soundEnabled, false);
      expect(copy.hapticsEnabled, true); // unchanged
    });

    test('copies with no overrides returns equal state', () {
      const original = UserPreferences(
        displayName: 'Test',
        fontScale: 1.15,
      );
      final copy = original.copyWith();

      expect(copy.displayName, original.displayName);
      expect(copy.fontScale, original.fontScale);
      expect(copy.soundEnabled, original.soundEnabled);
    });
  });

  // -------------------------------------------------------
  // JSON serialization
  // -------------------------------------------------------
  group('JSON serialization', () {
    test('round-trips through toJson/fromJson', () {
      const original = UserPreferences(
        displayName: 'Elder Smith',
        soundEnabled: false,
        hapticsEnabled: false,
        fontScale: 1.15,
        notificationsEnabled: false,
        dailyReminderEnabled: true,
        dailyReminderHour: 19,
        dailyReminderMinute: 30,
      );

      final json = original.toJson();
      final restored = UserPreferences.fromJson(json);

      expect(restored.displayName, 'Elder Smith');
      expect(restored.soundEnabled, false);
      expect(restored.hapticsEnabled, false);
      expect(restored.fontScale, 1.15);
      expect(restored.notificationsEnabled, false);
      expect(restored.dailyReminderEnabled, true);
      expect(restored.dailyReminderHour, 19);
      expect(restored.dailyReminderMinute, 30);
    });

    test('fromJson handles missing keys with defaults', () {
      final restored = UserPreferences.fromJson({});

      expect(restored.displayName, '');
      expect(restored.soundEnabled, true);
      expect(restored.hapticsEnabled, true);
      expect(restored.fontScale, 1.0);
    });

    test('fromJson handles null values with defaults', () {
      final restored = UserPreferences.fromJson({
        'displayName': null,
        'soundEnabled': null,
        'fontScale': null,
      });

      expect(restored.displayName, '');
      expect(restored.soundEnabled, true);
      expect(restored.fontScale, 1.0);
    });
  });
}
