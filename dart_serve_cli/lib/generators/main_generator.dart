import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:code_generator/code_generator.dart';

import '../utils/library_utils.dart';

class MainGenerator extends GeneratorForProject {
  final String outputDir;

  MainGenerator({required this.outputDir});

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
import 'dart:io';

import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:dart_serve/dart_serve.dart';

import 'injectables_registry.dart' as injectables_registry;

${handlerDefinition.map((h) {
      return "import 'routes/${h.libraryName}.dart' as ${h.libraryName};";
    }).join('\n')}

void main() => serveWithHotReload(createServer);

Future<HttpServer> createServer() {
  ServiceLocator.clear();
  final router = Router();

${handlerDefinition.map((h) {
      return "  router.mount('${h.path}', ${h.libraryName}.${h.createMethodName}());";
    }).join('\n')}

  injectables_registry.registerInjectables();
  print('Starting app at http://localhost:8080...');
  return io.serve(router, InternetAddress.anyIPv4, 8080);
}
''';
    return GeneratedFile(
      content: content,
      path: '$outputDir/main.dart',
    );
  }

  List<_HandlerDefinition> _getHandlerDefinitions(
      List<ResolvedLibraryResult> libraries) {
    return libraries.where(_libraryContainsController).map((l) {
      final libraryName = LibraryUtils.getLibraryName(l.element.identifier);
      final controllers = _getControllers(l);
      return controllers.map((c) {
        final path = _getControllerPath(c);
        return _HandlerDefinition(
          libraryName: libraryName,
          createMethodName: 'create${c.name2}Handler',
          path: path,
        );
      });
    }).fold<List<_HandlerDefinition>>([], (h1, h2) => [...h1, ...h2]);
  }

  bool _libraryContainsController(ResolvedLibraryResult library) {
    return LibraryUtils.containsElementAnnotatedWith<ClassDeclaration>(
        library, 'RestController');
  }

  List<ClassDeclaration> _getControllers(ResolvedLibraryResult library) {
    return LibraryUtils.findAllClassesAnnotatedWith(library, 'RestController');
  }

  String _getControllerPath(ClassDeclaration controller) {
    final restControllerAnnotation =
        controller.metadata.firstWhere((m) => m.name.name == 'RestController');
    final path = restControllerAnnotation.elementAnnotation!
            .computeConstantValue()
            ?.getField('path')
            ?.toStringValue() ??
        '/';
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
