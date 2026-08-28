import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'collects CocoaPods plus current and legacy remote SwiftPM pins',
    () async {
      final fixture = await _SwiftCollectorFixture.create();
      addTearDown(fixture.dispose);

      final directRevision = await fixture.createCheckout(
        directoryName: 'repository-basename',
        remote: 'https://example.com/RepositoryName.git',
        legalFiles: {
          'LICENSE': 'Direct license',
          'NOTICE.txt': 'Direct notice',
        },
      );
      final transitiveRevision = await fixture.createCheckout(
        directoryName: 'not-the-package-identity',
        remote: 'git@example.com:Transitive.git',
        legalFiles: {'COPYING': 'Transitive license'},
      );
      await fixture.writeCurrentResolvedFile(directRevision: directRevision);
      await fixture.writeLegacyResolvedFile(
        transitiveRevision: transitiveRevision,
      );

      final result = await fixture.run();

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      final payload = (jsonDecode(await fixture.output.readAsString()) as List)
          .cast<Map<String, Object?>>();
      expect(payload, [
        {
          'packages': ['DifferentIdentity'],
          'text': 'Direct license\n\nDirect notice',
        },
        {
          'packages': ['LegacyTransitive'],
          'text': 'Transitive license',
        },
        {
          'packages': ['NativePod'],
          'text': 'Native pod license',
        },
      ]);
    },
    skip: !Platform.isMacOS,
  );

  test(
    'fails when a remote SwiftPM checkout has no legal file at its root',
    () async {
      final fixture = await _SwiftCollectorFixture.create();
      addTearDown(fixture.dispose);
      final revision = await fixture.createCheckout(
        directoryName: 'repository-basename',
        remote: 'https://example.com/RepositoryName.git',
        legalFiles: {'README.md': 'No legal text'},
      );
      await fixture.writeCurrentResolvedFile(directRevision: revision);

      final result = await fixture.run();

      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('has no root legal file'));
    },
    skip: !Platform.isMacOS,
  );

  test(
    'fails when a checkout revision differs from the resolved pin',
    () async {
      final fixture = await _SwiftCollectorFixture.create();
      addTearDown(fixture.dispose);
      await fixture.createCheckout(
        directoryName: 'repository-basename',
        remote: 'https://example.com/RepositoryName.git',
        legalFiles: {'LICENSE': 'License'},
      );
      await fixture.writeCurrentResolvedFile(
        directRevision: List.filled(40, '0').join(),
      );

      final result = await fixture.run();

      expect(result.exitCode, isNot(0));
      expect(
        result.stderr,
        contains('matches both its remote URL and pinned revision'),
      );
    },
    skip: !Platform.isMacOS,
  );

  test('collects remote SwiftPM pins from a macOS project', () async {
    final fixture = await _SwiftCollectorFixture.create(applePlatform: 'macos');
    addTearDown(fixture.dispose);
    final revision = await fixture.createCheckout(
      directoryName: 'repository-basename',
      remote: 'https://example.com/RepositoryName.git',
      legalFiles: {'LICENSE': 'macOS package license'},
    );
    await fixture.writeCurrentResolvedFile(directRevision: revision);

    final result = await fixture.run();

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    final payload = (jsonDecode(await fixture.output.readAsString()) as List)
        .cast<Map<String, Object?>>();
    expect(payload, [
      {
        'packages': ['DifferentIdentity'],
        'text': 'macOS package license',
      },
      {
        'packages': ['NativePod'],
        'text': 'Native pod license',
      },
    ]);
  }, skip: !Platform.isMacOS);
}

final class _SwiftCollectorFixture {
  _SwiftCollectorFixture(this.root, this.applePlatform);

  final Directory root;
  final String applePlatform;

  Directory get project => Directory('${root.path}/project');
  Directory get sourcePackages => Directory('${root.path}/SourcePackages');
  File get output => File('${root.path}/output/licenses.json');
  File get acknowledgements => File('${root.path}/acknowledgements.plist');

