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

  // Check if user has premium access
  bool get hasPremiumAccess {
    if (_customerInfo == null) return false;
    return _customerInfo!.activeSubscriptions.isNotEmpty;
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

      // Load customer info
      _customerInfo = await Purchases.getCustomerInfo();

      _logger.i('RevenueCat initialized successfully');
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize RevenueCat: $e', error: e, stackTrace: stackTrace);
      rethrow;
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
      Offerings offerings = await Purchases.getOfferings();

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
