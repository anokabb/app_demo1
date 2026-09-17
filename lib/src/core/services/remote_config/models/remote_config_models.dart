import 'package:freezed_annotation/freezed_annotation.dart';

part 'gen/remote_config_models.freezed.dart';
part 'gen/remote_config_models.g.dart';

/// Main remote config model that contains essential configuration
@freezed
abstract class RemoteConfigModel with _$RemoteConfigModel {
  const factory RemoteConfigModel({
    @Default(SettingsConfigModel()) SettingsConfigModel settings,
    @Default(RevenueCatConfigModel()) RevenueCatConfigModel revenueCat,
  }) = _RemoteConfigModel;

  factory RemoteConfigModel.fromJson(Map<String, dynamic> json) => _$RemoteConfigModelFromJson(json);
}

/// RevenueCat configuration settings
@freezed
abstract class RevenueCatConfigModel with _$RevenueCatConfigModel {
  const factory RevenueCatConfigModel({
    @Default('') String revenueIOSApiKey,
    @Default('') String revenueAndroidApiKey,
    @Default(3) int freeLimit,
    @Default(5) int closeButtonDelay,
    @Default(false) bool showDiscountAfterPaywall,
    @Default('') String hideDiscountPaywallForVersion,
  }) = _RevenueCatConfigModel;

  factory RevenueCatConfigModel.fromJson(Map<String, dynamic> json) => _$RevenueCatConfigModelFromJson(json);
}

/// Settings configuration - essential, app-wide settings data
@freezed
abstract class SettingsConfigModel with _$SettingsConfigModel {
  const factory SettingsConfigModel({
    // Legal & Support URLs
    @Default('') String privacyPolicyUrl,
    @Default('') String termsOfServiceUrl,
    @Default('') String aboutUrl,
    @Default('') String helpAndSupportUrl,
    @Default('') String contactUsEmail,

    // Account management
    @Default(true) bool enableAccountDeletion,
    @Default(true) bool enableDataDeletion,
    @Default('') String accountDeletionUrl,

    // App updates
    @Default(false) bool forceUpdate,

    // Third-party API keys
    @Default('') String geminiApiKey,

    // Hides the in-app "sent to Gemini" notice text under the Generate
    // button without touching the consent flow itself.
    @Default(false) bool hideGeminiDeclaration,
  }) = _SettingsConfigModel;

  factory SettingsConfigModel.fromJson(Map<String, dynamic> json) => _$SettingsConfigModelFromJson(json);
}

/// Remote config keys constants
class RemoteConfigKeys {
  // Settings Config
  static const String privacyPolicyUrl = 'privacy_policy_url';
  static const String termsOfServiceUrl = 'terms_of_service_url';
  static const String helpAndSupportUrl = 'help_and_support_url';
  static const String aboutUrl = 'about_url';
  static const String enableAccountDeletion = 'enable_account_deletion';
  static const String enableDataDeletion = 'enable_data_deletion';
  static const String accountDeletionUrl = 'account_deletion_url';
  static const String contactUsEmail = 'contact_us_email';
  static const String forceUpdate = 'force_update';
  static const String geminiApiKey = 'gemini_api_key';
  static const String hideGeminiDeclaration = 'hide_gemini_declaration';

  // RevenueCat Config
  static const String revenueIOSApiKey = 'revenue_ios_api_key';
  static const String revenueAndroidApiKey = 'revenue_android_api_key';
  static const String freeLimit = 'free_limit';
  static const String closeButtonDelay = 'close_button_delay';
  static const String showDiscountAfterPaywall = 'show_discount_after_paywall';
  static const String hideDiscountPaywallForVersion = 'hide_discount_paywall_for_version';
}
