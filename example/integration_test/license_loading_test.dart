import 'package:flutter/foundation.dart';
import 'package:flutter_native_oss_licenses/flutter_native_oss_licenses.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loads the native bridge and merges registered notices', (
    tester,
  ) async {
    LicenseRegistry.addLicense(() async* {
      yield const LicenseEntryWithLineBreaks([
        'integration_test_notice',
      ], 'Integration test notice');
    });

    final entries = await loadMergedLicenses();

    expect(entries, isNotEmpty);
    expect(
      entries.expand((entry) => entry.packages),
      contains('integration_test_notice'),
    );
  });
}
