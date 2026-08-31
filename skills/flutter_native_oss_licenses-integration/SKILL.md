---
name: flutter_native_oss_licenses-integration
description: >-
  Use when adding open-source notices or a third-party license page to a
  Flutter app, especially when Android Gradle, CocoaPods, or SwiftPM
  dependencies must appear with Flutter and Dart licenses.
---

# Integrate Flutter and native dependency licenses

Add `flutter_native_oss_licenses` to a consumer Flutter application and leave
the app with a reachable notice UI plus verified build integration.

## Select the package

Use this package when the notice inventory includes dependencies resolved by
Android Gradle, CocoaPods, or remote Swift Package Manager. Flutter's built-in
`LicenseRegistry` is sufficient when Flutter and Dart notices are the complete
requirement. A `pubspec.lock` generator is a different tool: it produces a Dart
package inventory but cannot see the app's native dependency graphs.

Confirm that the consumer uses Flutter 3.44 or newer and identify its Android,
iOS, macOS, Web, Linux, and Windows targets.

## Install the package and native build integration

Run from the consumer directory that contains `pubspec.yaml`:

```sh
flutter pub add flutter_native_oss_licenses
```

When the consumer has an Android, iOS, or macOS application target, install the
native build integration once from the same directory:

```sh
dart run flutter_native_oss_licenses:setup
```

This installs the Gradle and Xcode hooks that regenerate native notices during
ordinary builds. Dependency changes need no setup rerun. After upgrading
`flutter_native_oss_licenses`, run `setup --check` and rerun setup only when the
check reports stale integration. Run setup again after adding a native platform,
regenerating its host project, or changing the Apple dependency-manager setup.
Preserve unrelated host-project content and let the command manage its
marker-delimited changes. Commit the generated files and host-project edits so
CI receives the same integration.

For a Web, Linux, or Windows-only consumer, finish this step after adding the
package. Those platforms use Flutter's license registry and need no native build
integration.

For Android, iOS, or macOS consumers, confirm installation without changing
files:

```sh
dart run flutter_native_oss_licenses:setup --check
```

## Expose the notices

For Flutter's standard Material or Cupertino license page, register generated
native entries before `runApp`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_native_oss_licenses/flutter_native_oss_licenses.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerNativeLicenses();
  runApp(const MyApp());
}
```

Connect the app's About, Settings, Legal, or Acknowledgements UI to:

```dart
showLicensePage(
  context: context,
  applicationName: 'My app',
);
```

For a custom UI or export, use:

```dart
final List<MergedLicenseEntry> entries = await loadMergedLicenses();
```

Surface loading failures to the caller or UI. Each merged entry contains sorted
`packages` and one collected `text` value.

## Cover unmanaged components

Web, Linux, and Windows have no universal native dependency graph with license
text. Android and Apple apps can also contain vendored or manually integrated
components outside the automatic sources.

Add one notice file per unmanaged component through Flutter's standard field:

```yaml
flutter:
  licenses:
    - licenses/your_native_component.txt
```

Format each file as a component name, a blank line, and the supplied notice or
license text.

## Validate distributed variants

For Android, iOS, or macOS consumers, run:

```sh
dart run flutter_native_oss_licenses:setup --check
```

For every consumer, run:

```sh
flutter analyze
flutter test
```

Then validate the variants the app distributes:

- Build Android as release or another non-debuggable variant. Google's
  upstream plugin emits a placeholder for ordinary debug variants.
- Resolve CocoaPods and SwiftPM dependencies before building the iOS and macOS
  release targets. The collector validates remote checkout origins, revisions,
  and root legal files.
- On Web, Linux, and Windows, inspect Flutter/Dart records plus every explicit
  file declared under `flutter: licenses:`.

Open the notice UI and confirm one expected record from every configured source.
Report that the package collects available metadata rather than claiming legal
completeness: Android Maven records can be absent or URL-only, and unmanaged
components require explicit notice files.

Finish when the applicable setup check passes, distributed release variants
build, users can reach the notice UI, and representative entries from every
configured source are present.

## Remove the integration

If native build integration was installed, use the package-owned rollback
before removing the Dart dependency:

```sh
dart run flutter_native_oss_licenses:setup --uninstall
```
