import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app_template/src/core/constants/env_config.dart';
import 'package:flutter_app_template/src/core/network/client/dio_factory.dart';
import 'package:flutter_app_template/src/core/network/client/interceptors/logger_interceptor.dart';
import 'package:flutter_app_template/src/core/network/client/interceptors/mock_logger_interceptor.dart';
import 'package:flutter_app_template/src/features/languages/presentation/cubit/language_cubit.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/infrastructure/gemini_image_prompt_repo.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/infrastructure/image_prompt_repo.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/cubit/image_to_prompt_cubit.dart';
import 'package:flutter_app_template/src/core/services/purchases/revenue_cat_service.dart';
import 'package:flutter_app_template/src/core/services/purchases/subscription_cubit.dart';
import 'package:flutter_app_template/src/core/services/remote_config/remote_config_service.dart';
import 'package:flutter_app_template/src/features/theme/presentation/cubit/theme_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

// TODO: Remove this when not testing
bool isMockTesting = kDebugMode && true;

final locator = GetIt.instance;

void setupLocator() {
  // 1. Dio Client
  locator.registerLazySingleton<Dio>(
    () => DioFactory.create(
      baseUrl: EnvConfig.baseUrl,
      interceptors: [
        isMockTesting ? MockLoggerInterceptor() : LoggerInterceptor(),
      ],
    ),
  );

  // 2. Image-to-prompt provider — swap this single line to switch providers
  // (e.g. `MockImagePromptRepo()`); everything else depends on `ImagePromptRepo`.
  locator.registerLazySingleton<ImagePromptRepo>(() => GeminiImagePromptRepo());

  // 3. Cubits
  locator.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
  locator.registerLazySingleton<LanguageCubit>(() => LanguageCubit());
  locator.registerLazySingleton<ImageToPromptCubit>(() => ImageToPromptCubit());

  // 4. Remote Config / RevenueCat — initialized in main.dart after locator setup.
  locator.registerLazySingleton<RemoteConfigService>(() => RemoteConfigService());
  locator.registerLazySingleton<RevenueCatService>(() => RevenueCatService());
  locator.registerLazySingleton<SubscriptionCubit>(() => SubscriptionCubit(locator<RemoteConfigService>()));
}

void onLoggedIn(GetIt instance) async {
  log('Locator onLoggedIn');
}

List<BlocProvider> blocProviders = [
  BlocProvider<ThemeCubit>.value(value: locator<ThemeCubit>()),
  BlocProvider<LanguageCubit>.value(value: locator<LanguageCubit>()),
  BlocProvider<SubscriptionCubit>.value(value: locator<SubscriptionCubit>()),
];
