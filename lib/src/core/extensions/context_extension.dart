import 'package:flutter/material.dart';
import 'package:flutter_app_template/l10n/app_localizations.dart';
import 'package:flutter_app_template/src/core/components/pop_up/app_alert_toast.dart';
import 'package:flutter_app_template/src/core/services/locator/locator.dart';
import 'package:flutter_app_template/src/core/services/theme/app_colors.dart';
import 'package:flutter_app_template/src/features/theme/presentation/cubit/theme_cubit.dart';

extension AppLocalizationsExtension on AppLocalizations {
  String getString(String key) {
    final Map<String, String> localizedStrings = {
      // 'key': value,
    };

    return localizedStrings[key.toLowerCase()] ?? key;
  }
}

extension EBuildContext on BuildContext {
  AppLocalizations get localization => AppLocalizations.of(this)!;
  bool get isDarkMode => locator<ThemeCubit>().state.isDarkMode;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: isError ? Colors.red : AppColors.green,
      ),
    );
  }

  double get height => MediaQuery.of(this).size.height;
  double get width => MediaQuery.of(this).size.width;
}

void showTopError(String message) {
  showAppError(message);
}

void showTopAlert(String message, {bool isError = false}) {
  showAppAlert(message, isError: isError);
}
