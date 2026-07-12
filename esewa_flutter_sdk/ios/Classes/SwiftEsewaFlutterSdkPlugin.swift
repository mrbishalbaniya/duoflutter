import Flutter
import UIKit

/// iOS stub — the vendored EsewaSDK.framework (Swift 5.10) fails to compile under
/// Xcode 16+ / Swift 6 on CI. Duo wallet uses WebView checkout on iOS instead.
public class SwiftEsewaFlutterSdkPlugin: NSObject, FlutterPlugin {
  static var channel: FlutterMethodChannel?
  static let METHOD_CHANNEL_NAME = "flutter_sdk_channel"
  private let paymentMethodFailure = "payment_failure"

  public static func register(with registrar: FlutterPluginRegistrar) {
    channel = FlutterMethodChannel(name: METHOD_CHANNEL_NAME, binaryMessenger: registrar.messenger())
    let instance = SwiftEsewaFlutterSdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel!)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initPayment":
      SwiftEsewaFlutterSdkPlugin.channel?.invokeMethod(
        paymentMethodFailure,
        arguments: "Native eSewa is unavailable on iOS. Use web checkout."
      )
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
