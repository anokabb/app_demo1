import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/src/app.dart';
import 'package:flutter_app_template/src/core/constants/env_config.dart';
import 'package:flutter_app_template/src/core/constants/hive_config.dart';
import 'package:flutter_app_template/src/core/routing/app_router.dart';
import 'package:flutter_app_template/src/core/services/locator/locator.dart';
import 'package:flutter_app_template/src/features/auth/presentation/cubit/auth_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initHive();
  await EnvConfig.loadEnv();

  setupLocator();
  await locator.allReady();
  await locator<AuthCubit>().checkAuthStatus();

  // Remote Config / RevenueCat init — depends on Firebase being initialized
  // above, so left inert until that's wired up.
  // await locator<RemoteConfigService>().initialize();
  // await locator<RemoteConfigService>().fetchAndActivate();
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
