import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Runtime subscription override for the Dev Menu.
///
/// This lets you toggle Free/Premium at runtime without editing code.
/// The override takes priority over [AppConfig.forcePremium] when set.
///
/// Values:
///   `null`  → use AppConfig defaults (or real subscription in release)
///   `true`  → force premium
///   `false` → force free
class DevModeNotifier extends StateNotifier<bool?> {
  DevModeNotifier() : super(null);

  /// Override to premium experience.
  void forcePremium() => state = true;

  /// Override to free-tier experience.
  void forceFree() => state = false;

  /// Clear override — fall back to AppConfig defaults.
  void useDefault() => state = null;
}

final devModeOverrideProvider =
    StateNotifierProvider<DevModeNotifier, bool?>(
  (ref) => DevModeNotifier(),
);
