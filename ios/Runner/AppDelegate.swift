import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Key comes from ios/Flutter/Maps.xcconfig (git-ignored) via Info.plist,
    // mirroring how Android reads its key from android/local.properties.
    // Left unset the app still runs; the map view is simply blank.
    if let key = Bundle.main.object(forInfoDictionaryKey: "MapsApiKey") as? String,
       !key.isEmpty {
      GMSServices.provideAPIKey(key)
    } else {
      NSLog("[VybeCabs] No Maps key found. Copy ios/Flutter/Maps.xcconfig.example "
            + "to Maps.xcconfig and add your Maps SDK for iOS key.")
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
