import 'package:flutter/foundation.dart';
import 'package:flutter_native_oss_licenses/flutter_native_oss_licenses.dart';
import 'package:flutter_native_oss_licenses/flutter_native_oss_licenses_platform_interface.dart';
import 'package:flutter_native_oss_licenses/src/license_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FlutterNativeOssLicensesPlatform originalPlatform;

  setUp(() {
    LicenseRegistry.reset();
    originalPlatform = FlutterNativeOssLicensesPlatform.instance;
    if (!kIsWeb) {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    }
  });

  tearDown(() {
    FlutterNativeOssLicensesPlatform.instance = originalPlatform;
    LicenseRegistry.reset();
    if (!kIsWeb) {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test('uses only Flutter entries on Web, Linux, and Windows', () async {
    final platform = _RecordingPlatform();
    FlutterNativeOssLicensesPlatform.instance = platform;
    LicenseRegistry.addLicense(() async* {
      yield const LicenseEntryWithLineBreaks(['flutter_only'], 'Flutter text');
    });

    final entries = await LicenseService().loadMergedLicenses();

    expect(platform.loads, 0);
    expect(entries, [
      MergedLicenseEntry(packages: ['flutter_only'], text: 'Flutter text'),
    ]);
  });

  test('uses only Flutter entries on Windows', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final platform = _RecordingPlatform();
    FlutterNativeOssLicensesPlatform.instance = platform;
    LicenseRegistry.addLicense(() async* {
      yield const LicenseEntryWithLineBreaks(['flutter_only'], 'Flutter text');
    });

    final entries = await LicenseService().loadMergedLicenses();

    expect(platform.loads, 0);
    expect(entries, [
      MergedLicenseEntry(packages: ['flutter_only'], text: 'Flutter text'),
    ]);
  }, skip: kIsWeb);
}

final class _RecordingPlatform extends FlutterNativeOssLicensesPlatform {
  int loads = 0;

  @override
  Future<String> loadNativeLicensePayload() async {
    loads += 1;
    return '[]';
  }
}
