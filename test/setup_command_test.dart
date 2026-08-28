import 'dart:io';

import 'package:flutter_native_oss_licenses/src/setup/setup_command.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory project;
  late Directory packageRoot;

  setUp(() async {
    project = await Directory.systemTemp.createTemp('native_oss_setup_test_');
    packageRoot = Directory.current;
    await File('${project.path}/pubspec.yaml').writeAsString('''
name: fixture
dependencies:
  flutter:
    sdk: flutter
flutter:
  uses-material-design: true
''');
  });

  tearDown(() async {
    if (await project.exists()) {
      await project.delete(recursive: true);
    }
  });

  test(
    'installs, checks, reinstalls, and uninstalls Android and Apple files',
    () async {
      await _copyFixtureFile(
        'example/android/settings.gradle.kts',
        '${project.path}/android/settings.gradle.kts',
      );
      await _copyFixtureFile(
        'example/android/app/build.gradle.kts',
        '${project.path}/android/app/build.gradle.kts',
      );
      await _copyFixtureFile(
        'example/ios/Runner.xcodeproj/project.pbxproj',
        '${project.path}/ios/Runner.xcodeproj/project.pbxproj',
      );
      await _copyFixtureFile(
        'example/macos/Runner.xcodeproj/project.pbxproj',
        '${project.path}/macos/Runner.xcodeproj/project.pbxproj',
      );
      final command = SetupCommand(
        projectRoot: project,
        packageRoot: packageRoot,
      );

      expect((await command.install()).success, isTrue);
      expect((await command.check()).success, isTrue);
      final firstSettings = await File(
        '${project.path}/android/settings.gradle.kts',
      ).readAsString();
      final firstProject = await File(
        '${project.path}/ios/Runner.xcodeproj/project.pbxproj',
      ).readAsString();
      final firstMacosProject = await File(
        '${project.path}/macos/Runner.xcodeproj/project.pbxproj',
      ).readAsString();

      await command.install();
      expect(
        await File(
          '${project.path}/android/settings.gradle.kts',
        ).readAsString(),
        firstSettings,
      );
      expect(
        await File(
          '${project.path}/ios/Runner.xcodeproj/project.pbxproj',
        ).readAsString(),
        firstProject,
      );
      expect(
        await File(
          '${project.path}/macos/Runner.xcodeproj/project.pbxproj',
        ).readAsString(),
        firstMacosProject,
      );
      expect(
        RegExp(
          'com.google.android.gms.oss-licenses-plugin',
        ).allMatches(firstSettings).length,
        2,
      );
      expect(
        RegExp('Flutter Native OSS Licenses').allMatches(firstProject).length,
        3,
      );
      expect(
        RegExp(
          'Flutter Native OSS Licenses',
        ).allMatches(firstMacosProject).length,
        3,
      );

      await command.uninstall();
      expect(
        await File(
          '${project.path}/android/settings.gradle.kts',
        ).readAsString(),
        isNot(contains('flutter_native_oss_licenses plugin resolution')),
      );
      expect(
        await File(
          '${project.path}/ios/Runner.xcodeproj/project.pbxproj',
        ).readAsString(),
        isNot(contains('Flutter Native OSS Licenses')),
      );
      expect(
        await File(
          '${project.path}/macos/Runner.xcodeproj/project.pbxproj',
        ).readAsString(),
        isNot(contains('Flutter Native OSS Licenses')),
      );
      expect(
        File(
          '${project.path}/android/flutter_native_oss_licenses.gradle',
        ).existsSync(),
        isFalse,
      );
    },
  );

  test('supports Groovy Gradle projects', () async {
    await File(
      '${project.path}/android/settings.gradle',
    ).create(recursive: true);
    await File('${project.path}/android/settings.gradle').writeAsString('''
pluginManagement {
  repositories { google(); mavenCentral(); gradlePluginPortal() }
}
include ':app'
''');
    await File(
      '${project.path}/android/app/build.gradle',
    ).create(recursive: true);
    await File('${project.path}/android/app/build.gradle').writeAsString('''
plugins {
  id 'com.android.application'
}
''');
    final command = SetupCommand(
      projectRoot: project,
      packageRoot: packageRoot,
    );

    await command.install();

    expect((await command.check()).success, isTrue);
    expect(
      await File('${project.path}/android/app/build.gradle').readAsString(),
      allOf(
        contains("id 'com.google.android.gms.oss-licenses-plugin'"),
        contains(
          "apply from: rootProject.file('flutter_native_oss_licenses.gradle')",
        ),
      ),
    );
  });

  test(
    '--check reports a stale copied integration without changing it',
    () async {
      await _copyFixtureFile(
        'example/android/settings.gradle.kts',
        '${project.path}/android/settings.gradle.kts',
      );
      await _copyFixtureFile(
        'example/android/app/build.gradle.kts',
        '${project.path}/android/app/build.gradle.kts',
      );
      final command = SetupCommand(
        projectRoot: project,
        packageRoot: packageRoot,
      );
      await command.install();
      final generated = File(
        '${project.path}/android/flutter_native_oss_licenses.gradle',
      );
      await generated.writeAsString('stale');

      final result = await command.check();

      expect(result.success, isFalse);
      expect(result.messages, contains(contains('is stale')));
      expect(await generated.readAsString(), 'stale');
    },
  );

  test('needs no setup for Web, Linux, and Windows projects', () async {
    for (final platform in ['web', 'linux', 'windows']) {
      await Directory('${project.path}/$platform').create(recursive: true);
    }
    final command = SetupCommand(
      projectRoot: project,
      packageRoot: packageRoot,
    );

    final installed = await command.install();
    final checked = await command.check();
    final uninstalled = await command.uninstall();

    expect(installed.success, isTrue);
    expect(
      installed.messages.single,
      contains('No build integration is required for Web, Linux, and Windows'),
    );
    expect(checked.success, isTrue);
    expect(uninstalled.success, isTrue);
    expect(
      uninstalled.messages.single,
      contains('No build integration is installed'),
    );
  });
}

Future<void> _copyFixtureFile(String sourcePath, String destinationPath) async {
  final destination = File(destinationPath);
  await destination.parent.create(recursive: true);
  await File(sourcePath).copy(destination.path);
}
