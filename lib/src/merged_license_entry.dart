import 'package:flutter/foundation.dart';

/// One license text and the packages to which it applies.
///
/// [packages] is an unmodifiable snapshot. The collected [text] is preserved.
@immutable
final class MergedLicenseEntry {
  /// Creates a license entry from [packages] and [text].
  MergedLicenseEntry({required Iterable<String> packages, required this.text})
    : packages = List<String>.unmodifiable(packages);

  /// Package or component names covered by [text].
  final List<String> packages;

  /// The collected license text, notice text, or upstream license URL.
  final String text;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MergedLicenseEntry &&
            listEquals(other.packages, packages) &&
            other.text == text;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(packages), text);

  @override
  String toString() {
    return 'MergedLicenseEntry(packages: $packages, text: ${text.length} chars)';
  }
}
