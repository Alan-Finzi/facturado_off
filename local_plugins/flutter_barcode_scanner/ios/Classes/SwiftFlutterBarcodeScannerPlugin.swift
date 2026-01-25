import Flutter
import UIKit

public class SwiftFlutterBarcodeScannerPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_barcode_scanner", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterBarcodeScannerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "scanBarcode":
      // In a real implementation this would scan a barcode
      // For now, we just return a dummy barcode
      result("12345678901234")
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}