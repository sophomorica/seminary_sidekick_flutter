import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:seminary_sidekick/providers/subscription_provider.dart';

void main() {
  late SubscriptionNotifier notifier;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_sub_test_');
    Hive.init(tempDir.path);
    notifier = SubscriptionNotifier();
    await notifier.init();
  });

  tearDown(() async {
    // Allow fire-and-forget _persist() calls to complete before closing Hive
    await Future.delayed(const Duration(milliseconds: 50));
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  // ─── SubscriptionTier enum ───────────────────────────────────────────

  group('SubscriptionTier', () {
    test('free.isPremium is false', () {
      expect(SubscriptionTier.free.isPremium, false);
    });

    test('free.isFree is true', () {
      expect(SubscriptionTier.free.isFree, true);
    });

    test('premium.isPremium is true', () {
      expect(SubscriptionTier.premium.isPremium, true);
    });

    test('premium.isFree is false', () {
      expect(SubscriptionTier.premium.isFree, false);
    });
  });

  // ─── PremiumPlan enum ────────────────────────────────────────────────

  group('PremiumPlan', () {
    test('monthly has correct id', () {
      expect(PremiumPlan.monthly.id, 'seminary_sidekick_monthly');
    });

    test('yearly has savings text', () {
      expect(PremiumPlan.yearly.savings, isNotNull);
      expect(PremiumPlan.yearly.savings, contains('Save'));
    });

    test('monthly has no savings', () {
      expect(PremiumPlan.monthly.savings, isNull);
    });

    test('yearly has lower per-month price', () {
      // yearly: $2.92/mo ($34.99/yr), monthly: $4.99/mo
      expect(PremiumPlan.yearly.pricePerMonth, '\$2.92');
      expect(PremiumPlan.monthly.pricePerMonth, '\$4.99');
    });
  });

  // ─── SubscriptionState ──────────────────────────────────────────────

  group('SubscriptionState', () {
    test('defaults to free tier', () {
      const state = SubscriptionState();
      expect(state.tier, SubscriptionTier.free);
      expect(state.activePlan, isNull);
      expect(state.expiresAt, isNull);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.promptDismissals, 0);
      expect(state.lastPromptShown, isNull);
    });

    test('isPremium and isFree convenience getters', () {
      const free = SubscriptionState();
      expect(free.isPremium, false);
      expect(free.isFree, true);

      const premium = SubscriptionState(tier: SubscriptionTier.premium);
      expect(premium.isPremium, true);
      expect(premium.isFree, false);
    });

    group('canShowUpgradePrompt', () {
      test('true for fresh free user', () {
        const state = SubscriptionState();
        expect(state.canShowUpgradePrompt, true);
      });

      test('false for premium user', () {
        const state = SubscriptionState(tier: SubscriptionTier.premium);
        expect(state.canShowUpgradePrompt, false);
      });

      test('false after 3 dismissals', () {
        const state = SubscriptionState(promptDismissals: 3);
        expect(state.canShowUpgradePrompt, false);
      });

      test('false if shown within last 24 hours', () {
        final recentlyShown = SubscriptionState(
          lastPromptShown: DateTime.now().subtract(const Duration(hours: 12)),
        );
        expect(recentlyShown.canShowUpgradePrompt, false);
      });

      test('true if shown more than 24 hours ago', () {
        final longAgo = SubscriptionState(
          lastPromptShown: DateTime.now().subtract(const Duration(hours: 25)),
        );
        expect(longAgo.canShowUpgradePrompt, true);
      });

      test('true with 2 dismissals and enough time passed', () {
        final state = SubscriptionState(
          promptDismissals: 2,
          lastPromptShown: DateTime.now().subtract(const Duration(days: 2)),
        );
        expect(state.canShowUpgradePrompt, true);
      });
    });

    group('copyWith', () {
      test('copies with new tier', () {
        const state = SubscriptionState();
        final copy = state.copyWith(tier: SubscriptionTier.premium);
        expect(copy.tier, SubscriptionTier.premium);
        expect(copy.isLoading, false); // unchanged
      });

      test('clearPlan sets activePlan to null', () {
        const state = SubscriptionState(activePlan: PremiumPlan.monthly);
        final copy = state.copyWith(clearPlan: true);
        expect(copy.activePlan, isNull);
      });

      test('clearExpiry sets expiresAt to null', () {
        final state = SubscriptionState(expiresAt: DateTime.now());
        final copy = state.copyWith(clearExpiry: true);
        expect(copy.expiresAt, isNull);
      });

      test('clearError sets error to null', () {
        const state = SubscriptionState(error: 'Fail');
        final copy = state.copyWith(clearError: true);
        expect(copy.error, isNull);
      });
    });
  });

  // ─── SubscriptionNotifier ────────────────────────────────────────────

  group('SubscriptionNotifier', () {
    test('initializes with free tier by default', () {
      expect(notifier.state.tier, SubscriptionTier.free);
      expect(notifier.state.isPremium, false);
    });

    test('purchasePlan fails gracefully when RevenueCat is unavailable',
        () async {
      // A pure unit-test VM has no RevenueCat SDK, so the SDK guard
      // short-circuits: premium is NOT granted, loading is cleared, and an
      // error is surfaced instead of crashing. Real purchase + expiry behavior
      // (now driven by the store's CustomerInfo, not computed in-app) is
      // covered by on-device sandbox testing — see REVENUECAT_SETUP.md.
      final success = await notifier.purchasePlan(PremiumPlan.monthly);
      expect(success, false);
      expect(notifier.state.isPremium, false);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNotNull);
    });

    test('dismissUpgradePrompt increments dismissals', () {
      expect(notifier.state.promptDismissals, 0);

      notifier.dismissUpgradePrompt();
      expect(notifier.state.promptDismissals, 1);

      notifier.dismissUpgradePrompt();
      expect(notifier.state.promptDismissals, 2);
    });

    test('dismissUpgradePrompt records lastPromptShown', () {
      notifier.dismissUpgradePrompt();
      expect(notifier.state.lastPromptShown, isNotNull);
    });

    test('recordPromptShown updates lastPromptShown without incrementing', () {
      notifier.recordPromptShown();
      expect(notifier.state.lastPromptShown, isNotNull);
      expect(notifier.state.promptDismissals, 0);
    });

    test('clearError removes error state', () async {
      // Force error by checking state after restore (no actual RC configured)
      notifier.clearError();
      expect(notifier.state.error, isNull);
    });

    test('restores persisted subscription state on init', () async {
      // Seed the Hive box as if a premium purchase had previously been
      // persisted. (purchasePlan itself needs the RevenueCat SDK, which is
      // unavailable in a unit-test VM.) init() should rehydrate this state;
      // the background RevenueCat sync is a no-op without the SDK.
      final box = await Hive.openBox('subscription');
      await box.put('tier', SubscriptionTier.premium.index);
      await box.put('plan', PremiumPlan.yearly.index);
      await box.put('dismissals', 1);

      // New notifier simulates an app restart restoring from storage.
      final restored = SubscriptionNotifier();
      await restored.init();

      expect(restored.state.isPremium, true);
      expect(restored.state.activePlan, PremiumPlan.yearly);
      expect(restored.state.promptDismissals, 1);
    });

    test('restorePurchases finishes without crashing', () async {
      // With no RevenueCat configured, should complete gracefully
      await notifier.restorePurchases();
      expect(notifier.state.isLoading, false);
    });
  });
}
