// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../remote_config_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RemoteConfigModelImpl _$$RemoteConfigModelImplFromJson(
        Map<String, dynamic> json) =>
    _$RemoteConfigModelImpl(
      settings: json['settings'] == null
          ? const SettingsConfigModel()
          : SettingsConfigModel.fromJson(
              json['settings'] as Map<String, dynamic>),
      revenueCat: json['revenue_cat'] == null
          ? const RevenueCatConfigModel()
          : RevenueCatConfigModel.fromJson(
              json['revenue_cat'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$RemoteConfigModelImplToJson(
        _$RemoteConfigModelImpl instance) =>
    <String, dynamic>{
      'settings': instance.settings,
      'revenue_cat': instance.revenueCat,
    };

_$RevenueCatConfigModelImpl _$$RevenueCatConfigModelImplFromJson(
        Map<String, dynamic> json) =>
    _$RevenueCatConfigModelImpl(
      revenueIOSApiKey: json['revenue_i_o_s_api_key'] as String? ?? '',
      revenueAndroidApiKey: json['revenue_android_api_key'] as String? ?? '',
      freeLimit: (json['free_limit'] as num?)?.toInt() ?? 3,
      closeButtonDelay: (json['close_button_delay'] as num?)?.toInt() ?? 5,
      showDiscountAfterPaywall:
          json['show_discount_after_paywall'] as bool? ?? false,
      hideDiscountPaywallForVersion:
          json['hide_discount_paywall_for_version'] as String? ?? '',
    );

Map<String, dynamic> _$$RevenueCatConfigModelImplToJson(
        _$RevenueCatConfigModelImpl instance) =>
    <String, dynamic>{
      'revenue_i_o_s_api_key': instance.revenueIOSApiKey,
      'revenue_android_api_key': instance.revenueAndroidApiKey,
      'free_limit': instance.freeLimit,
      'close_button_delay': instance.closeButtonDelay,
      'show_discount_after_paywall': instance.showDiscountAfterPaywall,
      'hide_discount_paywall_for_version':
          instance.hideDiscountPaywallForVersion,
    };

_$SettingsConfigModelImpl _$$SettingsConfigModelImplFromJson(
        Map<String, dynamic> json) =>
    _$SettingsConfigModelImpl(
      privacyPolicyUrl: json['privacy_policy_url'] as String? ?? '',
      termsOfServiceUrl: json['terms_of_service_url'] as String? ?? '',
      aboutUrl: json['about_url'] as String? ?? '',
      helpAndSupportUrl: json['help_and_support_url'] as String? ?? '',
      contactUsEmail: json['contact_us_email'] as String? ?? '',
      enableAccountDeletion: json['enable_account_deletion'] as bool? ?? true,
      enableDataDeletion: json['enable_data_deletion'] as bool? ?? true,
      accountDeletionUrl: json['account_deletion_url'] as String? ?? '',
      forceUpdate: json['force_update'] as bool? ?? false,
      geminiApiKey: json['gemini_api_key'] as String? ?? '',
      hideGeminiDeclaration: json['hide_gemini_declaration'] as bool? ?? false,
    );

Map<String, dynamic> _$$SettingsConfigModelImplToJson(
        _$SettingsConfigModelImpl instance) =>
    <String, dynamic>{
      'privacy_policy_url': instance.privacyPolicyUrl,
      'terms_of_service_url': instance.termsOfServiceUrl,
      'about_url': instance.aboutUrl,
      'help_and_support_url': instance.helpAndSupportUrl,
      'contact_us_email': instance.contactUsEmail,
      'enable_account_deletion': instance.enableAccountDeletion,
      'enable_data_deletion': instance.enableDataDeletion,
      'account_deletion_url': instance.accountDeletionUrl,
      'force_update': instance.forceUpdate,
      'gemini_api_key': instance.geminiApiKey,
      'hide_gemini_declaration': instance.hideGeminiDeclaration,
    };
