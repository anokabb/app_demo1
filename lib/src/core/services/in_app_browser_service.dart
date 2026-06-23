import 'package:flutter/services.dart';

/// Presents [url] as a native bottom modal sheet (SFSafariViewController with
/// `.pageSheet`) on iOS — see `AppDelegate.swift`. `url_launcher`'s
/// `LaunchMode.inAppBrowserView` hardcodes `.overFullScreen` on iOS, which
/// looks like a left-to-right push instead of a modal sheet.
class InAppBrowserService {
  static const _channel = MethodChannel('flutter_app_template/in_app_browser');

  static Future<void> open(String url) => _channel.invokeMethod('open', {'url': url});
}
