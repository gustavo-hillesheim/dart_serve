import 'dart:io';

import 'package:code_generator/code_generator.dart';
import 'package:path/path.dart';

import 'generators/main_generator.dart';
import 'generators/injectables_registry_generator.dart';
import 'generators/rest_controller_routes_generator.dart';

Stream<GenerationStep> generateProject({
  required Directory sourceDirectory,
  required Directory outputDirectory,
}) {
  final codeGenerator = CodeGenerator(
    generators: [
      RestControllerRoutesGenerator(outputDirectory.path),
    ],
    projectGenerators: [
      MainGenerator(outputDir: outputDirectory.path),
      InjectablesRegistryGenerator(outputDir: outputDirectory.path),
    ],
  );

  return codeGenerator.generateForIncrementally(
    Directory(join(sourceDirectory.absolute.path, 'lib')),
  );
}
