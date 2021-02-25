import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
      print("Launching options called")
      GeneratedPluginRegistrant.register(with: self)

      guard let controller = window?.rootViewController as? FlutterViewController else {
        fatalError("rootViewController is not type FlutterViewController")
      }

      let greetingChannel = FlutterMethodChannel(name: "waypoint_app.flutter.io/cate", binaryMessenger: controller.binaryMessenger)

      greetingChannel.setMethodCallHandler({
        [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
        guard call.method == "getGreeting" else {
          print("Flutter Method Not Implemented")
          result("FlutterMethodNotImplemented")
          return
        }
        self?.receiveGreeting(result: result)
      })
      

      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func receiveGreeting(result: FlutterResult) {
    print("Went to receiveGreeting in AppDelegate.swift")
    result("Hello Cate!");
  }
}

