import 'dart:io';
import 'dart:isolate';

import 'package:flutter_native_oss_licenses/src/setup/setup_command.dart';

Future<void> main(List<String> arguments) async {
  final packageLibrary = await Isolate.resolvePackageUri(
    Uri.parse(
      'package:flutter_native_oss_licenses/flutter_native_oss_licenses.dart',
    ),
  );
  if (packageLibrary == null || packageLibrary.scheme != 'file') {
    stderr.writeln('Could not locate the flutter_native_oss_licenses package.');
    exitCode = 2;
    return;
  }

  final packageRoot = File.fromUri(packageLibrary).parent.parent;
  final command = SetupCommand(
    projectRoot: Directory.current,
    packageRoot: packageRoot,
  );

  try {
    final result = switch (arguments) {
      [] => await command.install(),
      ['--check'] => await command.check(),
      ['--uninstall'] => await command.uninstall(),
      _ => throw const SetupException(
        'Usage: dart run flutter_native_oss_licenses:setup '
        '[--check|--uninstall]',
      ),
    };
    for (final message in result.messages) {
      stdout.writeln(message);
    }
    if (!result.success) {
      exitCode = 1;
    }
  } on SetupException catch (error) {
    stderr.writeln(error.message);
    exitCode = 2;
  } on FileSystemException catch (error) {
    stderr.writeln(error.message);
    exitCode = 2;
  }
}
