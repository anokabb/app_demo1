import Flutter
import SafariServices
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // url_launcher's inAppBrowserView mode presents SFSafariViewController with
    // .overFullScreen on iOS, which looks like a left-to-right push. We want the
    // standard rounded-corner bottom modal sheet instead, so we present it ourselves.
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "flutter_app_template/in_app_browser",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        guard call.method == "open",
              let args = call.arguments as? [String: Any],
              let urlString = args["url"] as? String,
              let url = URL(string: urlString)
        else {
          result(FlutterError(code: "bad_args", message: "Missing or invalid url", details: nil))
          return
        }
        let safariViewController = SFSafariViewController(url: url)
        safariViewController.modalPresentationStyle = .pageSheet
        controller.present(safariViewController, animated: true)
        result(nil)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
