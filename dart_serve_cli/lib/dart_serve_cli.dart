import 'dart:io';

import 'package:code_generator/code_generator.dart';
import 'package:path/path.dart';

import 'generators/main_generator.dart';
import 'generators/rest_controller_generator.dart';

// TODO: Add dependecy injection

Stream<GenerationStep> generateProject({
  required Directory sourceDirectory,
  required Directory outputDirectory,
}) {
  final codeGenerator = CodeGenerator(
    generators: [
      RestControllerGenerator(outputDirectory.path),
    ],
    projectGenerators: [
      MainGenerator(outputDir: outputDirectory.path),
    ],
  );

  return codeGenerator.generateForIncrementally(
    Directory(join(sourceDirectory.absolute.path, 'lib')),
  );
}
