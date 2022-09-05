import 'package:args/command_runner.dart';

import 'commands/start_command.dart';

void main(List<String> args) {
  CommandRunner('dart_serve', 'CLI for running and building DartServe apps')
    ..addCommand(StartCommand())
    ..run(args);
}
