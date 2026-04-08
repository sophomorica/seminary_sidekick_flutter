import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Subscription tier for the app.
enum SubscriptionTier {
  free,
  premium;

  bool get isPremium => this == SubscriptionTier.premium;
  bool get isFree => this == SubscriptionTier.free;
}

/// Available premium plan options.
enum PremiumPlan {
  monthly(
    id: 'seminary_sidekick_monthly',
    label: 'Monthly',
    price: '\$2.99/mo',
    pricePerMonth: '\$2.99',
    savings: null,
  ),
  yearly(
    id: 'seminary_sidekick_yearly',
    label: 'Yearly',
    price: '\$19.99/yr',
    pricePerMonth: '\$1.67',
    savings: 'Save 44%',
  );

  const PremiumPlan({
    required this.id,
    required this.label,
    required this.price,
    required this.pricePerMonth,
    required this.savings,
  });

  final String id;
  final String label;
  final String price;
  final String pricePerMonth;
  final String? savings;
}

/// Immutable subscription state.
class SubscriptionState {
  final SubscriptionTier tier;
  final PremiumPlan? activePlan;
  final DateTime? expiresAt;
  final bool isLoading;
  final String? error;

  /// How many times the user has dismissed an upgrade prompt (for rate limiting).
  final int promptDismissals;

  /// Last time an upgrade prompt was shown.
  final DateTime? lastPromptShown;

  const SubscriptionState({
    this.tier = SubscriptionTier.free,
    this.activePlan,
    this.expiresAt,
    this.isLoading = false,
    this.error,
    this.promptDismissals = 0,
    this.lastPromptShown,
  });

  bool get isPremium => tier.isPremium;
  bool get isFree => tier.isFree;

  /// Whether it's appropriate to show an upgrade prompt right now.
  /// Rate-limited: max 1 per session day, max 3 dismissals before backing off.
  bool get canShowUpgradePrompt {
    if (isPremium) return false;
    if (promptDismissals >= 3) return false;
    if (lastPromptShown != null) {
      final now = DateTime.now();
      final diff = now.difference(lastPromptShown!);
      // Don't show more than once per 24 hours
      if (diff.inHours < 24) return false;
    }
    return true;
  }

  SubscriptionState copyWith({
    SubscriptionTier? tier,
    PremiumPlan? activePlan,
    DateTime? expiresAt,
    bool? isLoading,
    String? error,
    int? promptDismissals,
    DateTime? lastPromptShown,
    bool clearPlan = false,
    bool clearExpiry = false,
    bool clearError = false,
  }) {
    return SubscriptionState(
      tier: tier ?? this.tier,
      activePlan: clearPlan ? null : (activePlan ?? this.activePlan),
      expiresAt: clearExpiry ? null : (expiresAt ?? this.expiresAt),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      promptDismissals: promptDismissals ?? this.promptDismissals,
      lastPromptShown: lastPromptShown ?? this.lastPromptShown,
    );
  }
}

