import 'dart:io';
import 'package:path/path.dart' as p;
import 'colors.dart';
import 'prompts.dart';
import 'project_creator.dart';

// ─── Detection result models ────────────────────────────────────────────────

class FlutterInfo {
  final bool available;
  final String version;
  final String channel;
  final String dartVersion;
  final String path;
  final bool isViaFvm;  // true if detected via 'fvm flutter'

  const FlutterInfo({
    required this.available,
    this.version = '',
    this.channel = '',
    this.dartVersion = '',
    this.path = '',
    this.isViaFvm = false,
  });
}

class FvmInfo {
  final bool available;
  final String fvmVersion;
  final List<String> installedVersions;
  final String? activeVersion;

  const FvmInfo({
    required this.available,
    this.fvmVersion = '',
    this.installedVersions = const [],
    this.activeVersion,
  });
}

class EnvironmentInfo {
  final FlutterInfo flutter;
  final FvmInfo fvm;
  const EnvironmentInfo({required this.flutter, required this.fvm});
}

// ─── Internal runner models ──────────────────────────────────────────────────

class _RunnerOption {
  final String label;
  final String command;
  final bool isFvm;
  final String version;
  _RunnerOption({
    required this.label,
    required this.command,
    required this.isFvm,
    required this.version,
  });
}

class _RunnerInfo {
  final String command;
  final bool isFvm;
  final String version;
  final String label;
  _RunnerInfo({
    required this.command,
    required this.isFvm,
    required this.version,
    required this.label,
  });
}

// ─── CLI Runner ──────────────────────────────────────────────────────────────

class CliRunner {
  late EnvironmentInfo _env;

  Future<void> run(List<String> args) async {
    printBanner();

    stdout.write(gray('  Scanning environment...'));
    _env = await _detectEnvironment();
    stdout.write('\r                                    \r');

    if (args.isNotEmpty && (args[0] == '--help' || args[0] == '-h')) {
      _printHelp();
      return;
    }

    if (args.isNotEmpty && (args[0] == '--version' || args[0] == '-v')) {
      _printVersion();
      return;
    }

    if (args.isNotEmpty && args[0] == 'doctor') {
      _printDoctor();
      return;
    }

    if (args.isEmpty || args[0] != 'create') {
      _printHelp();
      return;
    }

    await _runCreateFlow(args.skip(1).toList());
  }

  // ─── Environment Detection ──────────────────────────────────────────────

  Future<EnvironmentInfo> _detectEnvironment() async {
    final results = await Future.wait([_detectFlutter(), _detectFvm()]);
    return EnvironmentInfo(
      flutter: results[0] as FlutterInfo,
      fvm: results[1] as FvmInfo,
    );
  }

  Future<FlutterInfo> _detectFlutter() async {
    // Try system flutter first, then fvm flutter as fallback
    for (final flutterCmd in ['flutter', 'fvm flutter']) {
      final info = await _tryDetectFlutter(flutterCmd);
      if (info.available) return info;
    }
    return const FlutterInfo(available: false);
  }

  Future<FlutterInfo> _tryDetectFlutter(String flutterCmd) async {
    final isViaFvm = flutterCmd != 'flutter';

    // Try `flutter --version --machine` first (JSON output)
    var result = await _runCommandFull('$flutterCmd --version --machine');
    final machineOut = result.stderr.trim().isNotEmpty
        ? result.stderr
        : result.stdout; // some versions may write to stdout

    if (result.exitCode == 0 && machineOut.trim().isNotEmpty) {
      final versionMatch =
      RegExp(r'"frameworkVersion"\s*:\s*"([^"]+)"').firstMatch(machineOut);
      final channelMatch =
      RegExp(r'"channel"\s*:\s*"([^"]+)"').firstMatch(machineOut);
      final dartMatch =
      RegExp(r'"dartSdkVersion"\s*:\s*"([^"]+)"').firstMatch(machineOut);

      if (versionMatch != null) {
        final pathResult = await _resolveExecutablePath('flutter');
        return FlutterInfo(
          available: true,
          version: versionMatch.group(1) ?? 'unknown',
          channel: channelMatch?.group(1) ?? 'unknown',
          dartVersion: (dartMatch?.group(1) ?? 'unknown').split(' ').first,
          path: isViaFvm ? '(via FVM)' : pathResult,
          isViaFvm: isViaFvm,
        );
      }
    }

    // Fallback: plain text `flutter --version`
    result = await _runCommandFull('$flutterCmd --version');
    if (result.exitCode != 0 ||
        (result.stdout.trim().isEmpty && result.stderr.trim().isEmpty)) {
      return const FlutterInfo(available: false);
    }

    // Combine stdout+stderr for plain-text parsing
    final out = '${result.stdout}\n${result.stderr}';
    final versionMatch = RegExp(r'Flutter\s+(\d+\.\d+\.\d+\S*)').firstMatch(out);
    final channelMatch = RegExp(r'channel\s+(\S+)').firstMatch(out);
    final dartMatch =
    RegExp(r'Dart(?:\s+SDK(?:\s+version)?)?\s+(\d+\.\d+\.\d+\S*)').firstMatch(out);
    final pathResult = await _resolveExecutablePath('flutter');

    return FlutterInfo(
      available: versionMatch != null,
      version: versionMatch?.group(1) ?? 'unknown',
      channel: channelMatch?.group(1) ?? 'unknown',
      dartVersion: dartMatch?.group(1) ?? 'unknown',
      path: isViaFvm ? '(via FVM)' : pathResult,
      isViaFvm: isViaFvm,
    );
  }

