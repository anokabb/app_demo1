import 'dart:developer';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
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
import 'package:flutter_app_template/src/features/auth/presentation/cubit/auth_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initHive();
  await EnvConfig.loadEnv();

  setupLocator();
  await locator.allReady();
  await locator<AuthCubit>().checkAuthStatus();

  await locator<RemoteConfigService>().initialize();
  await locator<RemoteConfigService>().fetchAndActivate();

  await _initializeRevenueCat();

  runApp(
    App(
      routerConfig: AppRouter().createRouter(),
    ),
  );
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