  static Future<_SwiftCollectorFixture> create({
    String applePlatform = 'ios',
  }) async {
    final root = await Directory.systemTemp.createTemp('swift_oss_collector_');
    final fixture = _SwiftCollectorFixture(root, applePlatform);
    await fixture.sourcePackages.create(recursive: true);
    await Directory(
      '${fixture.project.path}/$applePlatform',
    ).create(recursive: true);
    await File(
      '${fixture.project.path}/.flutter-plugins-dependencies',
    ).writeAsString(
      jsonEncode({
        'plugins': {
          'ios': applePlatform == 'ios'
              ? [
                  {'name': 'FlutterPluginRoot'},
                ]
              : <Object?>[],
          'macos': applePlatform == 'macos'
              ? [
                  {'name': 'FlutterPluginRoot'},
                ]
              : <Object?>[],
        },
      }),
    );
    await fixture.acknowledgements.writeAsString('''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>PreferenceSpecifiers</key>
  <array>
    <dict><key>Type</key><string>PSGroupSpecifier</string><key>Title</key><string>Acknowledgements</string><key>FooterText</key><string>This application makes use of the following third party libraries:</string></dict>
    <dict><key>Type</key><string>PSGroupSpecifier</string><key>Title</key><string>FlutterPluginRoot</string><key>FooterText</key><string>Flutter plugin license</string></dict>
    <dict><key>Type</key><string>PSGroupSpecifier</string><key>Title</key><string>NativePod</string><key>FooterText</key><string>Native pod license</string></dict>
    <dict><key>Type</key><string>PSGroupSpecifier</string><key>Title</key><string></string><key>FooterText</key><string>Generated by CocoaPods - https://cocoapods.org</string></dict>
  </array>
</dict>
</plist>
''');
    return fixture;
  }

  Future<String> createCheckout({
    required String directoryName,
    required String remote,
    required Map<String, String> legalFiles,
  }) async {
    final checkout = Directory(
      '${sourcePackages.path}/checkouts/$directoryName',
    );
    await checkout.create(recursive: true);
    await _git(checkout, ['init']);
    await _git(checkout, ['remote', 'add', 'origin', remote]);
    for (final entry in legalFiles.entries) {
      await File('${checkout.path}/${entry.key}').writeAsString(entry.value);
    }
    await _git(checkout, ['add', '.']);
    await _git(checkout, [
      '-c',
      'user.name=Fixture',
      '-c',
      'user.email=fixture@example.com',
      'commit',
      '-m',
      'fixture',
    ]);
    return (await _git(checkout, [
      'rev-parse',
      'HEAD',
    ])).stdout.toString().trim();
  }

  Future<void> writeCurrentResolvedFile({
    required String directRevision,
  }) async {
    final file = File(
      '${project.path}/$applePlatform/Runner.xcodeproj/project.xcworkspace/'
      'xcshareddata/swiftpm/Package.resolved',
    );
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'originHash': 'fixture',
        'pins': [
          {
            'identity': 'DifferentIdentity',
            'kind': 'remoteSourceControl',
            'location': 'https://example.com/RepositoryName.git',
            'state': {'revision': directRevision, 'version': '1.0.0'},
          },
          {
            'identity': 'LocalPlugin',
            'kind': 'localSourceControl',
            'location': '../FlutterGeneratedPluginSwiftPackage',
            'state': {'revision': directRevision},
          },
        ],
        'version': 3,
      }),
    );
  }

  Future<void> writeLegacyResolvedFile({
    required String transitiveRevision,
  }) async {
    final file = File(
      '${project.path}/$applePlatform/Runner.xcworkspace/'
      'xcshareddata/swiftpm/Package.resolved',
    );
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'object': {
          'pins': [
            {
              'package': 'LegacyTransitive',
              'repositoryURL': 'git@example.com:Transitive.git',
              'state': {'revision': transitiveRevision, 'version': '2.0.0'},
            },
          ],
        },
        'version': 1,
      }),
    );
  }

  Future<ProcessResult> run() {
    return Process.run(
      'xcrun',
      [
        '--sdk',
        'macosx',
        'swift',
        '${Directory.current.path}/tool/templates/collect_licenses.swift',
        acknowledgements.path,
        sourcePackages.path,
        project.path,
        '${project.path}/$applePlatform',
        output.path,
      ],
      environment: {
        ...Platform.environment,
        'CLANG_MODULE_CACHE_PATH': '${root.path}/module-cache',
      },
    );
  }

  Future<void> dispose() => root.delete(recursive: true);

  Future<ProcessResult> _git(
    Directory directory,
    List<String> arguments,
  ) async {
    final result = await Process.run(
      'git',
      arguments,
      workingDirectory: directory.path,
    );
    if (result.exitCode != 0) {
      throw StateError('git ${arguments.join(' ')} failed: ${result.stderr}');
    }
    return result;
  }
}