  Future<FvmInfo> _detectFvm() async {
    final versionResult = await _runCommandFull('fvm --version');
    if (versionResult.exitCode != 0) return const FvmInfo(available: false);

    // FIX 4: version output may start with blank lines; skip them
    final fvmVersion = (versionResult.stdout.trim().isNotEmpty
        ? versionResult.stdout
        : versionResult.stderr)
        .trim()
        .split('\n')
        .map((l) => l.trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => 'unknown');

    final listResult = await _runCommandFull('fvm list');
    final installedVersions = <String>[];
    String? activeVersion;

    final listOut = listResult.exitCode == 0
        ? '${listResult.stdout}\n${listResult.stderr}'
        : '';

    if (listOut.trim().isNotEmpty) {
      // FIX 5: Improved FVM list parsing
      // FVM 3.x output columns: SDK Version | Channel | Release Date | Active
      // FVM 2.x output: lines with optional ✓ / → prefix
      for (final line in listOut.split('\n')) {
        final trimmed = line.trim();

        // Skip header/separator lines
        if (trimmed.isEmpty ||
            trimmed.startsWith('Cache') ||
            RegExp(r'^[─═\-─]+$').hasMatch(trimmed) ||
            trimmed.toLowerCase().startsWith('sdk version') ||
            trimmed.toLowerCase().startsWith('flutter sdk') ||
            trimmed.toLowerCase().startsWith('no sdk')) continue;

        // Extract version token (semver OR named channel like stable/beta/master/main)
        final vMatch = RegExp(
          r'(\d+\.\d+\.\d+(?:[+\-]\S*)?|stable|beta|dev|master|main)',
        ).firstMatch(trimmed);
        if (vMatch == null) continue;

        final v = vMatch.group(1)!;

        // Detect active markers used across FVM versions
        final isActive = trimmed.contains('✓') ||
            trimmed.contains('✔') ||
            trimmed.startsWith('→') ||
            trimmed.startsWith('▶') ||
            trimmed.contains('●') ||  // FVM 4.x uses bullet in Local/Global column
            RegExp(r'\bactive\b', caseSensitive: false).hasMatch(trimmed) ||
            trimmed.contains('(active)') ||
            trimmed.contains('* ');

        if (!installedVersions.contains(v)) {
          installedVersions.add(v);
        }
        if (isActive && activeVersion == null) activeVersion = v;
      }
    }

    return FvmInfo(
      available: true,
      fvmVersion: fvmVersion,
      installedVersions: installedVersions,
      activeVersion: activeVersion,
    );
  }

  // ─── Doctor ─────────────────────────────────────────────────────────────

