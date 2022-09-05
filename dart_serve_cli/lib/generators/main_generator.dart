import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart';
import 'package:code_generator/code_generator.dart';

import '../utils/library_utils.dart';

class MainGenerator extends GeneratorForProject {
  final String outputDir;
  final String sourceDir;
  final String packageName;

  MainGenerator({
    required this.outputDir,
    required this.sourceDir,
    required this.packageName,
  });

  @override
  GeneratorResult generate(List<ResolvedLibraryResult> members) {
    return GeneratorResult([
      _createMainLibrary(members),
      _createPubspec(),
    ]);
  }

  GeneratedFile _createMainLibrary(
      List<ResolvedLibraryResult> projectLibraries) {
    final librariesWithControllers = projectLibraries
        .where(_libraryContainsController)
        .map((l) => l.element);
    final content = '''
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf_io.dart' as io;

${librariesWithControllers.map((l) {
      final libraryName = LibraryUtils.createRoutesLibraryName(l.identifier);
      return "import 'routes/$libraryName.dart' as $libraryName;";
    }).join('\n')}

void main() async {
  final router = Router();

${librariesWithControllers.map((l) {
      final libraryName = LibraryUtils.createRoutesLibraryName(l.identifier);
      return "  $libraryName.install(router);";
    }).join('\n')}

  io.serve(router, 'localhost', 8080);
  print('Started server in port 8080');
}
''';
    return GeneratedFile(
      content: content,
      path: '$outputDir/lib/main.dart',
    );
  }

  bool _libraryContainsController(ResolvedLibraryResult library) {
    for (final unit in library.units) {
      for (final declaration in unit.unit.declarations) {
        if (declaration is ClassDeclaration &&
            declaration.metadata.any((m) => m.name.name == 'RestController')) {
          return true;
        }
      }
    }
    return false;
  }

  GeneratedFile _createPubspec() {
    final content = '''
name: ${packageName}_server

environment:
  sdk: '>=2.10.0 <3.0.0'

dependencies:
  shelf:
  shelf_router:
  $packageName:
    path: ${relative(sourceDir, from: outputDir)}
''';
    return GeneratedFile(
      path: '$outputDir/pubspec.yaml',
      content: content,
    );
  }
}
