import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/firebase_options.dart';
import 'package:flutter_app_template/src/app.dart';
import 'package:flutter_app_template/src/core/constants/env_config.dart';
import 'package:flutter_app_template/src/core/constants/hive_config.dart';
import 'package:flutter_app_template/src/core/routing/app_router.dart';
import 'package:flutter_app_template/src/core/services/locator/locator.dart';
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

  // RevenueCat init — left inert until real RevenueCat API keys are set in
  // Remote Config (revenue_ios_api_key / revenue_android_api_key default to
  // empty strings, and Purchases.configure('') would throw on startup).
  // await locator<RevenueCatService>().initialize(
  //   apiKey: Platform.isIOS
  //       ? locator<RemoteConfigService>().data.revenueCat.revenueIOSApiKey
  //       : locator<RemoteConfigService>().data.revenueCat.revenueAndroidApiKey,
  // );

  runApp(
    App(
      routerConfig: AppRouter().createRouter(),
    ),
  );
}
