import 'dart:io';

const _googlePluginId = 'com.google.android.gms.oss-licenses-plugin';
const _googlePluginModule = 'com.google.android.gms:oss-licenses-plugin:0.13.0';
const _settingsMarkerStart =
    '// flutter_native_oss_licenses plugin resolution:start';
const _settingsMarkerEnd =
    '// flutter_native_oss_licenses plugin resolution:end';
const _appPluginMarkerStart = '// flutter_native_oss_licenses plugin:start';
const _appPluginMarkerEnd = '// flutter_native_oss_licenses plugin:end';
const _collectorMarkerStart = '// flutter_native_oss_licenses collector:start';
const _collectorMarkerEnd = '// flutter_native_oss_licenses collector:end';
const _xcodePhaseId = 'F1055A1C3E4E4D87A51CE001';
const _xcodePhaseName = 'Flutter Native OSS Licenses';

/// A setup failure caused by an unsupported or inconsistent host project.
final class SetupException implements Exception {
  const SetupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The outcome of setup, validation, or removal.
final class SetupResult {
  const SetupResult({required this.success, required this.messages});

  final bool success;
  final List<String> messages;
}

/// Installs the Android, iOS, and macOS build integration into one Flutter app.
final class SetupCommand {
  SetupCommand({required this.projectRoot, required this.packageRoot});

  final Directory projectRoot;
  final Directory packageRoot;

  Future<SetupResult> install() async {
    _validateFlutterProject();
    final messages = <String>[];
    if (_hasAndroidProject) {
      await _installAndroid();
      messages.add('Android build integration is installed.');
    }
    if (_hasAppleProject('ios')) {
      await _installApple('ios');
      messages.add(
        'iOS build integration is installed '
        '(${_appleDependencyMode('ios')}).',
      );
    }
    if (_hasAppleProject('macos')) {
      await _installApple('macos');
      messages.add(
        'macOS build integration is installed '
        '(${_appleDependencyMode('macos')}).',
      );
    }
    if (messages.isEmpty) {
      final flutterOnlyPlatforms = _detectedFlutterOnlyPlatforms;
      if (flutterOnlyPlatforms.isNotEmpty) {
        return SetupResult(
          success: true,
          messages: [_flutterOnlySetupMessage(flutterOnlyPlatforms)],
        );
      }
      throw const SetupException(
        'No supported Android, iOS, macOS, Web, Linux, or Windows '
        'application project was found.',
      );
    }
    return SetupResult(success: true, messages: messages);
  }

  Future<SetupResult> check() async {
    _validateFlutterProject();
    final issues = <String>[];
    if (_hasAndroidProject) {
      await _checkAndroid(issues);
    }
    if (_hasAppleProject('ios')) {
      await _checkApple('ios', issues);
    }
    if (_hasAppleProject('macos')) {
      await _checkApple('macos', issues);
    }
    if (!_hasAutomaticProject) {
      final flutterOnlyPlatforms = _detectedFlutterOnlyPlatforms;
      if (flutterOnlyPlatforms.isNotEmpty) {
        return SetupResult(
          success: true,
          messages: [_flutterOnlySetupMessage(flutterOnlyPlatforms)],
        );
      }
      issues.add(
        'No supported Android, iOS, macOS, Web, Linux, or Windows '
        'application project was found.',
      );
    }
    if (issues.isNotEmpty) {
      return SetupResult(success: false, messages: issues);
    }
    return const SetupResult(
      success: true,
      messages: ['flutter_native_oss_licenses build integration is current.'],
    );
  }

  Future<SetupResult> uninstall() async {
    _validateFlutterProject();
    final messages = <String>[];
    if (_hasAndroidProject) {
      final settings = _singleGradleFile('android/settings.gradle');
      final appBuild = _singleGradleFile('android/app/build.gradle');
      await _removeMarkedBlock(
        settings,
        _settingsMarkerStart,
        _settingsMarkerEnd,
      );
      await _removeMarkedBlock(
        appBuild,
        _appPluginMarkerStart,
        _appPluginMarkerEnd,
      );
      await _removeMarkedBlock(
        appBuild,
        _collectorMarkerStart,
        _collectorMarkerEnd,
      );
      final copiedGradle = _file('android/flutter_native_oss_licenses.gradle');
      if (await copiedGradle.exists()) {
        await copiedGradle.delete();
      }
      messages.add('Removed Android build integration.');
    }
    if (_hasAppleProject('ios')) {
      await _uninstallApple('ios');
      messages.add('Removed iOS build integration.');
    }
    if (_hasAppleProject('macos')) {
      await _uninstallApple('macos');
      messages.add('Removed macOS build integration.');
    }
    if (messages.isEmpty && _detectedFlutterOnlyPlatforms.isNotEmpty) {
      messages.add(
        'No build integration is installed for '
        '${_formatPlatformList(_detectedFlutterOnlyPlatforms)}.',
      );
    }
    return SetupResult(success: true, messages: messages);
  }

