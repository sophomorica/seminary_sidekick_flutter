import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Manages onboarding state — tracks whether the user has seen the
/// first-launch tutorial explaining the mastery path.
class OnboardingNotifier extends StateNotifier<bool> {
  static const _boxName = 'onboarding';
  static const _completedKey = 'onboarding_completed';

  OnboardingNotifier() : super(false);

  /// Load persisted onboarding state from Hive.
  Future<void> init() async {
    final box = await Hive.openBox(_boxName);
    state = box.get(_completedKey, defaultValue: false) as bool;
  }

  /// Whether the user has completed (or skipped) onboarding.
  bool get hasCompletedOnboarding => state;

  /// Mark onboarding as complete and persist.
  Future<void> completeOnboarding() async {
    final box = Hive.box(_boxName);
    await box.put(_completedKey, true);
    state = true;
  }

  /// Reset onboarding (for re-showing from help/settings).
  Future<void> resetOnboarding() async {
    final box = Hive.box(_boxName);
    await box.put(_completedKey, false);
    state = false;
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, bool>(
  (ref) => OnboardingNotifier(),
);