  void _printDoctor() {
    print(cyan('  ═══════════════════════════════════════════════════'));
    print(cyan('                  ENVIRONMENT DOCTOR                  '));
    print(cyan('  ═══════════════════════════════════════════════════'));
    print('');

    final f = _env.flutter;
    if (f.available) {
      print(green('  ✔ Flutter') + gray(' detected'));
      print(gray('      Version : ') + white(f.version));
      print(gray('      Channel : ') + yellow(f.channel));
      print(gray('      Dart    : ') + cyan(f.dartVersion));
      if (f.path.isNotEmpty) print(gray('      Path    : ') + gray(f.path));
    } else {
      print(red('  ✘ Flutter not found'));
      print(gray('      → Install: https://flutter.dev/docs/get-started/install'));
    }

    print('');

    final fvm = _env.fvm;
    if (fvm.available) {
      print(green('  ✔ FVM') + gray(' v${fvm.fvmVersion}'));
      if (fvm.installedVersions.isEmpty) {
        print(gray('      No Flutter versions installed via FVM yet.'));
        print(gray('      → Run: ') + white('fvm install stable'));
      } else {
        print(gray('      Installed versions:'));
        for (final v in fvm.installedVersions) {
          final isActive = v == fvm.activeVersion;
          if (isActive) {
            print('      ${green('▶')} ${green(v)} ${gray('← active')}');
          } else {
            print('        ${white(v)}');
          }
        }
      }
    } else {
      print(yellow('  ⚠ FVM not installed'));
      print(gray('      → Install: dart pub global activate fvm'));
    }

    print('');

    if (!f.available) {
      print(red('  ✘ Flutter is required. Please install it first.'));
    } else {
      print(green('  ✔ Ready!') + gray(' Run: ') + cyan('sta create'));
    }
    print('');
  }

  // ─── Help ────────────────────────────────────────────────────────────────

  void _printEnvStatus() {
    final f = _env.flutter;
    final fvm = _env.fvm;
    print(gray('  ┌─ Environment ───────────────────────────────────────┐'));
    if (f.available) {
      print(gray('  │  ') +
          green('✔ Flutter ') +
          white(f.version) +
          gray(' · ') +
          yellow(f.channel) +
          gray(' channel · Dart ') +
          cyan(f.dartVersion));
    } else {
      print(gray('  │  ') + red('✘ Flutter not found in PATH'));
    }
    if (fvm.available) {
      final vCount = '${fvm.installedVersions.length} version(s) installed';
      final active = fvm.activeVersion != null
          ? gray(' · active: ') + green(fvm.activeVersion!)
          : '';
      print(gray('  │  ') +
          green('✔ FVM ') +
          white(fvm.fvmVersion) +
          gray(' · $vCount') +
          active);
    } else {
      print(gray('  │  ') + yellow('⚠ FVM not installed'));
    }
    print(gray('  └────────────────────────────────────────────────────┘'));
    print('');
  }

  void _printHelp() {
    _printEnvStatus();

    print(white('  Commands:'));
    print('');
    print('    ${cyan('sta create')} ${yellow('[project_name]')}');
    print(gray('      Interactively scaffold a new Flutter MVC project'));
    print('');
    print('    ${cyan('sta doctor')}');
    print(gray('      Show auto-detected Flutter & FVM environment info'));
    print('');
    print('    ${cyan('sta --version')}  ${gray('/')}  ${cyan('-v')}   Show STA CLI version');
    print('    ${cyan('sta --help')}     ${gray('/')}  ${cyan('-h')}   Show this screen');
    print('');

    print(white('  Examples:'));
    print('');
    print('    ${gray('\$')} ${cyan('sta create')}');
    print('    ${gray('\$')} ${cyan('sta create my_shop_app')}');
    print('    ${gray('\$')} ${cyan('sta doctor')}');
    print('');

    print(white('  Generated project features:'));
    print('');
    final features = [
      ('GetX', 'State management, routing, DI'),
      ('MVC', 'controller / model / repository / view / shared / core'),
      ('Network', 'HTTP service with auto token-refresh (401 handling)'),
      ('Auth', 'Splash → Sign In → Sign Up → Home'),
      ('Widgets', 'AppButton, AppTextField, OTP field, AppBar, Divider'),
      ('Theme', 'Light & Dark theme, AppColors, AppTheme'),
      ('Storage', 'GetStorage for local persistence'),
      ('Messenger', 'Toasts, top snackbar (success/error/info)'),
    ];
    for (final f in features) {
      print('    ${green('✔')} ${white(f.$1.padRight(12))} ${gray(f.$2)}');
    }
    print('');

    print(white('  Auto-added dependencies:'));
    print('');
    final deps = [
      'get', 'logger', 'top_snackbar_flutter', 'fluttertoast',
      'http', 'loading_animation_widget', 'get_storage', 'pinput',
    ];
    print('    ' + deps.map(cyan).join(gray('  ·  ')));
    print('');
  }

