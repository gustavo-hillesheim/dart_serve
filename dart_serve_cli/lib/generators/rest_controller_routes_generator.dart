import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:code_generator/code_generator.dart';
import 'package:dart_serve/dart_serve.dart';

import '../utils/library_utils.dart';

class RestControllerRoutesGenerator extends GeneratorForClass {
  final String outputDir;

  RestControllerRoutesGenerator(this.outputDir);

  @override
  bool shouldGenerateFor(ClassDeclaration member, String path) {
    return super.shouldGenerateFor(member, path) &&
        member.metadata.any((m) => m.name.name == 'RestController');
  }

  @override
  GeneratorResult generate(ClassDeclaration member, String path) {
    final routes = _findEndpoints(member);
    final library = member.declaredElement2!.library;
    // TODO: Add support to access Request in handler
    String generatedCode = '''
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:dart_serve/dart_serve.dart';

import '${library.identifier}';

Handler create${member.name2}Handler() {
  const pipeline = Pipeline();
  final router = Router();

${routes.map((r) {
      return '''  router.${r.httpMethod.name}('${r.path}', ${_buildRequestHandler(r, member.name2.toString())});''';
    }).join('\n')}

  return pipeline.addHandler(router);
}
''';
    return GeneratorResult.single(
      path:
          '$outputDir/routes/${LibraryUtils.getLibraryName(library.identifier)}.dart',
      content: generatedCode,
    );
  }

  String _buildRequestHandler(
      _EndpointConfiguration endpointConfiguration, String controllerName) {
    String requestHandler = '(Request request) async {\n';
    requestHandler +=
        'final controller = ServiceLocator.locate<$controllerName>();\n';
    final orderedParameters = [...endpointConfiguration.parameters]..sort();
    for (final parameter in orderedParameters) {
      requestHandler +=
          'final _parameter_${parameter.name} = ${parameter.source.attributionStatement};\n';
      if (parameter.isRequired) {
        requestHandler += 'if (_parameter_${parameter.name} == null) {'
            'return Response.badRequest(body: \'${parameter.source.userFriendlyName} cannot be null\');'
            '}\n';
      }
    }
    String responseAttribution = 'final response = ';
    responseAttribution +=
        'controller.${endpointConfiguration.instanceMethodName}(';
    for (final parameter in orderedParameters) {
      if (parameter.type == _ParameterType.positional) {
        responseAttribution += '_parameter_${parameter.name},';
      } else {
        responseAttribution +=
            '${parameter.name}: _parameter_${parameter.name},';
      }
    }
    responseAttribution += ');';
    requestHandler += '$responseAttribution\n';
    requestHandler += 'return await createResponseFrom(response);';
    requestHandler += '\n}';
    return requestHandler;
  }

  List<_EndpointConfiguration> _findEndpoints(ClassDeclaration member) {
    final methods = member.members.whereType<MethodDeclaration>();
    final endpoints = <_EndpointConfiguration>[];
    for (final method in methods) {
      final methodName = method.name2.toString();
      for (final endpointAnnotation in _readEndPointAnnotations(method)) {
        for (final httpMethod in endpointAnnotation.methods) {
          endpoints.add(_EndpointConfiguration(
            httpMethod: httpMethod,
            path: _normalizePath(endpointAnnotation.path ?? ''),
            instanceMethodName: methodName,
            parameters: _readEndpointParameters(method) ?? [],
          ));
        }
      }
    }
    return endpoints;
  }

  String _normalizePath(String path) {
    return path.startsWith('/') ? path : '/$path';
  }

  Iterable<Endpoint> _readEndPointAnnotations(MethodDeclaration method) {
    const endpointAnnotationsNames = [
      'Get',
      'Put',
      'Post',
      'Delete',
      'Patch',
      'Endpoint'
    ];
    return method.metadata
        .where((m) => endpointAnnotationsNames.contains(m.name.name))
        .map((m) => m.elementAnnotation?.computeConstantValue())
        .whereType<DartObject>()
        .map(_readEndpoint);
  }

  Endpoint _readEndpoint(DartObject annotation) {
    return Endpoint(
      annotation.getInheritedField('path')?.toStringValue(),
      methods: annotation
              .getInheritedField('methods')
              ?.toListValue()
              ?.map((o) =>
                  HttpMethod.fromString(o.getField('_name')?.toStringValue()))
              .whereType<HttpMethod>()
              .toList() ??
          [],
    );
  }

  List<_EndpointParameter>? _readEndpointParameters(MethodDeclaration method) {
    const sourceAnnotationsNames = [
      'Header',
      'Headers',
      'PathParam',
      'PathParams',
      'QueryParam',
      'QueryParams',
      'RequestBody',
    ];
    final annotatedParameters = method.parameters?.parameters.where((p) {
      final annotations =
          p.metadata.where((m) => sourceAnnotationsNames.contains(m.name.name));
      if (annotations.length > 1) {
        throw ArgumentError(
          'Parameter ${p.name} contains ${annotations.length} source annotations: '
          '${annotations.map((a) => a.name.name)}. You can only specify one source annotation per parameter',
        );
      }
      return annotations.isNotEmpty;
    });
    if (annotatedParameters == null) {
      return null;
    }
    final endpointParameters = <_EndpointParameter>[];
    for (int i = 0; i < annotatedParameters.length; i++) {
      final parameter = annotatedParameters.elementAt(i);
      final endpointParameter = _readEndpointParameter(
        parameter: parameter,
        // TODO: Create method to retrieve annotations safely
        annotation: parameter.metadata
            .firstWhere((m) => sourceAnnotationsNames.contains(m.name.name))
            .elementAnnotation!
            .computeConstantValue()!,
        position: i,
      );
      endpointParameters.add(endpointParameter);
    }
    return endpointParameters;
  }

