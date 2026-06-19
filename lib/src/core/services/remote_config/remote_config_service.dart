import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_app_template/src/core/services/logger/logger.dart';
import 'package:flutter_app_template/src/core/services/remote_config/models/remote_config_models.dart';

class RemoteConfigService {
  final _logger = getLogger('RemoteConfigService');
  late final FirebaseRemoteConfig _remoteConfig;
  RemoteConfigModel data = const RemoteConfigModel();

  bool get isForceUpdate => data.settings.forceUpdate;

  /// Initialize Firebase Remote Config
  Future<void> initialize() async {
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 30),
          minimumFetchInterval: const Duration(seconds: 1),
        ),
      );
      await _setDefaultValues();
      _logger.i('Remote Config initialized successfully');
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize Remote Config', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Fetch and activate remote config values
  Future<void> fetchAndActivate() async {
    try {
      final result = await _remoteConfig.fetchAndActivate();
      _logger.i('Remote config fetchAndActivate result: $result');
      data = _parseRemoteConfig();
      _logger.i('Remote config fetched successfully: ${data.toJson()}');
    } catch (e, stackTrace) {
      _logger.e('Failed to fetch remote config', error: e, stackTrace: stackTrace);
      data = const RemoteConfigModel();
    }
  }

  /// Set default values for all remote config parameters
  Future<void> _setDefaultValues() async {
    final defaultValues = <String, dynamic>{
      // Settings Config defaults
      RemoteConfigKeys.privacyPolicyUrl: '',
      RemoteConfigKeys.termsOfServiceUrl: '',
      RemoteConfigKeys.aboutUrl: '',
      RemoteConfigKeys.helpAndSupportUrl: '',
      RemoteConfigKeys.contactUsEmail: '',
      RemoteConfigKeys.enableAccountDeletion: true,
      RemoteConfigKeys.enableDataDeletion: true,
      RemoteConfigKeys.accountDeletionUrl: '',
      RemoteConfigKeys.forceUpdate: false,
      RemoteConfigKeys.geminiApiKey: '',

      // RevenueCat Config defaults
      RemoteConfigKeys.revenueIOSApiKey: '',
      RemoteConfigKeys.revenueAndroidApiKey: '',
      RemoteConfigKeys.freeLimit: 3,
      RemoteConfigKeys.closeButtonDelay: 5,
      RemoteConfigKeys.showDiscountAfterPaywall: false,
      RemoteConfigKeys.hideDiscountPaywallForVersion: '',
    };

    await _remoteConfig.setDefaults(defaultValues);
  }

  /// Parse remote config values into model
  RemoteConfigModel _parseRemoteConfig() {
    return RemoteConfigModel(
      settings: SettingsConfigModel(
        privacyPolicyUrl: _remoteConfig.getString(RemoteConfigKeys.privacyPolicyUrl),
        termsOfServiceUrl: _remoteConfig.getString(RemoteConfigKeys.termsOfServiceUrl),
        aboutUrl: _remoteConfig.getString(RemoteConfigKeys.aboutUrl),
        helpAndSupportUrl: _remoteConfig.getString(RemoteConfigKeys.helpAndSupportUrl),
        contactUsEmail: _remoteConfig.getString(RemoteConfigKeys.contactUsEmail),
        enableAccountDeletion: _remoteConfig.getBool(RemoteConfigKeys.enableAccountDeletion),
        enableDataDeletion: _remoteConfig.getBool(RemoteConfigKeys.enableDataDeletion),
        accountDeletionUrl: _remoteConfig.getString(RemoteConfigKeys.accountDeletionUrl),
        forceUpdate: _remoteConfig.getBool(RemoteConfigKeys.forceUpdate),
        geminiApiKey: _remoteConfig.getString(RemoteConfigKeys.geminiApiKey),
      ),
      revenueCat: RevenueCatConfigModel(
        revenueIOSApiKey: _remoteConfig.getString(RemoteConfigKeys.revenueIOSApiKey),
        revenueAndroidApiKey: _remoteConfig.getString(RemoteConfigKeys.revenueAndroidApiKey),
        freeLimit: _remoteConfig.getInt(RemoteConfigKeys.freeLimit),
        closeButtonDelay: _remoteConfig.getInt(RemoteConfigKeys.closeButtonDelay),
        showDiscountAfterPaywall: _remoteConfig.getBool(RemoteConfigKeys.showDiscountAfterPaywall),
        hideDiscountPaywallForVersion: _remoteConfig.getString(RemoteConfigKeys.hideDiscountPaywallForVersion),
      ),
    );
  }

  /// Last fetch time
  DateTime get lastFetchTime => _remoteConfig.lastFetchTime;

  /// Last fetch status
  RemoteConfigFetchStatus get lastFetchStatus => _remoteConfig.lastFetchStatus;
}