  bool get _hasAndroidProject => _directory('android/app').existsSync();

  bool _hasAppleProject(String platform) =>
      _file('$platform/Runner.xcodeproj/project.pbxproj').existsSync();

  bool get _hasAutomaticProject =>
      _hasAndroidProject ||
      _hasAppleProject('ios') ||
      _hasAppleProject('macos');

  List<String> get _detectedFlutterOnlyPlatforms => [
    if (_directory('web').existsSync()) 'Web',
    if (_directory('linux').existsSync()) 'Linux',
    if (_directory('windows').existsSync()) 'Windows',
  ];

  void _validateFlutterProject() {
    final pubspec = _file('pubspec.yaml');
    if (!pubspec.existsSync() ||
        !pubspec.readAsStringSync().contains('flutter:')) {
      throw SetupException(
        '${projectRoot.path} is not a Flutter project root with a pubspec.yaml.',
      );
    }
  }

  Future<void> _installAndroid() async {
    final settings = _singleGradleFile('android/settings.gradle');
    final appBuild = _singleGradleFile('android/app/build.gradle');
    final kotlinSettings = settings.path.endsWith('.kts');
    final kotlinApp = appBuild.path.endsWith('.kts');

    var settingsText = await settings.readAsString();
    if (!settingsText.contains(_googlePluginModule)) {
      final blockEnd = _findBlockEnd(settingsText, 'pluginManagement');
      final snippet = kotlinSettings
          ? '''
    $_settingsMarkerStart
    resolutionStrategy {
        eachPlugin {
            if (requested.id.id == "$_googlePluginId") {
                useModule("$_googlePluginModule")
            }
        }
    }
    $_settingsMarkerEnd
'''
          : '''
    $_settingsMarkerStart
    resolutionStrategy {
        eachPlugin {
            if (requested.id.id == '$_googlePluginId') {
                useModule('$_googlePluginModule')
            }
        }
    }
    $_settingsMarkerEnd
''';
      settingsText = settingsText.replaceRange(blockEnd, blockEnd, snippet);
      await settings.writeAsString(settingsText);
    }

    var appText = await appBuild.readAsString();
    if (!appText.contains(_googlePluginId)) {
      final blockEnd = _findBlockEnd(appText, 'plugins');
      final snippet = kotlinApp
          ? '''
    $_appPluginMarkerStart
    id("$_googlePluginId")
    $_appPluginMarkerEnd
'''
          : '''
    $_appPluginMarkerStart
    id '$_googlePluginId'
    $_appPluginMarkerEnd
''';
      appText = appText.replaceRange(blockEnd, blockEnd, snippet);
    }
    if (!appText.contains(_collectorMarkerStart)) {
      final applyLine = kotlinApp
          ? 'apply(from = rootProject.file("flutter_native_oss_licenses.gradle"))'
          : "apply from: rootProject.file('flutter_native_oss_licenses.gradle')";
      appText =
          '${appText.trimRight()}\n\n'
          '$_collectorMarkerStart\n'
          '$applyLine\n'
          '$_collectorMarkerEnd\n';
    }
    await appBuild.writeAsString(appText);
    await _copyTemplate(
      'flutter_native_oss_licenses.gradle',
      _file('android/flutter_native_oss_licenses.gradle'),
    );
  }

  Future<void> _checkAndroid(List<String> issues) async {
    final settings = _singleGradleFile('android/settings.gradle');
    final appBuild = _singleGradleFile('android/app/build.gradle');
    final settingsText = await settings.readAsString();
    final appText = await appBuild.readAsString();
    if (!settingsText.contains(_googlePluginModule)) {
      issues.add('Android settings do not resolve $_googlePluginId 0.13.0.');
    }
    if (!appText.contains(_googlePluginId)) {
      issues.add('Android app does not apply $_googlePluginId.');
    }
    if (!appText.contains(_collectorMarkerStart)) {
      issues.add('Android app does not apply the generated-assets collector.');
    }
    await _checkTemplate(
      'flutter_native_oss_licenses.gradle',
      _file('android/flutter_native_oss_licenses.gradle'),
      issues,
    );
  }