  _EndpointParameter _readEndpointParameter({
    required FormalParameter parameter,
    required DartObject annotation,
    required int position,
  }) {
    final type = _ParameterType.forParameter(parameter);
    final name = parameter.name?.toString();
    return _EndpointParameter(
      type: type,
      name: name,
      position: position,
      isRequired: parameter.declaredElement?.type.nullabilitySuffix ==
          NullabilitySuffix.none,
      source: _getParameterSource(parameter, annotation),
    );
  }

  _EndpointParameterSource _getParameterSource(
      FormalParameter parameter, DartObject sourceAnnotation) {
    final annotationName =
        sourceAnnotation.type!.getDisplayString(withNullability: false);
    switch (annotationName) {
      case 'Header':
        return _HeaderEndpointParameterSource(
          headerName: sourceAnnotation.getField('name')?.toStringValue() ??
              parameter.name.toString(),
        );
      case 'Headers':
        return _AllHeadersEndpointParameterSource();
      case 'PathParam':
        return _PathParamEndpointParameterSource(
          paramName: sourceAnnotation.getField('name')?.toStringValue() ??
              parameter.name.toString(),
        );
      case 'PathParams':
        return _AllPathParamsEndpointParameterSource();
      case 'QueryParam':
        return _QueryParamEndpointParameterSource(
          paramName: sourceAnnotation.getField('name')?.toStringValue() ??
              parameter.name.toString(),
        );
      case 'QueryParams':
        return _AllQueryParamsEndpointParameterSource();
      case 'RequestBody':
        return _RequestBodyEndpointParameterSource();
      default:
        throw ArgumentError(
            'Cannot create parameter source for annotation "$annotationName"');
    }
  }
}

class _EndpointConfiguration {
  final HttpMethod httpMethod;
  final String instanceMethodName;
  final String path;
  final List<_EndpointParameter> parameters;

  const _EndpointConfiguration({
    required this.httpMethod,
    required this.instanceMethodName,
    required this.path,
    required this.parameters,
  });
}

// TODO: Add support for converting parameters to desired type
class _EndpointParameter implements Comparable<_EndpointParameter> {
  final _EndpointParameterSource source;
  final _ParameterType type;
  final String? name;
  final int? position;
  final bool isRequired;

  const _EndpointParameter({
    required this.source,
    required this.type,
    required this.isRequired,
    this.name,
    this.position,
  });

  @override
  int compareTo(_EndpointParameter other) {
    if (type == _ParameterType.positional) {
      if (other.type == _ParameterType.named) {
        return -1;
      }
      return position!.compareTo(other.position!);
    } else {
      if (other.type == _ParameterType.positional) {
        return 1;
      }
      return 0;
    }
  }
}

abstract class _EndpointParameterSource {
  String get attributionStatement;
  String get userFriendlyName;
  bool get isNullable;
}

class _HeaderEndpointParameterSource implements _EndpointParameterSource {
  final String headerName;

  const _HeaderEndpointParameterSource({
    required this.headerName,
  });

  @override
  String get userFriendlyName => 'Header "$headerName"';

  @override
  String get attributionStatement => 'request.headers["$headerName"]';

  @override
  bool get isNullable => true;
}

class _AllHeadersEndpointParameterSource implements _EndpointParameterSource {
  @override
  String get userFriendlyName => 'Headers';

  @override
  String get attributionStatement => 'request.headers';

  @override
  bool get isNullable => false;
}

class _PathParamEndpointParameterSource implements _EndpointParameterSource {
  final String paramName;

  const _PathParamEndpointParameterSource({
    required this.paramName,
  });

  @override
  String get userFriendlyName => 'Path parameter "$paramName"';

  @override
  String get attributionStatement => 'request.params["$paramName"]';

  @override
  bool get isNullable => true;
}

class _AllPathParamsEndpointParameterSource
    implements _EndpointParameterSource {
  @override
  String get userFriendlyName => 'Path parameters';
  @override
  String get attributionStatement => 'request.params';

  @override
  bool get isNullable => false;
}

class _QueryParamEndpointParameterSource implements _EndpointParameterSource {
  final String paramName;

  const _QueryParamEndpointParameterSource({
    required this.paramName,
  });

  @override
  String get userFriendlyName => 'Query parameter "$paramName"';

  @override
  String get attributionStatement =>
      'request.url.queryParameters["$paramName"]';

  @override
  bool get isNullable => true;
}

class _AllQueryParamsEndpointParameterSource
    implements _EndpointParameterSource {
  @override
  String get userFriendlyName => 'Query parameters';
  @override
  String get attributionStatement => 'request.url.queryParameters';

  @override
  bool get isNullable => false;
}

class _RequestBodyEndpointParameterSource implements _EndpointParameterSource {
  @override
  String get userFriendlyName => 'Body';
  @override
  String get attributionStatement => 'await request.readAsString()';

  @override
  bool get isNullable => false;
}

enum _ParameterType {
  positional,
  named;

  static forParameter(FormalParameter parameter) {
    if (parameter.isPositional) {
      return _ParameterType.positional;
    } else if (parameter.isNamed) {
      return _ParameterType.named;
    }
    throw ArgumentError(
        'Cannot get ParameterType for parameter ${parameter.name}');
  }
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
