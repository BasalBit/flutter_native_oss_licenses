# flutter_native_oss_licenses_example

Demonstrates both public integration paths:

- `loadMergedLicenses()` for a custom UI or export; and
- `registerNativeLicenses()` with Flutter's Material `showLicensePage`.

The checked-in Android, iOS, and macOS host changes were produced by:

```sh
dart run flutter_native_oss_licenses:setup
```

Web, Linux, and Windows use Flutter's license registry without host changes.
The example's `licenses/example_external_component.txt` shows how to add a
notice that no automatic platform collector can discover.
