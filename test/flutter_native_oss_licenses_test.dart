import 'dart:async';

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
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    FlutterNativeOssLicensesPlatform.instance = originalPlatform;
    LicenseRegistry.reset();
    debugDefaultTargetPlatformOverride = null;
  });

  for (final target in [
    TargetPlatform.android,
    TargetPlatform.iOS,
    TargetPlatform.macOS,
  ]) {
    test('loads the generated native payload on $target', () async {
      debugDefaultTargetPlatformOverride = target;
      final platform = _RecordingPlatform();
      FlutterNativeOssLicensesPlatform.instance = platform;

      final entries = await LicenseService().loadNativeLicenses();

      expect(platform.loads, 1);
      expect(entries, [
        MergedLicenseEntry(packages: ['native'], text: 'Native license'),
      ]);
    });
  }

  test('parses, normalizes, and protects native payload entries', () {
    const text = '  exact text with boundary whitespace  ';
    final entries = parseNativeLicensePayload('''
      [
        {
          "packages": [" zeta ", "alpha", "alpha", ""],
          "text": "$text"
        }
      ]
    ''');

    expect(entries, [
      MergedLicenseEntry(packages: ['alpha', 'zeta'], text: text),
    ]);
    expect(() => entries.add(entries.single), throwsUnsupportedError);
    expect(
      () => entries.single.packages.add('mutable'),
      throwsUnsupportedError,
    );
  });

  test('rejects malformed native payloads', () {
    expect(() => parseNativeLicensePayload('{}'), throwsFormatException);
    expect(
      () => parseNativeLicensePayload('[{"packages": [], "text": "x"}]'),
      throwsFormatException,
    );
    expect(
      () => parseNativeLicensePayload('[{"packages": ["x"], "text": "  "}]'),
      throwsFormatException,
    );
  });

  test('groups equal text and sorts package names and records', () async {
    LicenseRegistry.addLicense(() async* {
      yield const LicenseEntryWithLineBreaks([
        ' flutter_package ',
        'shared',
      ], 'Shared text');
      yield const LicenseEntryWithLineBreaks(['zulu'], 'Zulu text');
    });
    final service = LicenseService(
      nativeLoader: () async => [
        MergedLicenseEntry(
          packages: ['native_package', 'shared'],
          text: 'Shared text',
        ),
        MergedLicenseEntry(packages: ['alpha'], text: 'Alpha text'),
      ],
    );

    final result = await service.loadMergedLicenses();

    expect(result.map((entry) => entry.packages), [
      ['alpha'],
      ['flutter_package', 'native_package', 'shared'],
      ['zulu'],
    ]);
    expect(result[1].text, 'Shared text');
  });

  test(
    'sees Flutter collectors registered after an earlier snapshot',
    () async {
      final service = LicenseService(nativeLoader: () async => []);
      LicenseRegistry.addLicense(() async* {
        yield const LicenseEntryWithLineBreaks(['first'], 'First');
      });
      expect(
        (await service.loadMergedLicenses()).map(
          (entry) => entry.packages.single,
        ),
        ['first'],
      );

      LicenseRegistry.addLicense(() async* {
        yield const LicenseEntryWithLineBreaks(['second'], 'Second');
      });
      expect(
        (await service.loadMergedLicenses()).map(
          (entry) => entry.packages.single,
        ),
        ['first', 'second'],
      );
    },
  );

  test('shares one native load across concurrent callers', () async {
    final completer = Completer<List<MergedLicenseEntry>>();
    var loads = 0;
    final service = LicenseService(
      nativeLoader: () {
        loads += 1;
        return completer.future;
      },
    );

    final first = service.loadNativeLicenses();
    final second = service.loadNativeLicenses();
    expect(identical(first, second), isTrue);
    expect(loads, 1);
    completer.complete([
      MergedLicenseEntry(packages: ['native'], text: 'Native'),
    ]);
    await Future.wait([first, second]);
  });

  test('registration is idempotent before and after collection', () async {
    var loads = 0;
    final service = LicenseService(
      nativeLoader: () async {
        loads += 1;
        return [
          MergedLicenseEntry(packages: ['native'], text: 'Native'),
        ];
      },
    );

    final beforeRegistration = await service.loadMergedLicenses();
    expect(beforeRegistration, hasLength(1));
    service.registerNativeLicenses();
    service.registerNativeLicenses();
    final afterRegistration = await service.loadMergedLicenses();

    expect(afterRegistration, hasLength(1));
    expect(afterRegistration.single.packages, ['native']);
    expect(loads, 1);
    expect(await LicenseRegistry.licenses.toList(), hasLength(1));
  });
}

final class _RecordingPlatform extends FlutterNativeOssLicensesPlatform {
  int loads = 0;

  @override
  Future<String> loadNativeLicensePayload() async {
    loads += 1;
    return '[{"packages":["native"],"text":"Native license"}]';
  }
}
