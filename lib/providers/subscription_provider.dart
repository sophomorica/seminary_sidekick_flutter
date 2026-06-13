import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/app_config.dart';
import 'dev_mode_provider.dart';

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
    price: '\$4.99/mo',
    pricePerMonth: '\$4.99',
    savings: null,
  ),
  yearly(
    id: 'seminary_sidekick_yearly',
    label: 'Yearly',
    price: '\$34.99/yr',
    pricePerMonth: '\$2.92',
    savings: 'Save 42%',
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

  /// Localized store prices keyed by [PremiumPlan.id], loaded from
  /// RevenueCat offerings. Empty until offerings are fetched; the UI should
  /// fall back to the hardcoded [PremiumPlan.price] via [priceFor].
  final Map<String, String> livePrices;

  const SubscriptionState({
    this.tier = SubscriptionTier.free,
    this.activePlan,
    this.expiresAt,
    this.isLoading = false,
    this.error,
    this.promptDismissals = 0,
    this.lastPromptShown,
    this.livePrices = const {},
  });

  bool get isPremium => tier.isPremium;
  bool get isFree => tier.isFree;

  /// Localized store price for [plan] if RevenueCat offerings have loaded,
  /// otherwise the hardcoded fallback from the enum. Apple/Google require we
  /// display the real localized price, so prefer the live value when present.
  String priceFor(PremiumPlan plan) => livePrices[plan.id] ?? plan.price;

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
    Map<String, String>? livePrices,
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
      livePrices: livePrices ?? this.livePrices,
    );
  }
}