  void _printVersion() {
    _printEnvStatus();
    print(white('  STA CLI ') + cyan('v0.1.4'));
    print(gray('  Flutter project scaffolding CLI — built with Dart'));
    print('');
  }

  // ─── Create flow ─────────────────────────────────────────────────────────

  Future<void> _runCreateFlow(List<String> args) async {
    if (!_env.flutter.available) {
      printError('Flutter is not installed or not found in PATH.');
      printInfo('Install Flutter: https://flutter.dev/docs/get-started/install');
      exit(1);
    }

    _printEnvStatus();

    print(cyan('  ═══════════════════════════════════════════════════'));
    print(cyan('               CREATE NEW FLUTTER PROJECT             '));
    print(cyan('  ═══════════════════════════════════════════════════'));
    print('');

    printStep(1, 4, 'Flutter Runner');
    printDivider();
    final runnerInfo = await _selectRunner();
    print('');

    printStep(2, 4, 'Project Details');
    printDivider();

    var projectName = args.isNotEmpty ? args[0] : '';
    if (projectName.isEmpty) {
      projectName = prompt('Project name (snake_case)', defaultValue: 'my_app');
    }

    projectName = projectName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    if (projectName.isEmpty || RegExp(r'^\d').hasMatch(projectName)) {
      printError('Invalid project name. Use snake_case (e.g. my_awesome_app)');
      exit(1);
    }

    printInfo('Project name: ${green(projectName)}');
    final orgName = prompt('Organization ID', defaultValue: 'com.example');
    final packageName = '$orgName.$projectName';
    printInfo('Package ID  : ${yellow(packageName)}');
    print('');

    printStep(3, 4, 'Project Location');
    printDivider();
    final basePath = await _selectLocation();
    var projectPath = p.join(basePath, projectName);

    // Auto-increment folder name if it already exists
    if (await Directory(projectPath).exists()) {
      print('');
      printWarning('Directory "$projectName" already exists.');
      final overwrite = confirm('Overwrite existing directory?', defaultYes: false);
      if (!overwrite) {
        // Find next available name with suffix _1, _2, etc.
        var counter = 1;
        var newName = '${projectName}_$counter';
        var newPath = p.join(basePath, newName);
        while (await Directory(newPath).exists()) {
          counter++;
          newName = '${projectName}_$counter';
          newPath = p.join(basePath, newName);
        }
        projectName = newName;
        projectPath = newPath;
        printInfo('Using alternative name: ${green(projectName)}');
      }
    }

    printInfo('Full path: ${blue(projectPath)}');
    print('');

    printStep(4, 4, 'Confirm & Create');
    printDivider();
    _printSummary(
      projectName: projectName,
      packageName: packageName,
      projectPath: projectPath,
      runnerLabel: runnerInfo.label,
    );

    final ok = confirm('Proceed?', defaultYes: true);
    if (!ok) {
      printInfo('Aborted.');
      exit(0);
    }
    print('');

    await _createProject(
      runnerInfo: runnerInfo,
      projectName: projectName,
      projectPath: projectPath,
      packageName: packageName,
      orgName: orgName,
    );
  }

  // ─── Runner picker ────────────────────────────────────────────────────────

