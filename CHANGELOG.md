## 1.0.1

- Describe setup as a one-time native build integration for Android, iOS, and
  macOS, with explicit instructions for dependency changes, package upgrades,
  CI, and regenerated platform projects.
- Update the bundled integration skill so Web, Linux, and Windows-only apps
  skip native setup and native checks run only where applicable.

## 1.0.0

- Add a deterministic API that merges Flutter, Android Gradle, CocoaPods, and
  remote Swift Package Manager license records.
- Add idempotent registration for Flutter's standard license registry.
- Add variant-aware Android generation that survives resource shrinking.
- Add hybrid CocoaPods and SwiftPM collection during iOS builds.
- Add equivalent CocoaPods and SwiftPM collection for macOS builds.
- Add first-class Web, Linux, and Windows Flutter-license support with no setup
  requirement and standard `flutter: licenses:` extension points.
- Add idempotent setup, CI check, and uninstall commands.
- Add a package-bundled integration skill for coding agents in consumer apps.
- Add a public example screenshot and contribution workflows.
- Add a reproducible pre-publication gate for the maximum current pub.dev score.