  Future<void> _installApple(String platform) async {
    final projectFile = _file('$platform/Runner.xcodeproj/project.pbxproj');
    final project = await projectFile.readAsString();
    await projectFile.writeAsString(_addXcodePhase(project));
    final integration = _directory('$platform/FlutterNativeOssLicenses');
    await integration.create(recursive: true);
    await _copyTemplate(
      'collect_licenses.sh',
      File('${integration.path}/collect_licenses.sh'),
    );
    await _copyTemplate(
      'collect_licenses.swift',
      File('${integration.path}/collect_licenses.swift'),
    );
  }

  Future<void> _checkApple(String platform, List<String> issues) async {
    final projectFile = _file('$platform/Runner.xcodeproj/project.pbxproj');
    final project = await projectFile.readAsString();
    if (!project.contains('$_xcodePhaseId /* $_xcodePhaseName */') ||
        !project.contains('FlutterNativeOssLicenses/collect_licenses.sh')) {
      issues.add(
        'The ${_applePlatformName(platform)} Runner target is missing the '
        'native-license Xcode phase.',
      );
    }
    await _checkTemplate(
      'collect_licenses.sh',
      _file('$platform/FlutterNativeOssLicenses/collect_licenses.sh'),
      issues,
    );
    await _checkTemplate(
      'collect_licenses.swift',
      _file('$platform/FlutterNativeOssLicenses/collect_licenses.swift'),
      issues,
    );
  }

  Future<void> _uninstallApple(String platform) async {
    final projectFile = _file('$platform/Runner.xcodeproj/project.pbxproj');
    if (await projectFile.exists()) {
      final updated = _removeXcodePhase(await projectFile.readAsString());
      await projectFile.writeAsString(updated);
    }
    final integration = _directory('$platform/FlutterNativeOssLicenses');
    for (final name in ['collect_licenses.sh', 'collect_licenses.swift']) {
      final file = File('${integration.path}/$name');
      if (await file.exists()) {
        await file.delete();
      }
    }
    if (await integration.exists() && await integration.list().isEmpty) {
      await integration.delete();
    }
  }

  String _appleDependencyMode(String platform) {
    final hasPods =
        _file('$platform/Podfile').existsSync() ||
        _directory('$platform/Pods').existsSync();
    final project = _file(
      '$platform/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    final hasSwiftPackages =
        project.contains('packageProductDependencies') ||
        project.contains('XCLocalSwiftPackageReference');
    if (hasPods && hasSwiftPackages) {
      return 'CocoaPods + Swift Package Manager';
    }
    if (hasPods) {
      return 'CocoaPods';
    }
    if (hasSwiftPackages) {
      return 'Swift Package Manager';
    }
    return 'build-time auto-detection';
  }

  String _applePlatformName(String platform) =>
      platform == 'ios' ? 'iOS' : 'macOS';

  String _flutterOnlySetupMessage(List<String> platforms) =>
      'No build integration is required for ${_formatPlatformList(platforms)}. '
      "Flutter's license registry is used directly.";

  String _formatPlatformList(List<String> platforms) {
    if (platforms.length == 1) {
      return platforms.single;
    }
    if (platforms.length == 2) {
      return '${platforms.first} and ${platforms.last}';
    }
    return '${platforms.take(platforms.length - 1).join(', ')}, and '
        '${platforms.last}';
  }

  Future<void> _copyTemplate(String name, File destination) async {
    final source = File('${packageRoot.path}/tool/templates/$name');
    if (!await source.exists()) {
      throw SetupException('Package template is missing: ${source.path}');
    }
    await destination.parent.create(recursive: true);
    await source.copy(destination.path);
  }

  Future<void> _checkTemplate(
    String name,
    File destination,
    List<String> issues,
  ) async {
    final source = File('${packageRoot.path}/tool/templates/$name');
    if (!await destination.exists()) {
      issues.add('Generated integration file is missing: ${destination.path}');
      return;
    }
    if (!await source.exists()) {
      issues.add('Package template is missing: ${source.path}');
      return;
    }
    final expected = await source.readAsBytes();
    final actual = await destination.readAsBytes();
    if (!_equalBytes(expected, actual)) {
      issues.add('Generated integration file is stale: ${destination.path}');
    }
  }

  bool _equalBytes(List<int> left, List<int> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index += 1) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }

