import 'dart:io';

import 'package:path/path.dart';
import 'package:args/command_runner.dart';
import 'package:dart_serve_cli/dart_serve_cli.dart';

class StartCommand extends Command {
  @override
  String get name => 'start';

  @override
  String get description => 'Starts the DartServe app in the current directory';

  @override
  void run() async {
    final projectRelativePath =
        argResults!.rest.isNotEmpty ? argResults!.rest[0] : '.';
    final projectDirectory = Directory(
      normalize(join(Directory.current.absolute.path, projectRelativePath)),
    );
    print('Building app at ${projectDirectory.path}...');
    final outputPath = relative(
      '.dart_serve',
      from: projectDirectory.absolute.path,
    );
    final outputDirectory = Directory(outputPath);
    if (await outputDirectory.exists()) {
      await outputDirectory.delete(recursive: true);
    }
    await generateProject(
      sourceDirectory: projectDirectory,
      outputDirectory: outputDirectory,
    );
    print('Starting app...');
    await Process.start(
      'dart',
      ['run', '--enable-vm-service', join(outputPath, 'main.dart')],
      workingDirectory: projectDirectory.absolute.path,
      mode: ProcessStartMode.inheritStdio,
    );
  }
}
