#!/bin/sh
set -eu

package_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
audit_root=$(mktemp -d "${TMPDIR:-/tmp}/flutter_native_oss_licenses_pana.XXXXXX")
audit_package="$audit_root/package"

cleanup() {
  rm -rf -- "$audit_root"
}
trap cleanup EXIT HUP INT TERM

cd "$package_root"

dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter pub outdated
dart pub publish --dry-run

mkdir -p "$audit_package"
rsync -a \
  --exclude '.git/' \
  --exclude '.dart_tool/' \
  --exclude '.flutter-plugins-dependencies' \
  --exclude '.gradle/' \
  --exclude '.idea/' \
  --exclude 'build/' \
  --exclude 'doc/api/' \
  --exclude 'local.properties' \
  --exclude 'pubspec.lock' \
  --exclude '*.iml' \
  "$package_root/" "$audit_package/"

dart pub global activate pana
dart pub global run pana "$audit_package" --exit-code-threshold=0
