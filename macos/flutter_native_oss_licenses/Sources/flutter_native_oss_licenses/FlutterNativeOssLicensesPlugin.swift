import Cocoa
import FlutterMacOS

public class FlutterNativeOssLicensesPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "flutter_native_oss_licenses",
      binaryMessenger: registrar.messenger
    )
    let instance = FlutterNativeOssLicensesPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "loadNativeLicensePayload":
      loadNativeLicensePayload(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func loadNativeLicensePayload(result: @escaping FlutterResult) {
    guard let url = Bundle.main.url(
      forResource: "licenses",
      withExtension: "json",
      subdirectory: "flutter_native_oss_licenses"
    ) else {
      result("[]")
      return
    }

    do {
      result(try String(contentsOf: url, encoding: .utf8))
    } catch {
      result(FlutterError(
        code: "native_license_payload_read_failed",
        message: "Could not read the generated native-license payload.",
        details: error.localizedDescription
      ))
    }
  }
}
