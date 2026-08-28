/// Plugin registration for platforms that use Flutter's license registry only.
final class FlutterNativeOssLicensesFlutterOnlyPlugin {
  const FlutterNativeOssLicensesFlutterOnlyPlugin._();

  /// Registers the platform implementation.
  ///
  /// Linux and Windows need no native bridge because Flutter's build already
  /// places Dart and explicitly declared notice files in the license registry.
  static void registerWith() {}
}