/// Manages subscription state with Hive persistence and RevenueCat integration.
///
/// Provides the full subscription state management layer with graceful
/// free-tier fallbacks. Every RevenueCat call is guarded by [_isConfigured]
/// and wrapped in try/catch, so the app works perfectly without a network
/// connection or before RevenueCat is configured (e.g. no API key dart-define).
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  static const String _boxName = 'subscription';
  static const String _tierKey = 'tier';
  static const String _planKey = 'plan';
  static const String _expiryKey = 'expiry';
  static const String _dismissalsKey = 'dismissals';
  static const String _lastPromptKey = 'lastPrompt';

  /// RevenueCat entitlement identifier that unlocks premium. This MUST match
  /// the entitlement created in the RevenueCat dashboard (see
  /// REVENUECAT_SETUP.md). All premium gating keys off this entitlement, not
  /// off individual product IDs.
  static const String premiumEntitlementId = 'premium';

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
  ///
  /// Flow: fetch the current offering → find the package matching [plan] →
  /// `purchasePackage` → unlock premium iff the `premium` entitlement is now
  /// active. Returns `true` only when premium is actually granted. A user
  /// cancelling the native sheet is treated as a non-error (`false`, no error
  /// message).
  Future<bool> purchasePlan(PremiumPlan plan) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      if (!await _isConfigured()) {
        state = state.copyWith(
          isLoading: false,
          error: 'Purchases aren\'t available right now. Please try again later.',
        );
        return false;
      }

      final offerings = await Purchases.getOfferings();
      final package = _packageForPlan(offerings, plan);
      if (package == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'That plan isn\'t available right now. Please try again later.',
        );
        return false;
      }

      final customerInfo = await Purchases.purchasePackage(package);
      final isPremium = _isEntitled(customerInfo);

      state = state.copyWith(
        tier: isPremium ? SubscriptionTier.premium : SubscriptionTier.free,
        activePlan: isPremium ? (_planFrom(customerInfo) ?? plan) : null,
        clearPlan: !isPremium,
        expiresAt: isPremium ? _expiryFrom(customerInfo) : null,
        clearExpiry: !isPremium,
        isLoading: false,
      );
      await _persist();
      return isPremium;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        // User backed out of the native purchase sheet — not an error.
        state = state.copyWith(isLoading: false);
        return false;
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Purchase failed. Please try again.',
      );
      return false;
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
      if (!await _isConfigured()) {
        state = state.copyWith(isLoading: false);
        return;
      }
      final customerInfo = await Purchases.restorePurchases();
      _applyCustomerInfo(customerInfo);
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

  /// Background sync with RevenueCat to verify subscription status and load
  /// localized offering prices. Called on launch (non-blocking). Reconciles
  /// local state with the source of truth (the `premium` entitlement) so a
  /// subscription bought on another device, or one that expired while the app
  /// was closed, is reflected correctly.
  Future<void> _syncWithRevenueCat() async {
    try {
      if (!await _isConfigured()) return;
      final customerInfo = await Purchases.getCustomerInfo();
      _applyCustomerInfo(customerInfo);
      await _persist();
      await _loadOfferings();
    } catch (_) {
      // Silent failure — free tier fallback is always safe.
    }
  }

  /// Fetch the current offering and cache localized store prices so the
  /// upgrade screen can show the real price the user will be charged.
  Future<void> _loadOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current == null) return;
      final prices = <String, String>{};
      for (final plan in PremiumPlan.values) {
        final pkg = _packageForPlan(offerings, plan);
        if (pkg != null) prices[plan.id] = pkg.storeProduct.priceString;
      }
      if (prices.isNotEmpty) {
        state = state.copyWith(livePrices: prices);
      }
    } catch (_) {
      // Non-fatal — the UI falls back to hardcoded prices.
    }
  }

  /// Reconcile local subscription state with a [CustomerInfo] snapshot.
  void _applyCustomerInfo(CustomerInfo info) {
    if (_isEntitled(info)) {
      state = state.copyWith(
        tier: SubscriptionTier.premium,
        activePlan: _planFrom(info) ?? state.activePlan,
        expiresAt: _expiryFrom(info),
      );
    } else {
      state = state.copyWith(
        tier: SubscriptionTier.free,
        clearPlan: true,
        clearExpiry: true,
      );
    }
  }

  /// Whether the RevenueCat SDK has been configured (API key provided at
  /// launch). When false, every RevenueCat call is skipped and the app stays
  /// on the free tier. `await` is safe whether the getter returns a bool or a
  /// Future<bool>.
  Future<bool> _isConfigured() async {
    try {
      return await Purchases.isConfigured;
    } catch (_) {
      return false;
    }
  }

  /// True if the `premium` entitlement is active in [info].
  bool _isEntitled(CustomerInfo info) =>
      info.entitlements.all[premiumEntitlementId]?.isActive ?? false;

  /// Expiration date of the active `premium` entitlement, if any.
  DateTime? _expiryFrom(CustomerInfo info) {
    final iso = info.entitlements.all[premiumEntitlementId]?.expirationDate;
    return iso == null ? null : DateTime.tryParse(iso);
  }

  /// Map the active entitlement's product back to a [PremiumPlan] so we can
  /// show the user which plan they're on. Android product IDs may carry a
  /// base-plan suffix, so we match by prefix as well as exact id.
  PremiumPlan? _planFrom(CustomerInfo info) {
    final entitlement = info.entitlements.all[premiumEntitlementId];
    if (entitlement == null || !entitlement.isActive) return null;
    final productId = entitlement.productIdentifier;
    for (final plan in PremiumPlan.values) {
      if (productId == plan.id || productId.startsWith(plan.id)) return plan;
    }
    return null;
  }

  /// Find the offering package corresponding to [plan]. Matches by product
  /// identifier first, then falls back to RevenueCat's standard package types
  /// (monthly / annual) so this keeps working if product IDs are renamed.
  Package? _packageForPlan(Offerings offerings, PremiumPlan plan) {
    final offering = offerings.current;
    if (offering == null) return null;
    for (final pkg in offering.availablePackages) {
      final id = pkg.storeProduct.identifier;
      if (id == plan.id || id.startsWith(plan.id)) return pkg;
    }
    switch (plan) {
      case PremiumPlan.monthly:
        return offering.monthly;
      case PremiumPlan.yearly:
        return offering.annual;
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
///
/// Resolution order:
///   1. Dev Menu runtime override (debug only, highest priority)
///   2. [AppConfig.forcePremium] static flag (debug only)
///   3. Real subscription state from RevenueCat (always used in release)
final isPremiumProvider = Provider<bool>((ref) {
  if (AppConfig.isDevModeActive) {
    // Runtime override from Dev Menu takes priority
    final override = ref.watch(devModeOverrideProvider);
    if (override != null) return override;
    // Fall back to static config default
    return AppConfig.forcePremium;
  }
  // Release mode: always use real subscription
  return ref.watch(subscriptionProvider).isPremium;
});

/// Convenience: can we show an upgrade prompt right now?
final canShowUpgradePromptProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionProvider).canShowUpgradePrompt;
});
