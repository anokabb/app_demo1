import 'package:flutter/widgets.dart';
import 'package:flutter_app_template/src/core/constants/hive_config.dart';
import 'package:flutter_app_template/src/core/routing/app_router.dart';
import 'package:flutter_app_template/src/core/services/logger/logger.dart';
import 'package:flutter_app_template/src/core/services/purchases/revenue_cat_service.dart';
import 'package:flutter_app_template/src/core/services/remote_config/models/remote_config_models.dart';
import 'package:flutter_app_template/src/core/services/remote_config/remote_config_service.dart';
import 'package:flutter_app_template/src/features/paywall/presentation/views/paywall_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

part 'subscription_state.dart';

class SubscriptionCubit extends Cubit<SubscriptionState> with WidgetsBindingObserver {
  final RemoteConfigService _remoteConfigService;
  final _logger = getLogger('SubscriptionCubit');

  // Usage tracking key
  static const String _freeLimitKey = RemoteConfigKeys.freeLimit;

  SubscriptionCubit(this._remoteConfigService) : super(const SubscriptionState.initial()) {
    _initializeUsageTracking();
    // Re-check entitlements whenever the app comes back to the foreground —
    // a purchase/renewal made outside the app (or a lapsed grace period) would
    // otherwise leave the user on a stale, wrong subscription state.
    WidgetsBinding.instance.addObserver(this);
    // RevenueCat pushes customer info whenever it changes (purchase, renewal,
    // restore, billing issue resolved, promotional entitlement granted…).
    Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
  }

