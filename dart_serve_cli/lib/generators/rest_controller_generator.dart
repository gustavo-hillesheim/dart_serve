import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:code_generator/code_generator.dart';
import 'package:dart_serve/dart_serve.dart';
import 'package:collection/collection.dart';

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
    final routes = _findEndpoints(member);
    final library = member.declaredElement2!.library;
    if (routes.isNotEmpty) {
      String generatedCode = '''
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';


import '${library.identifier}';

Handler create${member.name2}Handler() {
  final instance = ${member.name2}();
  const pipeline = Pipeline();
  final router = Router();

${routes.map((r) {
        return '''  router.${r.httpMethod.name}('${r.path}', (Request request) async {
    return Response.ok(await instance.${r.instanceMethodName}());
  });''';
      }).join('\n')}

  return pipeline.addHandler(router);
}
''';
      return GeneratorResult.single(
        path:
            '$outputDir/routes/${LibraryUtils.createRoutesLibraryName(library.identifier)}.dart',
        content: generatedCode,
      );
    }
    return GeneratorResult([]);
  }

  List<_Endpoint> _findEndpoints(ClassDeclaration member) {
    final methods = member.members.whereType<MethodDeclaration>();
    const endpointAnnotationsNames = [
      'Get',
      'Put',
      'Post',
      'Delete',
      'Patch',
      'Endpoint'
    ];
    return methods.map<Iterable<_Endpoint>>((method) {
      final endpointAnnotations = method.metadata
          .where((m) => endpointAnnotationsNames.contains(m.name.name))
          .map((m) => m.elementAnnotation?.computeConstantValue())
          .whereType<DartObject>();
      return endpointAnnotations.map((e) {
        final path =
            e.getInheritedField('path')?.toStringValue() ?? '${method.name2}';
        final methods = e
                .getInheritedField('methods')
                ?.toListValue()
                ?.map((o) =>
                    HttpMethod.fromString(o.getField('_name')?.toStringValue()))
                .whereType<HttpMethod>() ??
            [];
        return methods.map((httpMethod) => _Endpoint(
              httpMethod: httpMethod,
              path: path.startsWith('/') ? path : '/$path',
              instanceMethodName: method.name2.toString(),
            ));
      }).fold([], (acc, v) => [...acc, ...v]);
    }).fold(<_Endpoint>[], (acc, v) => [...acc, ...v]);
  }
}

class _Endpoint {
  final HttpMethod httpMethod;
  final String instanceMethodName;
  final String path;

  const _Endpoint({
    required this.httpMethod,
    required this.instanceMethodName,
    required this.path,
  });
}

extension on DartObject {
  DartObject? getInheritedField(String name) {
    DartObject? object = this;
    while (object != null) {
      final value = object.getField(name);
      if (value != null) {
        return value;
      }
      object = object.getField('(super)');
    }
    return null;
  }
}
