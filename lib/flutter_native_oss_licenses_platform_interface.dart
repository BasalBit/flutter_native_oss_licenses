/// Platform interface for loading generated native license payloads.
library;

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_native_oss_licenses_method_channel.dart';

/// Contract implemented by the Android, iOS, and macOS native payload bridges.
abstract class FlutterNativeOssLicensesPlatform extends PlatformInterface {
  /// Constructs a FlutterNativeOssLicensesPlatform.
  FlutterNativeOssLicensesPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterNativeOssLicensesPlatform _instance =
      MethodChannelFlutterNativeOssLicenses();

  /// The default instance of [FlutterNativeOssLicensesPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterNativeOssLicenses].
  static FlutterNativeOssLicensesPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterNativeOssLicensesPlatform] when
  /// they register themselves.
  static set instance(FlutterNativeOssLicensesPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Loads the generated native-license JSON payload.
  Future<String> loadNativeLicensePayload() {
    throw UnimplementedError(
      'loadNativeLicensePayload() has not been implemented.',
    );
  }
}
