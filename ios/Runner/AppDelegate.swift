import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // This is the corrected function to handle URL schemes
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    // First, let the parent class (FlutterAppDelegate) try to handle the URL.
    // This is what passes the URL to Flutter plugins.
    let handled = super.application(app, open: url, options: options)

    // If the parent class handled it, we're done.
    if handled {
        return true
    }

    // If not, you can add your own custom scheme handling here.
    // For now, we return false as we expect Flutter to handle it.
    return false
  }
}