  /// Initialize usage tracking and reset if needed
  void _initializeUsageTracking() {
    _updateUsageState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkSubscriptionStatus();
    }
  }

  /// A user counts as a subscriber when ANY entitlement is active — this covers
  /// lifetime/non-consumable purchases, promotional grants and grace periods,
  /// none of which appear in `activeSubscriptions`.
  static bool hasActiveEntitlement(CustomerInfo? info) => info != null && info.entitlements.active.isNotEmpty;

  void _onCustomerInfoUpdated(CustomerInfo customerInfo) {
    if (isClosed) return;
    // The dev override wins so the pro experience can still be forced locally.
    final isDevPro = devBox.get('isDevPro', defaultValue: false) as bool;
    final isSubscriber = isDevPro || hasActiveEntitlement(customerInfo);

    _logger.i('CustomerInfo update pushed by RevenueCat: isSubscriber = $isSubscriber');
    emit(state.copyWith(
      isLoading: false,
      isSubscriber: isSubscriber,
      customerInfo: customerInfo,
      error: null,
    ));
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    Purchases.removeCustomerInfoUpdateListener(_onCustomerInfoUpdated);
    return super.close();
  }

  /// Update state with current usage
  void _updateUsageState() {
    final usage = purchasesBox.get(_freeLimitKey, defaultValue: 0) as int;

    emit(state.copyWith(freeLimit: usage));
  }

  /// Check if discount paywall should be shown based on app version
  /// Returns true if discount should be shown, false if it should be hidden
  Future<bool> _shouldShowDiscountPaywall() async {
    try {
      final config = _remoteConfigService.data.revenueCat;

      // If showDiscountAfterPaywall is false, don't show it
      if (!config.showDiscountAfterPaywall) return false;

      // If hideDiscountPaywallForVersion is empty, show the discount
      if (config.hideDiscountPaywallForVersion.trim().isEmpty) return true;

      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Check if current version exactly matches the version to hide
      final shouldHide = currentVersion == config.hideDiscountPaywallForVersion;

      _logger.i(
          'Current version: $currentVersion, Hide for version: ${config.hideDiscountPaywallForVersion}, Should hide: $shouldHide');

      return !shouldHide;
    } catch (e) {
      _logger.e('Error checking discount paywall eligibility: $e');
      // If error occurs, default to showing the discount
      return _remoteConfigService.data.revenueCat.showDiscountAfterPaywall;
    }
  }

  /// Check subscription status
  Future<void> checkSubscriptionStatus() async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      if (devBox.get('isDevPro', defaultValue: false)) {
        emit(state.copyWith(isLoading: false, isSubscriber: true));
        return;
      }

      // Get customer info from RevenueCat
      final customerInfo = await Purchases.getCustomerInfo();

      // Entitlements (not activeSubscriptions) are the source of truth — they
      // also cover lifetime, promotional and grace-period access.
      final isSubscriber = hasActiveEntitlement(customerInfo);

      emit(state.copyWith(
        isLoading: false,
        isSubscriber: isSubscriber,
        customerInfo: customerInfo,
      ));

      _logger.i('Subscription status checked: isSubscriber = $isSubscriber');
    } catch (e, stackTrace) {
      _logger.e('Failed to check subscription status: $e', error: e, stackTrace: stackTrace);

      // NOTE: deliberately does NOT touch `isSubscriber`. A network blip while
      // checking must never silently downgrade a known subscriber — we keep the
      // last known good value and try again on the next resume/update push.
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Push the routed paywall page and re-check status after
  Future<void> showPaywall(PaywallOffers paywallOffer) async {
    if (state.isSubscriber) return;
    try {
      emit(state.copyWith(isLoading: true, error: null));

      final context = rootNavigatorKey.currentContext;
      if (context != null) {
        await context.push(PaywallPage.routeName, extra: paywallOffer);
        await checkSubscriptionStatus();

        // If user is not subscriber and paywall offer is not second offer, check if discount should be shown
        if (!state.isSubscriber && paywallOffer != PaywallOffers.second_offer && await _shouldShowDiscountPaywall()) {
          await showPaywall(PaywallOffers.second_offer);
        }
      } else {
        _logger.e('No context available for navigation');
        emit(state.copyWith(isLoading: false, error: 'Navigation context not available'));
      }
    } catch (e) {
      _logger.e('Failed to present paywall: $e');
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> showAppOpenPaywall() async {
    if (state.isSubscriber) return;

    bool isFirstAppOpen = purchasesBox.get('is_first_app_open', defaultValue: true);

    if (isFirstAppOpen) {
      await showPaywall(PaywallOffers.first_offer);
      purchasesBox.put('is_first_app_open', false);
    } else {
      // Returning users also get `first_offer`. `second_offer` is the
      // "One Time Offer / you won't see this offer again" template — showing it
      // on every app open makes that copy false and is an App Store risk. It
      // stays reserved for the one-shot discount follow-up in [showPaywall].
      await showPaywall(PaywallOffers.first_offer);
    }
  }

  /// Remaining free-tier actions before the paywall kicks in (clamped to >= 0).
  int get remainingFreeActions {
    final limit = _remoteConfigService.data.revenueCat.freeLimit;
    final remaining = limit - state.freeLimit;
    return remaining < 0 ? 0 : remaining;
  }

  /// DEV ONLY — force the subscriber flag on/off so the pro experience can be
  /// tested without a real purchase. Persisted so it survives a restart.
  Future<void> setDevPro(bool isPro) async {
    await devBox.put('isDevPro', isPro);
    emit(state.copyWith(isSubscriber: isPro));
    _logger.i('Dev pro override set to $isPro');
  }

  /// DEV ONLY — reset the consumed free-tier usage back to zero.
  void resetFreeUsage() {
    purchasesBox.put(_freeLimitKey, 0);
    emit(state.copyWith(freeLimit: 0));
    _logger.i('Free-tier usage reset to 0');
  }

  /// Permission check ONLY — does not consume anything. Returns false (and
  /// shows the paywall) once the remote-config-defined free limit is reached.
  ///
  /// Callers must pair this with [consumeFreeAction] *after* the action has
  /// actually succeeded, so a failed request never burns a credit.
  Future<bool> canUseFreeAction() async {
    if (state.isSubscriber) return true; // Subscribers have unlimited usage

    final currentUsage = state.freeLimit;
    final limit = _remoteConfigService.data.revenueCat.freeLimit;

    if (currentUsage >= limit) {
      showPaywall(PaywallOffers.first_offer);
      return false; // Limit reached
    }

    return true;
  }

  /// Consume one free-tier credit. Call this only once the gated action has
  /// produced a real result. No-op for subscribers.
  Future<void> consumeFreeAction() async {
    if (state.isSubscriber) return;

    final limit = _remoteConfigService.data.revenueCat.freeLimit;
    final newUsage = state.freeLimit + 1;
    await purchasesBox.put(_freeLimitKey, newUsage);
    emit(state.copyWith(freeLimit: newUsage));

    _logger.i('Free-tier usage: $newUsage/$limit');
  }

  /// Give a consumed credit back — safety net for callers that consume up front
  /// and then fail. Clamped so usage can never go negative.
  Future<void> refundFreeAction() async {
    if (state.isSubscriber) return;

    final newUsage = state.freeLimit - 1;
    final clamped = newUsage < 0 ? 0 : newUsage;
    await purchasesBox.put(_freeLimitKey, clamped);
    emit(state.copyWith(freeLimit: clamped));

    _logger.i('Free-tier usage refunded, now $clamped');
  }
}