/// Manages subscription state with Hive persistence and RevenueCat integration.
///
/// For the MVP, this provides the full subscription state management layer
/// with graceful free-tier fallbacks. RevenueCat calls are wrapped so the app
/// works perfectly without a network connection or before RC is configured.
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  static const String _boxName = 'subscription';
  static const String _tierKey = 'tier';
  static const String _planKey = 'plan';
  static const String _expiryKey = 'expiry';
  static const String _dismissalsKey = 'dismissals';
  static const String _lastPromptKey = 'lastPrompt';

  SubscriptionNotifier() : super(const SubscriptionState());

  /// Initialize from Hive and then sync with RevenueCat.
  Future<void> init() async {
    final box = await Hive.openBox(_boxName);

    // Restore persisted state
    final tierIndex = box.get(_tierKey, defaultValue: 0) as int;
    final planIndex = box.get(_planKey) as int?;
    final expiryMs = box.get(_expiryKey) as int?;
    final dismissals = box.get(_dismissalsKey, defaultValue: 0) as int;
    final lastPromptMs = box.get(_lastPromptKey) as int?;

    state = SubscriptionState(
      tier: SubscriptionTier.values[tierIndex.clamp(0, 1)],
      activePlan: planIndex != null
          ? PremiumPlan.values[planIndex.clamp(0, 1)]
          : null,
      expiresAt: expiryMs != null
          ? DateTime.fromMillisecondsSinceEpoch(expiryMs)
          : null,
      promptDismissals: dismissals,
      lastPromptShown: lastPromptMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastPromptMs)
          : null,
    );

    // Sync with RevenueCat in the background (non-blocking)
    _syncWithRevenueCat();
  }

  /// Attempt to purchase a premium plan via RevenueCat.
  Future<bool> purchasePlan(PremiumPlan plan) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // TODO: Replace with actual RevenueCat purchase call:
      // final customerInfo = await Purchases.purchasePackage(package);
      // For now, this is the integration point. The purchase flow will be:
      //
      // 1. Purchases.getOfferings() → get available packages
      // 2. Purchases.purchasePackage(package) → complete purchase
      // 3. Check customerInfo.entitlements.all['premium']?.isActive
      //
      // The stub below simulates a successful purchase for development:
      await Future.delayed(const Duration(milliseconds: 500));

      // On successful purchase:
      state = state.copyWith(
        tier: SubscriptionTier.premium,
        activePlan: plan,
        expiresAt: plan == PremiumPlan.yearly
            ? DateTime.now().add(const Duration(days: 365))
            : DateTime.now().add(const Duration(days: 30)),
        isLoading: false,
      );

      await _persist();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Purchase failed. Please try again.',
      );
      return false;
    }
  }

  /// Restore purchases (e.g., after reinstall or new device).
  Future<void> restorePurchases() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // TODO: Replace with actual RevenueCat restore:
      // final customerInfo = await Purchases.restorePurchases();
      // Check customerInfo.entitlements.all['premium']?.isActive
      await Future.delayed(const Duration(milliseconds: 500));

      // If no active subscription found after restore:
      state = state.copyWith(isLoading: false);
      await _persist();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not restore purchases. Please try again.',
      );
    }
  }

  /// Record that the user dismissed an upgrade prompt.
  void dismissUpgradePrompt() {
    state = state.copyWith(
      promptDismissals: state.promptDismissals + 1,
      lastPromptShown: DateTime.now(),
    );
    _persist();
  }

  /// Record that an upgrade prompt was shown (without dismissal).
  void recordPromptShown() {
    state = state.copyWith(lastPromptShown: DateTime.now());
    _persist();
  }

  /// Clear any error state.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Background sync with RevenueCat to verify subscription status.
  Future<void> _syncWithRevenueCat() async {
    try {
      // TODO: Replace with actual RevenueCat sync:
      // final customerInfo = await Purchases.getCustomerInfo();
      // final isPremium = customerInfo.entitlements.all['premium']?.isActive ?? false;
      //
      // if (isPremium && state.isFree) {
      //   state = state.copyWith(tier: SubscriptionTier.premium);
      //   await _persist();
      // } else if (!isPremium && state.isPremium) {
      //   // Subscription expired
      //   state = state.copyWith(
      //     tier: SubscriptionTier.free,
      //     clearPlan: true,
      //     clearExpiry: true,
      //   );
      //   await _persist();
      // }
    } catch (_) {
      // Silent failure — free tier fallback is always safe
    }
  }

  Future<void> _persist() async {
    final box = Hive.box(_boxName);
    await box.put(_tierKey, state.tier.index);
    if (state.activePlan != null) {
      await box.put(_planKey, state.activePlan!.index);
    } else {
      await box.delete(_planKey);
    }
    if (state.expiresAt != null) {
      await box.put(_expiryKey, state.expiresAt!.millisecondsSinceEpoch);
    } else {
      await box.delete(_expiryKey);
    }
    await box.put(_dismissalsKey, state.promptDismissals);
    if (state.lastPromptShown != null) {
      await box.put(
        _lastPromptKey,
        state.lastPromptShown!.millisecondsSinceEpoch,
      );
    }
  }
}

// ─── Providers ──────────────────────────────────────────────────────────────

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>(
  (ref) => SubscriptionNotifier(),
);

/// Convenience: is the user currently premium?
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionProvider).isPremium;
});

/// Convenience: can we show an upgrade prompt right now?
final canShowUpgradePromptProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionProvider).canShowUpgradePrompt;
});