  File _singleGradleFile(String pathWithoutExtension) {
    final kotlin = _file('$pathWithoutExtension.kts');
    final groovy = _file(pathWithoutExtension);
    final candidates = [
      kotlin,
      groovy,
    ].where((file) => file.existsSync()).toList();
    if (candidates.length != 1) {
      throw SetupException(
        'Expected exactly one $pathWithoutExtension or $pathWithoutExtension.kts.',
      );
    }
    return candidates.single;
  }

  int _findBlockEnd(String source, String blockName) {
    final match = RegExp(
      '\\b${RegExp.escape(blockName)}\\s*\\{',
    ).firstMatch(source);
    if (match == null) {
      throw SetupException('Could not find the $blockName block.');
    }
    final openingBrace = source.indexOf('{', match.start);
    var depth = 0;
    for (var index = openingBrace; index < source.length; index += 1) {
      if (source.codeUnitAt(index) == 0x7B) {
        depth += 1;
      } else if (source.codeUnitAt(index) == 0x7D) {
        depth -= 1;
        if (depth == 0) {
          return index;
        }
      }
    }
    throw SetupException('The $blockName block has unbalanced braces.');
  }

  String _addXcodePhase(String source) {
    if (source.contains('$_xcodePhaseId /* $_xcodePhaseName */')) {
      return source;
    }
    if (source.contains('/* $_xcodePhaseName */')) {
      throw const SetupException(
        'An Xcode build phase named Flutter Native OSS Licenses already exists '
        'but is not managed by this package.',
      );
    }

    final targetPattern = RegExp(
      r'([A-F0-9]{24} /\* Runner \*/ = \{\s*isa = PBXNativeTarget;[\s\S]*?buildPhases = \()([\s\S]*?)(\n\s*\);)',
    );
    final target = targetPattern.firstMatch(source);
    if (target == null) {
      throw const SetupException(
        'Could not find a standard Runner application target in project.pbxproj.',
      );
    }
    final phases = target.group(2)!;
    final reference = '\n\t\t\t\t$_xcodePhaseId /* $_xcodePhaseName */,';
    final thinBinary = RegExp(r'\n\s*[A-F0-9]{24} /\* Thin Binary \*/,');
    final thinMatch = thinBinary.firstMatch(phases);
    final updatedPhases = thinMatch == null
        ? '$phases$reference'
        : phases.replaceRange(thinMatch.end, thinMatch.end, reference);
    var updated = source.replaceRange(
      target.start,
      target.end,
      '${target.group(1)}$updatedPhases${target.group(3)}',
    );

    const object =
        '''
\t\t$_xcodePhaseId /* $_xcodePhaseName */ = {
\t\t\tisa = PBXShellScriptBuildPhase;
\t\t\talwaysOutOfDate = 1;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\tinputPaths = (
\t\t\t);
\t\t\tname = "$_xcodePhaseName";
\t\t\toutputPaths = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t\tshellPath = /bin/sh;
\t\t\tshellScript = "/bin/sh \\"\$SRCROOT/FlutterNativeOssLicenses/collect_licenses.sh\\"";
\t\t\tshowEnvVarsInLog = 0;
\t\t};
''';
    const sectionEnd = '/* End PBXShellScriptBuildPhase section */';
    final sectionIndex = updated.indexOf(sectionEnd);
    if (sectionIndex < 0) {
      throw const SetupException(
        'Could not find the PBXShellScriptBuildPhase section in project.pbxproj.',
      );
    }
    updated = updated.replaceRange(sectionIndex, sectionIndex, object);
    return updated;
  }

  String _removeXcodePhase(String source) {
    var updated = source.replaceAll(
      RegExp(
        '\\n\\s*${RegExp.escape(_xcodePhaseId)} /\\* '
        '${RegExp.escape(_xcodePhaseName)} \\*/,',
      ),
      '',
    );
    updated = updated.replaceAll(
      RegExp(
        '\\n\\s*${RegExp.escape(_xcodePhaseId)} /\\* '
        '${RegExp.escape(_xcodePhaseName)} \\*/ = \\{[\\s\\S]*?\\n\\s*\\};',
      ),
      '',
    );
    return updated;
  }

  Future<void> _removeMarkedBlock(File file, String start, String end) async {
    if (!await file.exists()) {
      return;
    }
    final source = await file.readAsString();
    final pattern = RegExp(
      '\\n?\\s*${RegExp.escape(start)}[\\s\\S]*?'
      '${RegExp.escape(end)}\\s*\\n?',
    );
    await file.writeAsString(source.replaceAll(pattern, '\n'));
  }

  File _file(String relativePath) => File('${projectRoot.path}/$relativePath');

  Directory _directory(String relativePath) =>
      Directory('${projectRoot.path}/$relativePath');
}
