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
  Offering? _offering;
  bool _isLoading = true;
  String? _error;
  bool _closeIsLoading = true;

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
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.all[widget.paywallOffer.name];
      if (!mounted) return;
      setState(() {
        _offering = offering;
        _isLoading = false;
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

  void _onRestoreCompleted(CustomerInfo customerInfo) {
    locator<SubscriptionCubit>().checkSubscriptionStatus();
    showTopAlert('Your purchases have been restored');
  }

  void _onDismiss() {
    locator<SubscriptionCubit>().checkSubscriptionStatus();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(CreateView.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _offering == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Something went wrong loading the paywall.', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TextButton(onPressed: _onDismiss, child: const Text('Close')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          PaywallView(
            offering: _offering,
            onRestoreCompleted: _onRestoreCompleted,
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
