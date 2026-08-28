#!/bin/sh
set -eu

collector="$SRCROOT/FlutterNativeOssLicenses/collect_licenses.swift"
project_root="$SRCROOT/.."
apple_project_root="$SRCROOT"
source_packages="$BUILD_DIR/../../SourcePackages"
output="$TARGET_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/flutter_native_oss_licenses/licenses.json"
acknowledgements="-"

if [ -n "${PODS_ROOT:-}" ]; then
  candidate="$PODS_ROOT/Target Support Files/Pods-$TARGET_NAME/Pods-$TARGET_NAME-acknowledgements.plist"
  if [ ! -f "$candidate" ]; then
    echo "error: CocoaPods acknowledgements are missing at $candidate" >&2
    exit 1
  fi
  acknowledgements="$candidate"
fi

mkdir -p "$(dirname "$output")"
xcrun --sdk macosx swift "$collector" \
  "$acknowledgements" \
  "$source_packages" \
  "$project_root" \
  "$apple_project_root" \
  "$output"
