import 'dart:io';
import 'package:path/path.dart' as p;
import 'colors.dart';
import 'prompts.dart';
import 'project_creator.dart';

class CliRunner {
  Future<void> run(List<String> args) async {
    printBanner();

    if (args.isNotEmpty && (args[0] == '--help' || args[0] == '-h')) {
      _printHelp();
      return;
    }

    if (args.isNotEmpty && (args[0] == '--version' || args[0] == '-v')) {
      print(cyan('  STA CLI v1.0.0'));
      return;
    }

    if (args.isEmpty || args[0] != 'create') {
      _printHelp();
      return;
    }

    await _runCreateFlow(args.skip(1).toList());
  }

  Future<void> _runCreateFlow(List<String> args) async {
    print(cyan('  ═══════════════════════════════════════════════════'));
    print(cyan('               CREATE NEW FLUTTER PROJECT             '));
    print(cyan('  ═══════════════════════════════════════════════════'));
    print('');

    // ── Step 1: Flutter / FVM version ───────────────────────────────────
    printStep(1, 4, 'Flutter / FVM Configuration');
    printDivider();

    final flutterMode = selectOption(
      'Which Flutter runner do you want to use?',
      ['Flutter (system)', 'FVM (Flutter Version Manager)'],
      defaultIndex: 0,
    );

    String flutterCommand;
    String flutterVersion = '';

    if (flutterMode == 1) {
      // FVM
      flutterVersion = prompt('FVM Flutter version', defaultValue: 'stable');
      flutterCommand = 'fvm use $flutterVersion --force && fvm flutter';
      printInfo('Using FVM with Flutter $flutterVersion');

      // Check if fvm is installed
      final fvmCheck = await _runCommand('fvm --version');
      if (fvmCheck.$1 != 0) {
        printWarning('FVM not found. Install with: dart pub global activate fvm');
        printInfo('Falling back to system Flutter...');
        flutterCommand = 'flutter';
      }
    } else {
      flutterCommand = 'flutter';
      // Check flutter version available
      final result = await _runCommand('flutter --version');
      if (result.$1 == 0) {
        final versionLine = result.$2.split('\n').first;
        printInfo('Found: $versionLine');
      } else {
        printError('Flutter not found in PATH. Please install Flutter first.');
        exit(1);
      }
    }

    print('');

    // ── Step 2: Project Name ─────────────────────────────────────────────
    printStep(2, 4, 'Project Details');
    printDivider();

    String projectName = args.isNotEmpty ? args[0] : '';
    if (projectName.isEmpty) {
      projectName = prompt('Project name (snake_case)', defaultValue: 'my_app');
    }

    // Sanitize project name
    projectName = projectName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    if (projectName.isEmpty || RegExp(r'^[0-9]').hasMatch(projectName)) {
      printError('Invalid project name. Use snake_case (e.g. my_awesome_app)');
      exit(1);
    }

    final orgName = prompt('Organization name', defaultValue: 'com.example');
    final packageName = '$orgName.$projectName';
    printInfo('Package ID: $packageName');

    print('');

    // ── Step 3: Project path ─────────────────────────────────────────────
    printStep(3, 4, 'Project Location');
    printDivider();

    final locationChoice = selectOption(
      'Where do you want to create the project?',
      [
        'Current directory (${Directory.current.path})',
        'Android Studio Projects (~/AndroidStudioProjects)',
        'Custom path',
      ],
      defaultIndex: 0,
    );

    String basePath;
    switch (locationChoice) {
      case 0:
        basePath = Directory.current.path;
        break;
      case 1:
        final home = Platform.environment['HOME'] ??
            Platform.environment['USERPROFILE'] ??
            Directory.current.path;
        basePath = p.join(home, 'AndroidStudioProjects');
        // Create if not exists
        final dir = Directory(basePath);
        if (!await dir.exists()) {
          printInfo('Creating AndroidStudioProjects folder...');
          await dir.create(recursive: true);
        }
        break;
      case 2:
        final customPath = prompt('Enter custom path');
        basePath = customPath.isEmpty ? Directory.current.path : customPath;
        break;
      default:
        basePath = Directory.current.path;
    }

    final projectPath = p.join(basePath, projectName);
    printInfo('Project will be created at: $projectPath');

    if (await Directory(projectPath).exists()) {
      printWarning('Directory already exists: $projectPath');
      final overwrite = confirm('Overwrite?', defaultYes: false);
      if (!overwrite) {
        printInfo('Aborted.');
        exit(0);
      }
    }

    print('');

    // ── Step 4: Platform selection ───────────────────────────────────────
    printStep(4, 4, 'Platform & Summary');
    printDivider();

    print(white('  Project Summary:'));
    print(gray('  ┌─────────────────────────────────────────────┐'));
    print(gray('  │ ') + '  Name    : ${cyan(projectName)}');
    print(gray('  │ ') + '  Package : ${yellow(packageName)}');
    print(gray('  │ ') + '  Path    : ${blue(projectPath)}');
    print(gray('  │ ') + '  Runner  : ${magenta(flutterMode == 1 ? 'FVM ($flutterVersion)' : 'Flutter (system)')}');
    print(gray('  └─────────────────────────────────────────────┘'));
    print('');

    final confirmed = confirm('Proceed with project creation?', defaultYes: true);
    if (!confirmed) {
      printInfo('Aborted by user.');
      exit(0);
    }

    print('');
    await _createProject(
      flutterCommand: flutterCommand,
      flutterMode: flutterMode,
      flutterVersion: flutterVersion,
      projectName: projectName,
      projectPath: projectPath,
      packageName: packageName,
      orgName: orgName,
    );
  }