  Future<_RunnerInfo> _selectRunner() async {
    final f = _env.flutter;
    final fvm = _env.fvm;
    final options = <_RunnerOption>[];

    // Only add system Flutter option if it's NOT detected via FVM
    if (f.available && !f.isViaFvm) {
      options.add(_RunnerOption(
        label: 'Flutter ${f.version} (${f.channel})  ← system install',
        command: 'flutter',
        isFvm: false,
        version: f.version,
      ));
    }

    if (fvm.available) {
      for (final v in fvm.installedVersions) {
        final tag = v == fvm.activeVersion ? '  ← active' : '';
        options.add(_RunnerOption(
          label: 'FVM  →  $v$tag',
          command: 'fvm flutter',
          isFvm: true,
          version: v,
        ));
      }
      options.add(_RunnerOption(
        label: 'FVM  →  install a different version…',
        command: 'fvm flutter',
        isFvm: true,
        version: '__ask__',
      ));
    }

    if (options.isEmpty) {
      printError('No Flutter runner found. Install Flutter or FVM first.');
      exit(1);
    }

    final idx = selectOption(
      'Select Flutter runner (auto-detected):',
      options.map((o) => o.label).toList(),
      defaultIndex: 0,
    );
    final choice = options[idx];

    if (choice.version == '__ask__') {
      print('');
      printInfo('Common options: stable · beta · 3.24.5 · 3.22.3 · 3.19.6');
      final v = prompt('FVM version to install', defaultValue: 'stable');
      print('');
      print(cyan('  ● Installing Flutter $v via FVM...'));
      final r = await _runCommandLive('fvm install $v');
      if (r == 0) {
        printSuccess('Installed Flutter $v');
      } else {
        printWarning('Install may have had issues — proceeding anyway.');
      }
      return _RunnerInfo(
        command: 'fvm flutter',
        isFvm: true,
        version: v,
        label: 'FVM → $v',
      );
    }

    return _RunnerInfo(
      command: choice.command,
      isFvm: choice.isFvm,
      version: choice.version,
      label: choice.label,
    );
  }

  // ─── Location picker ──────────────────────────────────────────────────────

