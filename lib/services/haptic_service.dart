import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/user_preferences_provider.dart';

/// Centralized haptic feedback that respects the user's preference.
///
/// Usage from any ConsumerWidget / ConsumerState:
///   ref.read(hapticProvider).light();
///   ref.read(hapticProvider).medium();
///   ref.read(hapticProvider).heavy();
///   ref.read(hapticProvider).selection();
class HapticService {
  final bool _enabled;

  const HapticService._(this._enabled);

  void light() {
    if (_enabled) HapticFeedback.lightImpact();
  }

  void medium() {
    if (_enabled) HapticFeedback.mediumImpact();
  }

  void heavy() {
    if (_enabled) HapticFeedback.heavyImpact();
  }

  void selection() {
    if (_enabled) HapticFeedback.selectionClick();
  }
}

/// Provider that rebuilds when the haptics preference changes.
final hapticProvider = Provider<HapticService>((ref) {
  final enabled = ref.watch(userPreferencesProvider).hapticsEnabled;
  return HapticService._(enabled);
});
