/// Method-channel implementation of the native license payload bridge.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_native_oss_licenses_platform_interface.dart';

/// An implementation of [FlutterNativeOssLicensesPlatform] that uses method channels.
class MethodChannelFlutterNativeOssLicenses
    extends FlutterNativeOssLicensesPlatform {
  /// Creates a method-channel platform implementation.
  MethodChannelFlutterNativeOssLicenses();

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_native_oss_licenses');

  @override
  Future<String> loadNativeLicensePayload() async {
    final payload = await methodChannel.invokeMethod<String>(
      'loadNativeLicensePayload',
    );
    return payload ?? '[]';
  }
}