  Future<String> _selectLocation() async {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        Directory.current.path;
    final androidPath = p.join(home, 'AndroidStudioProjects');
    final androidExists = await Directory(androidPath).exists();

    final options = [
      'Current directory   (${Directory.current.path})',
      '~/AndroidStudioProjects${androidExists ? '' : '  (will be created)'}',
      'Enter custom path…',
    ];

    final choice = selectOption('Project location:', options, defaultIndex: 0);
    switch (choice) {
      case 0:
        return Directory.current.path;
      case 1:
        if (!androidExists) {
          await Directory(androidPath).create(recursive: true);
          printInfo('Created ~/AndroidStudioProjects');
        }
        return androidPath;
      case 2:
        final raw = prompt('Full path', defaultValue: Directory.current.path);
        final expanded =
        raw.startsWith('~') ? raw.replaceFirst('~', home) : raw;
        final dir = Directory(expanded);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
          printInfo('Created $expanded');
        }
        return expanded;
      default:
        return Directory.current.path;
    }
  }

  // ─── Summary ──────────────────────────────────────────────────────────────

  void _printSummary({
    required String projectName,
    required String packageName,
    required String projectPath,
    required String runnerLabel,
  }) {
    print(white('  Project Summary'));
    print(gray('  ┌──────────────────────────────────────────────────┐'));
    print(gray('  │  ') + gray('Name    : ') + cyan(projectName));
    print(gray('  │  ') + gray('Package : ') + yellow(packageName));
    print(gray('  │  ') + gray('Path    : ') + blue(projectPath));
    print(gray('  │  ') + gray('Runner  : ') + magenta(runnerLabel));
    print(gray('  │'));
    print(gray('  │  ') + white('Dependencies:'));
    final deps = [
      'get', 'logger', 'top_snackbar_flutter', 'fluttertoast',
      'http', 'loading_animation_widget', 'get_storage', 'pinput'
    ];
    for (var i = 0; i < deps.length; i += 4) {
      final row = deps.skip(i).take(4).map(cyan).join(gray('  '));
      print(gray('  │    ') + row);
    }
    print(gray('  └──────────────────────────────────────────────────┘'));
    print('');
  }

  // ─── Project creation ─────────────────────────────────────────────────────

  Future<void> _createProject({
    required _RunnerInfo runnerInfo,
    required String projectName,
    required String projectPath,
    required String packageName,
    required String orgName,
  }) async {
    print(cyan('  ● Running ${runnerInfo.command} create...'));

    // Ensure project path doesn't have trailing/leading quotes
    final cleanPath = projectPath.replaceAll('"', '').replaceAll("'", '');

    // On Windows, use proper escaping for paths with spaces
    final pathArg = Platform.isWindows && cleanPath.contains(' ')
        ? '"$cleanPath"'
        : cleanPath;

    final createCmd =
        '${runnerInfo.command} create --org $orgName --project-name $projectName $pathArg';
    final createResult = await _runCommandLive(createCmd);
    if (createResult != 0) {
      printError('flutter create failed. See output above.');
      printInfo('Make sure Flutter is properly installed and in your PATH.');
      printInfo('Run "flutter doctor" to check your setup.');
      exit(1);
    }
    printSuccess('Flutter project scaffolded!');

    if (runnerInfo.isFvm) {
      print('');
      print(cyan('  ● Pinning FVM version ${runnerInfo.version}...'));
      final fvmCmd = Platform.isWindows
          ? 'cd /d "$cleanPath" && fvm use ${runnerInfo.version} --force'
          : 'cd "$cleanPath" && fvm use ${runnerInfo.version} --force';
      await _runCommandLive(fvmCmd);
      printSuccess('.fvmrc created in project root');
    }

    print('');
    print(cyan('  ● Writing MVC structure & source files...'));
    final creator = ProjectCreator(
      projectName: projectName,
      projectPath: cleanPath,
      packageName: packageName,
    );
    await creator.createStructure();
    await creator.writeAllFiles();
    printSuccess('Source files written!');

    print('');
    print(cyan('  ● Updating pubspec.yaml...'));
    await creator.updatePubspec();
    printSuccess('Dependencies added!');

    print('');
    print(cyan('  ● Running pub get...'));
    final pubCmd = Platform.isWindows
        ? 'cd /d "$cleanPath" && ${runnerInfo.command} pub get'
        : 'cd "$cleanPath" && ${runnerInfo.command} pub get';
    final pubResult = await _runCommandLive(pubCmd);
    if (pubResult == 0) {
      printSuccess('All packages installed!');
    } else {
      printWarning(
          'pub get had issues. Run manually: ${runnerInfo.command} pub get');
    }

    print('');
    _printComplete(projectName, cleanPath, runnerInfo);
  }

  void _printComplete(String name, String path, _RunnerInfo runner) {
    print(green('  ╔════════════════════════════════════════════════════╗'));
    print(green('  ║         🎉  PROJECT CREATED SUCCESSFULLY!           ║'));
    print(green('  ╚════════════════════════════════════════════════════╝'));
    print('');
    print(white('  Next steps:'));
    print('');
    print('    ${cyan('\$')} cd ${green(name)}');
    print('    ${cyan('\$')} ${runner.command} run');
    print('');
    if (runner.isFvm) {
      print(gray(
          '  Tip: Project is pinned to Flutter ${runner.version} via FVM.'));
      print(gray(
          '       Android Studio / VS Code will use this version automatically.'));
      print('');
    }
    print(gray('  Path: $path'));
    print('');
    print(magenta('  Happy coding! ✦ STA CLI'));
    print('');
  }

  // ─── Low-level helpers ────────────────────────────────────────────────────

  /// Run a command and capture both stdout and stderr separately.
  Future<({int exitCode, String stdout, String stderr})> _runCommandFull(
      String cmd) async {
    final ProcessResult r;
    if (Platform.isWindows) {
      r = await Process.run(
        'cmd',
        ['/c', cmd],
        runInShell: true,
      );
    } else {
      r = await Process.run(
        'bash',
        ['-c', cmd],
        runInShell: true,
      );
    }
    return (
      exitCode: r.exitCode,
      stdout: r.stdout.toString(),
      stderr: r.stderr.toString(),
    );
  }

  /// Resolve the full path of an executable using `which` (Unix) or
  /// `where` (Windows), with a graceful fallback.
  Future<String> _resolveExecutablePath(String executable) async {
    if (Platform.isWindows) {
      final r = await Process.run('where', [executable], runInShell: true);
      final out = r.stdout.toString().trim();
      if (r.exitCode == 0 && out.isNotEmpty) {
        return out.split('\n').first.trim();
      }
    } else {
      final r = await Process.run('which', [executable], runInShell: true);
      final out = r.stdout.toString().trim();
      if (r.exitCode == 0 && out.isNotEmpty) {
        return out.split('\n').first.trim();
      }
    }
    return '';
  }

  Future<int> _runCommandLive(String cmd) async {
    final Process proc;
    if (Platform.isWindows) {
      proc = await Process.start('cmd', ['/c', cmd], runInShell: true);
    } else {
      proc = await Process.start('bash', ['-c', cmd], runInShell: true);
    }
    proc.stdout.listen((d) => stdout.add(d));
    proc.stderr.listen((d) => stderr.add(d));
    return await proc.exitCode;
  }
}