import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../flutter_native_oss_licenses_platform_interface.dart';
import 'merged_license_entry.dart';

typedef NativeLicenseLoader = Future<List<MergedLicenseEntry>> Function();

/// Stateful implementation behind the package's top-level API.
///
final class LicenseService {
  LicenseService({NativeLicenseLoader? nativeLoader})
    : _nativeLoader = nativeLoader ?? _loadNativeLicenses;

  final NativeLicenseLoader _nativeLoader;
  Future<List<MergedLicenseEntry>>? _nativeEntries;
  bool _registered = false;

  Future<List<MergedLicenseEntry>> loadMergedLicenses() {
    return _mergeWithFlutterLicenses(loadNativeLicenses());
  }

  Future<List<MergedLicenseEntry>> loadNativeLicenses() {
    return _nativeEntries ??= _nativeLoader();
  }

  void registerNativeLicenses() {
    if (_registered || !_supportsNativePayload) {
      return;
    }
    _registered = true;

    LicenseRegistry.addLicense(() async* {
      for (final entry in await loadNativeLicenses()) {
        yield LicenseEntryWithLineBreaks(entry.packages, entry.text);
      }
    });
  }
}

bool get _supportsNativePayload {
  if (kIsWeb) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

Future<List<MergedLicenseEntry>> _loadNativeLicenses() async {
  if (!_supportsNativePayload) {
    return const <MergedLicenseEntry>[];
  }

  final payload = await FlutterNativeOssLicensesPlatform.instance
      .loadNativeLicensePayload();
  return parseNativeLicensePayload(payload);
}

@visibleForTesting
List<MergedLicenseEntry> parseNativeLicensePayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    throw FormatException('Native license payload is not valid JSON: $error');
  }

  if (decoded is! List<Object?>) {
    throw const FormatException('Native license payload must be a JSON array.');
  }

  final result = <MergedLicenseEntry>[];
  for (var index = 0; index < decoded.length; index += 1) {
    final value = decoded[index];
    if (value is! Map<Object?, Object?>) {
      throw FormatException('Native license entry $index must be an object.');
    }

    final packagesValue = value['packages'];
    final textValue = value['text'];
    if (packagesValue is! List<Object?> ||
        packagesValue.any((package) => package is! String)) {
      throw FormatException(
        'Native license entry $index must contain a string packages array.',
      );
    }
    if (textValue is! String || textValue.trim().isEmpty) {
      throw FormatException(
        'Native license entry $index must contain non-empty text.',
      );
    }

    final packages =
        packagesValue
            .cast<String>()
            .map((package) => package.trim())
            .where((package) => package.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    if (packages.isEmpty) {
      throw FormatException(
        'Native license entry $index must contain a non-empty package name.',
      );
    }
    result.add(MergedLicenseEntry(packages: packages, text: textValue));
  }

  return List<MergedLicenseEntry>.unmodifiable(result);
}

Future<List<MergedLicenseEntry>> _mergeWithFlutterLicenses(
  Future<List<MergedLicenseEntry>> nativeEntries,
) async {
  final packagesByText = <String, Set<String>>{};

  void add(Iterable<String> packages, String text) {
    if (text.trim().isEmpty) {
      return;
    }

    final names = packages
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty);
    packagesByText.putIfAbsent(text, () => <String>{}).addAll(names);
  }

  await for (final entry in LicenseRegistry.licenses) {
    add(
      entry.packages,
      entry.paragraphs.map((paragraph) => paragraph.text).join('\n\n'),
    );
  }

  for (final entry in await nativeEntries) {
    add(entry.packages, entry.text);
  }

  final result = packagesByText.entries
      .where((entry) => entry.value.isNotEmpty)
      .map((entry) {
        final packages = entry.value.toList()..sort();
        return MergedLicenseEntry(packages: packages, text: entry.key);
      })
      .toList();

  result.sort((left, right) {
    final byFirstPackage = left.packages.first.compareTo(right.packages.first);
    if (byFirstPackage != 0) {
      return byFirstPackage;
    }
    final byPackages = left.packages
        .join('\u0000')
        .compareTo(right.packages.join('\u0000'));
    return byPackages != 0 ? byPackages : left.text.compareTo(right.text);
  });
  return List<MergedLicenseEntry>.unmodifiable(result);
}
