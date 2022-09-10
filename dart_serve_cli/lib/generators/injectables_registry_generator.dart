import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:code_generator/code_generator.dart';

import '../utils/library_utils.dart';
import '../utils/declaration_utils.dart';

// TODO: Add support por named injectables
class InjectablesRegistryGenerator extends GeneratorForProject {
  final String outputDir;

  InjectablesRegistryGenerator({required this.outputDir});

  @override
  GeneratorResult generate(List<ResolvedLibraryResult> members) {
    final injectableFactories = _findLibrariesWithInjectables(members);
    final content = '''
import 'package:dart_serve/dart_serve.dart';

${injectableFactories.map((l) => "import '${l.libraryPath}' as ${l.libraryName};").join('\n')}

void registerInjectables() {
  ${injectableFactories.map((library) {
      return library.injectables
          .map((i) => _buildInjectableRegisterStatement(i, library.libraryName))
          .join('\n');
    }).join('\n')}
}
''';

    return GeneratorResult.single(
      path: '$outputDir/injectables_registry.dart',
      content: content,
    );
  }

  String _buildInjectableRegisterStatement(
    _InjectableFactory injectableFactory,
    String libraryName,
  ) {
    var injectableRegisterStatement =
        'ServiceLocator.registerFactory((l) => $libraryName.${injectableFactory.injectableName}';
    if (injectableFactory.constructorName != null) {
      injectableRegisterStatement += '.${injectableFactory.constructorName}';
    }
    injectableRegisterStatement += '(';
    final orderedParameters = [...injectableFactory.parameters]..sort();
    for (final parameter in orderedParameters) {
      switch (parameter.type) {
        case _ParameterType.positional:
          injectableRegisterStatement += 'l(),';
          break;
        case _ParameterType.named:
          injectableRegisterStatement += '${parameter.name}: l(),';
      }
    }
    injectableRegisterStatement += '));';
    return injectableRegisterStatement;
  }

  List<_LibraryWithInjectables> _findLibrariesWithInjectables(
      List<ResolvedLibraryResult> libraries) {
    return libraries.where(_libraryContainsInjectable).map((library) {
      final libraryIdentifier = library.element.identifier;
      final libraryName = LibraryUtils.getLibraryName(libraryIdentifier);
      final injectablesFactories = _findInjectablesFactories(library);
      return _LibraryWithInjectables(
        libraryName: libraryName,
        libraryPath: libraryIdentifier,
        injectables: injectablesFactories,
      );
    }).toList();
  }

  bool _libraryContainsInjectable(ResolvedLibraryResult library) {
    return LibraryUtils.containsElementAnnotatedWithAny(
        library, ['Injectable', 'RestController']);
  }

  List<_InjectableFactory> _findInjectablesFactories(
      ResolvedLibraryResult library) {
    return LibraryUtils.findAllClassesAnnotatedWithAny(
            library, ['RestController', 'Injectable'])
        .map(_createInjectableFactory)
        .toList();
  }

  _InjectableFactory _createInjectableFactory(
      ClassDeclaration classDeclaration) {
    final injectableConstructor = _getInjectableConstructor(classDeclaration);
    return _InjectableFactory(
      injectableName: classDeclaration.name2.toString(),
      constructorName: injectableConstructor?.name2?.toString(),
      parameters: _getConstructorParameters(injectableConstructor),
    );
  }

  ConstructorDeclaration? _getInjectableConstructor(
      ClassDeclaration classDeclaration) {
    final constructors =
        classDeclaration.members.whereType<ConstructorDeclaration>();
    final injectAnnotatedConstructors = constructors
        .where((c) => DeclarationUtils.hasAnnotationNamed(c, "Inject"));
    if (injectAnnotatedConstructors.isNotEmpty) {
      if (injectAnnotatedConstructors.length > 1) {
        throw ArgumentError(
            'Cannot have two constructors annotated with @Inject');
      }
      return injectAnnotatedConstructors.first;
    } else if (constructors.length > 1) {
      throw ArgumentError(
          'Cannot determine which constructor to use for dependency injection, annotate the desired one with @Inject');
    } else if (constructors.isNotEmpty) {
      return constructors.first;
    } else {
      return null;
    }
  }

  List<_ConstructorParameter> _getConstructorParameters(
      ConstructorDeclaration? constructor) {
    if (constructor == null) {
      return [];
    }
    final parameters = <_ConstructorParameter>[];
    for (int i = 0; i < constructor.parameters.parameters.length; i++) {
      final parameter = constructor.parameters.parameters.elementAt(i);
      final _ParameterType type;
      if (parameter.isPositional) {
        type = _ParameterType.positional;
      } else {
        type = _ParameterType.named;
      }
      parameters.add(_ConstructorParameter(
        type: type,
        name: parameter.name?.toString(),
        position: i,
      ));
    }
    return parameters;
  }
}

class _LibraryWithInjectables {
  final String libraryName;
  final String libraryPath;
  final List<_InjectableFactory> injectables;

  const _LibraryWithInjectables({
    required this.libraryName,
    required this.libraryPath,
    required this.injectables,
  });
}

class _InjectableFactory {
  final String injectableName;
  final String? constructorName;
  final List<_ConstructorParameter> parameters;

  const _InjectableFactory({
    required this.injectableName,
    required this.parameters,
    this.constructorName,
  });
}

class _ConstructorParameter implements Comparable<_ConstructorParameter> {
  final _ParameterType type;
  final String? name;
  final int? position;

  const _ConstructorParameter({
    required this.type,
    this.name,
    this.position,
  });

  @override
  int compareTo(_ConstructorParameter other) {
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

enum _ParameterType { named, positional }
