import 'package:flutter/foundation.dart';
import 'package:flutter_app_template/src/core/constants/hive_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum ConfigEnvironments { staging }

/// Backend deployment target, independent of [EnvConfig.currentEnv] (which
/// `.env` file to load) — lets the API base URL be flipped from dev tools
/// without a rebuild.
enum BackendEnvironment { beta, production }

class EnvConfig {
  static const String APP_NAME = 'Flutter App';
  static const String _backendEnvironmentKey = 'backend_environment';

  static String get baseUrl => dotenv.get('BASE_URL', fallback: '');
  static bool get showEnvBanner => devBox.get('showEnvBanner', defaultValue: kDebugMode ? true : false);
  static String get currentEnv => devBox.get(
        'env',
        defaultValue: const String.fromEnvironment(
          'ENV',
          defaultValue: 'staging',
        ),
      );

  static Future<void> loadEnv() async {
    await dotenv.load(fileName: '$currentEnv.env');
  }

  void changeEnv(String env) {
    devBox.put('env', env);
  }

// for testing in debug mode
  static String get TEST_PHONE_NUMBER => !kDebugMode ? '' : dotenv.get('TEST_PHONE_NUMBER', fallback: '');
  static String get TEST_OTP => !kDebugMode ? '' : dotenv.get('TEST_OTP', fallback: '');
  static String get TEST_EMAIL => !kDebugMode ? '' : dotenv.get('TEST_EMAIL', fallback: '');
  static String get TEST_PASSWORD => !kDebugMode ? '' : dotenv.get('TEST_PASSWORD', fallback: '');

  /// Current backend target (defaults to production).
  static BackendEnvironment get currentBackendEnvironment {
    final envString = devBox.get(_backendEnvironmentKey, defaultValue: 'production') as String;
    return envString == 'beta' ? BackendEnvironment.beta : BackendEnvironment.production;
  }

  static Future<void> setBackendEnvironment(BackendEnvironment env) async {
    await devBox.put(_backendEnvironmentKey, env == BackendEnvironment.beta ? 'beta' : 'production');
  }

  /// Pick a base URL based on [currentBackendEnvironment].
  static String getBackendBaseUrl({
    required String betaUrl,
    required String productionUrl,
  }) {
    return currentBackendEnvironment == BackendEnvironment.beta ? betaUrl : productionUrl;
  }
}
