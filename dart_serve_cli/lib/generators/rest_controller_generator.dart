import 'package:analyzer/dart/ast/ast.dart';
import 'package:code_generator/code_generator.dart';

import '../utils/library_utils.dart';

class RestControllerGenerator extends GeneratorForClass {
  final String outputDir;

  RestControllerGenerator(this.outputDir);

  @override
  bool shouldGenerateFor(ClassDeclaration member, String path) {
    return super.shouldGenerateFor(member, path) &&
        member.metadata.any((m) => m.name.name == 'RestController');
  }

  @override
  GeneratorResult generate(ClassDeclaration member, String path) {
    final routes = _findRoutes(member);
    final library = member.declaredElement!.library;
    if (routes.isNotEmpty) {
      String generatedCode = '''
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';


import '${library.identifier}';

void install(Router app) {
  final instance = ${member.name.name}();
''';
      for (final route in routes) {
        generatedCode += '''
  app.${route.restMethod.name}('/${route.path}', (Request request) async {
    return Response.ok(await instance.${route.instanceMethodName}());
  });
''';
      }
      generatedCode += '''
}
''';
      return GeneratorResult.single(
        path:
            '$outputDir/lib/routes/${LibraryUtils.createRoutesLibraryName(library.identifier)}.dart',
        content: generatedCode,
      );
    }
    return GeneratorResult([]);
  }

  List<_Route> _findRoutes(ClassDeclaration member) {
    final methods = member.members.whereType<MethodDeclaration>();
    final getRoutes = methods
        .where((m) => m.metadata.any((m) => m.name.name == 'Get'))
        .map((m) => _Route(
              restMethod: _RouteMethod.get,
              path: m.name.name,
              instanceMethodName: m.name.name,
            ));
    return getRoutes.toList();
  }
}

class _Route {
  final _RouteMethod restMethod;
  final String instanceMethodName;
  final String path;

  const _Route({
    required this.restMethod,
    required this.instanceMethodName,
    required this.path,
  });
}

enum _RouteMethod { get }
