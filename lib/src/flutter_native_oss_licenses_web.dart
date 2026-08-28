import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Web registration for the Flutter-only license implementation.
final class FlutterNativeOssLicensesWeb {
  const FlutterNativeOssLicensesWeb._();

  /// Registers the Web implementation.
  ///
  /// No platform bridge is needed because Flutter Web exposes its generated
  /// notice asset through Flutter's license registry.
  static void registerWith(Registrar registrar) {}
}
