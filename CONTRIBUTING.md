# Contributing

Bug reports and focused pull requests are welcome.

For a bug, include:

- Flutter and Dart versions;
- affected platform and build mode;
- Gradle, CocoaPods, or SwiftPM project shape;
- output from `dart run flutter_native_oss_licenses:setup --check`; and
- the smallest reproducible application or fixture you can share.

For a behavior change, open an issue before a large implementation so the
failure mode and compatibility boundary are agreed first.

## Local checks

From the package root, run:

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter pub outdated
flutter pub publish --dry-run
```

On macOS, the test suite also exercises the Swift collector. Android native
collection must be verified with a release or another non-debuggable build.

Changes to setup or uninstall behavior need tests for installation, a second
idempotent run, `--check`, and `--uninstall`. Update the README, example,
changelog, and bundled package skill when user-facing behavior changes.

Keep pull requests narrow and explain the consumer-app failure they fix.