  Future<void> _createProject({
    required String flutterCommand,
    required int flutterMode,
    required String flutterVersion,
    required String projectName,
    required String projectPath,
    required String packageName,
    required String orgName,
  }) async {
    print(cyan('  ● Running flutter create...'));

    // Flutter create
    final createCmd = flutterMode == 1
        ? 'fvm flutter create --org $orgName $projectPath'
        : 'flutter create --org $orgName $projectPath';

    final createResult = await _runCommandLive(createCmd);
    if (createResult != 0) {
      printError('flutter create failed. Aborting.');
      exit(1);
    }
    printSuccess('Flutter project created!');

    // FVM: set version in project
    if (flutterMode == 1 && flutterVersion.isNotEmpty) {
      print('');
      print(cyan('  ● Setting FVM version in project...'));
      await _runCommandLive('cd "$projectPath" && fvm use $flutterVersion');
    }

    print('');
    print(cyan('  ● Creating MVC folder structure...'));

    final creator = ProjectCreator(
      projectName: projectName,
      projectPath: projectPath,
      packageName: packageName,
    );

    await creator.createStructure();
    printSuccess('Folder structure created!');

    print('');
    print(cyan('  ● Writing source files...'));
    await creator.writeAllFiles();

    print('');
    print(cyan('  ● Updating pubspec.yaml with dependencies...'));
    await creator.updatePubspec();
    printSuccess('pubspec.yaml updated!');

    print('');
    print(cyan('  ● Running flutter pub get...'));
    final pubGetCmd = flutterMode == 1
        ? 'cd "$projectPath" && fvm flutter pub get'
        : 'cd "$projectPath" && flutter pub get';
    final pubGetResult = await _runCommandLive(pubGetCmd);
    if (pubGetResult == 0) {
      printSuccess('Dependencies installed!');
    } else {
      printWarning('pub get failed. Run manually: flutter pub get');
    }

    print('');
    _printComplete(projectName, projectPath, flutterMode);
  }

  void _printComplete(String name, String path, int flutterMode) {
    final runCmd = flutterMode == 1 ? 'fvm flutter run' : 'flutter run';
    print(green('  ╔══════════════════════════════════════════════════╗'));
    print(green('  ║         🎉  PROJECT CREATED SUCCESSFULLY!         ║'));
    print(green('  ╚══════════════════════════════════════════════════╝'));
    print('');
    print(white('  Next steps:'));
    print('');
    print('  ${cyan('1.')} cd $name');
    print('  ${cyan('2.')} $runCmd');
    print('');
    print(gray('  Project path: $path'));
    print('');
    print(magenta('  Happy coding! ✦ Built with STA CLI'));
    print('');
  }

  void _printHelp() {
    print(white('  Usage:'));
    print('');
    print('    ${cyan('sta create')} ${yellow('[project_name]')}    Create a new Flutter project');
    print('    ${cyan('sta --help')}                   Show this help message');
    print('    ${cyan('sta --version')}                Show CLI version');
    print('');
    print(white('  Examples:'));
    print('');
    print('    ${gray('sta create')}');
    print('    ${gray('sta create my_awesome_app')}');
    print('');
    print(white('  The generated project includes:'));
    print('');
    print('    ${green('✔')} GetX state management');
    print('    ${green('✔')} MVC folder structure');
    print('    ${green('✔')} Network layer (HTTP + token refresh)');
    print('    ${green('✔')} Auth flow (sign in, sign up, splash)');
    print('    ${green('✔')} Shared widgets (buttons, text fields, OTP)');
    print('    ${green('✔')} Theme, routing, and error handling');
    print('    ${green('✔')} Pre-configured dependencies');
    print('');
  }

  /// Run command silently, return (exitCode, stdout)
  Future<(int, String)> _runCommand(String cmd) async {
    final result = await Process.run(
      'bash',
      ['-c', cmd],
      runInShell: true,
    );
    return (result.exitCode, result.stdout.toString());
  }

  /// Run command with live output piped to terminal
  Future<int> _runCommandLive(String cmd) async {
    final process = await Process.start(
      'bash',
      ['-c', cmd],
      runInShell: true,
    );
    process.stdout.listen((data) => stdout.add(data));
    process.stderr.listen((data) => stderr.add(data));
    return await process.exitCode;
  }
}
