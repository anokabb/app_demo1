import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/src/core/extensions/context_extension.dart';
import 'package:flutter_app_template/src/core/services/locator/locator.dart';
import 'package:flutter_app_template/src/core/services/purchases/revenue_cat_service.dart';
import 'package:flutter_app_template/src/core/services/purchases/subscription_cubit.dart';
import 'package:flutter_app_template/src/core/services/remote_config/remote_config_service.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/create/presentation/views/create_view.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class PaywallPage extends StatefulWidget {
  static const routeName = '/paywall';
  final PaywallOffers paywallOffer;

  const PaywallPage({super.key, required this.paywallOffer});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  /// Upper bound on how long we'll wait for RevenueCat's offerings before
  /// giving up — without it a bad connection leaves the user on a spinner they
  /// cannot dismiss.
  static const _offeringsTimeout = Duration(seconds: 12);

  Offering? _offering;
  bool _isLoading = true;
  String? _error;
  bool _closeIsLoading = true;
  // Blocks the iOS edge-swipe-back gesture (and hardware/system back) so the
  // paywall can only be dismissed via the explicit close button above, which
  // itself is gated by [_closeIsLoading]. It is force-released once loading
  // finishes/fails so the user can never get trapped here.
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _loadOffering();
    // The close button only becomes tappable after a remote-config-defined
    // delay, nudging users to actually look at the offer before dismissing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(
        Duration(seconds: kDebugMode ? 0 : locator<RemoteConfigService>().data.revenueCat.closeButtonDelay),
        () {
          if (mounted) setState(() => _closeIsLoading = false);
        },
      );
    });
  }

  Future<void> _loadOffering() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final offerings = await Purchases.getOfferings().timeout(_offeringsTimeout);
      final offering = offerings.all[widget.paywallOffer.name];
      if (!mounted) return;
      setState(() {
        _offering = offering;
        _isLoading = false;
        if (offering == null) _error = 'This offer is not available right now.';
      });
    } catch (e) {
      log('Error loading paywall offering: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// The restore callback fires even when nothing was restored (documented
  /// plugin behaviour), so only claim success when an entitlement is actually
  /// active — otherwise tell the user we found nothing.
  void _onRestoreCompleted(CustomerInfo customerInfo) {
    final restored = SubscriptionCubit.hasActiveEntitlement(customerInfo);
    locator<SubscriptionCubit>().checkSubscriptionStatus();

    if (restored) {
      showTopAlert('Your purchases have been restored');
      _onDismiss();
    } else {
      showTopAlert('No previous purchases were found for this account.', isError: true);
    }
  }

  void _onRestoreError(PurchasesError error) {
    log('Paywall restore error: ${error.message}');
    showTopAlert("Couldn't restore purchases: ${error.message}", isError: true);
  }

  void _onPurchaseError(PurchasesError error) {
    log('Paywall purchase error: ${error.message}');
    showTopAlert("Purchase didn't go through: ${error.message}", isError: true);
  }

  void _onPurchaseCancelled() {
    log('Paywall purchase cancelled by user');
    showTopAlert('Purchase cancelled.');
  }

  void _onPurchaseCompleted(CustomerInfo customerInfo, StoreTransaction transaction) {
    locator<SubscriptionCubit>().checkSubscriptionStatus();
  }

  void _onDismiss() {
    locator<SubscriptionCubit>().checkSubscriptionStatus();
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(CreateView.routeName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // While loading, or once loading failed, there is nothing to sell — never
      // trap the user behind a blocked back gesture in those states.
      canPop: _allowPop || _isLoading || _error != null || _offering == null,
      child: _buildBody(),
    );
  }

  /// Always-available escape hatch used by the loading and error states.
  Widget _closeButton() => Positioned(
        top: 16,
        right: 16,
        child: SafeArea(
          child: IconButton(
            onPressed: _onDismiss,
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
        ),
      );

  Widget _buildBody() {
    if (_isLoading) {
      return Scaffold(
        body: Stack(
          children: [
            const Center(child: CircularProgressIndicator()),
            _closeButton(),
          ],
        ),
      );
    }

    if (_error != null || _offering == null) {
      return Scaffold(
        body: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Something went wrong loading the paywall.', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(onPressed: _loadOffering, child: const Text('Try again')),
                        const SizedBox(width: 8),
                        TextButton(onPressed: _onDismiss, child: const Text('Close')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _closeButton(),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          PaywallView(
            offering: _offering,
            onRestoreCompleted: _onRestoreCompleted,
            onRestoreError: _onRestoreError,
            onPurchaseCompleted: _onPurchaseCompleted,
            onPurchaseError: _onPurchaseError,
            onPurchaseCancelled: _onPurchaseCancelled,
            onDismiss: _onDismiss,
          ),
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: _closeIsLoading
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : GestureDetector(
                      onTap: _onDismiss,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
