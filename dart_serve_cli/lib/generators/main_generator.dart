import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
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
    ]);
  }

  GeneratedFile _createMainLibrary(
      List<ResolvedLibraryResult> projectLibraries) {
    final handlerDefinition = _getHandlerDefinitions(projectLibraries);
    final content = '''
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf_io.dart' as io;

${handlerDefinition.map((h) {
      return "import 'routes/${h.libraryName}.dart' as ${h.libraryName};";
    }).join('\n')}

void main() async {
  final router = Router();

${handlerDefinition.map((h) {
      return "  router.mount('${h.path}', ${h.libraryName}.${h.createMethodName}());";
    }).join('\n')}

  io.serve(router, 'localhost', 8080);
  print('Started server in port 8080');
}
''';
    return GeneratedFile(
      content: content,
      path: '$outputDir/main.dart',
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

  List<_HandlerDefinition> _getHandlerDefinitions(
      List<ResolvedLibraryResult> libraries) {
    return libraries
        .where(_libraryContainsController)
        .map((l) {
          final libraryName =
              LibraryUtils.createRoutesLibraryName(l.element.identifier);
          final controllers = _getControllers(l);
          return controllers.map((c) {
            final path = _getControllerPath(c);
            return _HandlerDefinition(
              libraryName: libraryName,
              createMethodName: 'create${c.name.name}Handler',
              path: path,
            );
          });
        })
        .reduce((h1, h2) => [...h1, ...h2])
        .toList();
  }

  List<ClassDeclaration> _getControllers(ResolvedLibraryResult library) {
    final controllers = <ClassDeclaration>[];
    for (final unit in library.units) {
      for (final declaration in unit.unit.declarations) {
        if (declaration is ClassDeclaration &&
            declaration.metadata.any((m) => m.name.name == 'RestController')) {
          controllers.add(declaration);
        }
      }
    }
    return controllers;
  }

  String _getControllerPath(ClassDeclaration controller) {
    final restControllerAnnotation =
        controller.metadata.firstWhere((m) => m.name.name == 'RestController');
    final path = restControllerAnnotation.getProperty<String>('path') ?? '/';
    if (!path.startsWith('/')) {
      return '/$path';
    }
    return path;
  }
}

class _HandlerDefinition {
  final String libraryName;
  final String createMethodName;
  final String path;

  const _HandlerDefinition({
    required this.libraryName,
    required this.createMethodName,
    required this.path,
  });
}
