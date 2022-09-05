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
    final outputProjectDir = relative(
      'dart_serve_${DateTime.now().millisecondsSinceEpoch}',
      from: projectDirectory.absolute.path,
    );
    await generateProject(
      sourceDirectory: projectDirectory,
      outputDirectory: Directory(outputProjectDir),
    );
    print('Starting app...');
    await Process.run('dart', ['pub', 'get'],
        workingDirectory: outputProjectDir);
    await Process.start(
      'dart',
      ['run', 'lib/main.dart'],
      workingDirectory: outputProjectDir,
      mode: ProcessStartMode.inheritStdio,
    );
  }
}
