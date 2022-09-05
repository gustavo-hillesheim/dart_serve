import 'dart:io';

import 'package:path/path.dart';
import 'package:code_generator/code_generator.dart';

import 'generators/main_generator.dart';
import 'generators/rest_controller_generator.dart';

Future<void> generateProject({
  required Directory sourceDirectory,
  required Directory outputDirectory,
}) async {
  final packageName = sourceDirectory.path.split(separator).last;

  final codeGenerator = CodeGenerator(
    generators: [
      RestControllerGenerator(outputDirectory.path),
    ],
    projectGenerators: [
      MainGenerator(
        outputDir: outputDirectory.path,
        sourceDir: sourceDirectory.path,
        packageName: packageName,
      ),
    ],
  );

  await codeGenerator.generateFor(sourceDirectory).last;
}
