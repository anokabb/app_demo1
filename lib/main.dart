import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/firebase_options.dart';
import 'package:flutter_app_template/src/app.dart';
import 'package:flutter_app_template/src/core/constants/env_config.dart';
import 'package:flutter_app_template/src/core/constants/hive_config.dart';
import 'package:flutter_app_template/src/core/routing/app_router.dart';
import 'package:flutter_app_template/src/core/services/locator/locator.dart';
import 'package:flutter_app_template/src/core/services/purchases/revenue_cat_service.dart';
import 'package:flutter_app_template/src/core/services/purchases/subscription_cubit.dart';
import 'package:flutter_app_template/src/core/services/remote_config/remote_config_service.dart';

void main() {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Firebase must come first so Crashlytics can capture everything after it.
      final firebaseReady = await _guard(
        'Firebase.initializeApp',
        () => Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
      );

      if (firebaseReady) await _setupCrashlytics();

      await _guard('initHive', initHive);
      await _guard('EnvConfig.loadEnv', EnvConfig.loadEnv);

      setupLocator();
      await _guard('locator.allReady', locator.allReady);

      await _guard('RemoteConfigService.initialize', locator<RemoteConfigService>().initialize);
      await _guard('RemoteConfigService.fetchAndActivate', locator<RemoteConfigService>().fetchAndActivate);

      await _initializeRevenueCat();

      runApp(
        App(
          routerConfig: AppRouter().createRouter(),
        ),
      );
    },
    _reportError,
  );
}

/// Runs a bootstrap step, reporting (but never propagating) failures so the
/// app always reaches [runApp] instead of hanging on a black screen.
Future<bool> _guard(String step, Future<void> Function() action) async {
  try {
    await action();
    return true;
  } catch (e, stackTrace) {
    log('Bootstrap step "$step" failed: $e', stackTrace: stackTrace);
    _reportError(e, stackTrace, reason: 'Bootstrap step "$step" failed');
    return false;
  }
}

Future<void> _setupCrashlytics() async {
  try {
    // Crashlytics is only collected in release builds.
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
      return true;
    };
  } catch (e, stackTrace) {
    log('Failed to set up Crashlytics: $e', stackTrace: stackTrace);
  }
}

void _reportError(Object error, StackTrace stackTrace, {String? reason}) {
  log('Uncaught error: $error', stackTrace: stackTrace);
  try {
    FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: reason, fatal: true);
  } catch (_) {
    // Crashlytics unavailable (e.g. Firebase failed to initialise) - ignore.
  }
}

// RevenueCat has no web plugin implementation, so this is skipped entirely
// on web (the app is deployed to GitHub Pages as a web build).
Future<void> _initializeRevenueCat() async {
  if (kIsWeb) return;
  try {
    final apiKey = Platform.isIOS
        ? locator<RemoteConfigService>().data.revenueCat.revenueIOSApiKey
        : locator<RemoteConfigService>().data.revenueCat.revenueAndroidApiKey;
    await locator<RevenueCatService>().initialize(apiKey: apiKey);
    await locator<SubscriptionCubit>().checkSubscriptionStatus();
  } catch (e) {
    log('Error initializing RevenueCat: $e');
  }
}
