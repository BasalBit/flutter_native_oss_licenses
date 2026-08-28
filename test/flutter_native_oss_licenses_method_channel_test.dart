import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_native_oss_licenses/flutter_native_oss_licenses_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelFlutterNativeOssLicenses platform =
      MethodChannelFlutterNativeOssLicenses();
  const MethodChannel channel = MethodChannel('flutter_native_oss_licenses');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return '[{"packages":["native"],"text":"License"}]';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('loadNativeLicensePayload', () async {
    expect(
      await platform.loadNativeLicensePayload(),
      '[{"packages":["native"],"text":"License"}]',
    );
  });
}
