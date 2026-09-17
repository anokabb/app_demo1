import 'dart:developer';

import 'package:flutter_app_template/src/core/services/logger/logger.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

enum PaywallOffers { first_offer, second_offer, third_offer }

class RevenueCatService {
  final _logger = getLogger('RevenueCatService');
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  CustomerInfo? _customerInfo;
  CustomerInfo? get customerInfo => _customerInfo;

  // Check if user has premium access.
  // Uses entitlements (not activeSubscriptions) so lifetime/non-consumable
  // purchases, promotional grants and grace periods all count as premium.
  bool get hasPremiumAccess {
    final info = _customerInfo;
    if (info == null) return false;
    return info.entitlements.active.isNotEmpty;
  }

  /// Initialize RevenueCat with API key
  Future<void> initialize({
    required String apiKey,
    String? appUserId,
  }) async {
    try {
      _logger.i('Initializing RevenueCat with API key');

      PurchasesConfiguration configuration = PurchasesConfiguration(apiKey);
      if (appUserId != null) {
        configuration.appUserID = appUserId;
      }

      await Purchases.configure(configuration);
      _isInitialized = true;

      // Keep the cached customer info fresh: RevenueCat pushes an update on
      // every purchase, renewal, restore or entitlement change, so we never sit
      // on a stale (silently downgraded) snapshot.
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

      // Load customer info
      _customerInfo = await Purchases.getCustomerInfo();

      _logger.i('RevenueCat initialized successfully');
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize RevenueCat: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  void _onCustomerInfoUpdated(CustomerInfo customerInfo) {
    _customerInfo = customerInfo;
    _logger.i('CustomerInfo updated — premium: ${customerInfo.entitlements.active.isNotEmpty}');
  }

  /// Force-refresh the cached customer info (e.g. on app resume). Never throws:
  /// a failed refresh keeps the last known good value rather than downgrading.
  Future<CustomerInfo?> refreshCustomerInfo() async {
    if (!_isInitialized) return _customerInfo;
    try {
      _customerInfo = await Purchases.getCustomerInfo();
      return _customerInfo;
    } catch (e) {
      _logger.e('Failed to refresh customer info: $e');
      return _customerInfo;
    }
  }

  Future<void> login(String userId) async {
    // TODO: maybe add this later
    // try {
    //   await Purchases.logIn(userId);
    //   _logger.i('Logged in to RevenueCat with user ID: $userId');
    // } catch (e) {
    //   _logger.e('Failed to log in to RevenueCat: $e');
    //   rethrow;
    // }
  }

  Future<void> logout() async {
    // TODO: maybe add this later
    // try {
    //   await Purchases.logOut();
    //   _logger.i('Logged out of RevenueCat');
    // } catch (e) {
    //   _logger.e('Failed to log out of RevenueCat: $e');
    //   rethrow;
    // }
  }

  Future<void> presentPaywallIfNeeded(PaywallOffers paywallOffer) async {
    try {
      // getOfferings can hang indefinitely on a bad connection — bound it so the
      // caller fails fast instead of leaving the user on a spinner.
      Offerings offerings = await Purchases.getOfferings().timeout(const Duration(seconds: 15));

      Offering? offering = offerings.all[paywallOffer.name];
      log('Offering: $offering');
      if (offering == null) {
        throw Exception('Offering not found');
      }

      final paywallResult = await RevenueCatUI.presentPaywall(offering: offering, displayCloseButton: true);
      log('Paywall result: $paywallResult');

      // Update customer info after paywall interaction
      _customerInfo = await Purchases.getCustomerInfo();
    } catch (e) {
      _logger.e('Paywall presentation failed: $e');
      rethrow;
    }
  }
}
