import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/analysis/results.dart';

class LibraryUtils {
  static String getLibraryName(String libraryIdentifier) {
    return libraryIdentifier.split('/').last.split('.dart').first;
  }

  static String getPackageName(String libraryIdentifier) {
    return libraryIdentifier.split('/')[0].split(':')[1];
  }

  static List<ClassDeclaration> findAllClassesAnnotatedWithAny(
      ResolvedLibraryResult library, List<String> annotationsNames) {
    return annotationsNames
        .map((annotationName) =>
            findAllClassesAnnotatedWith(library, annotationName))
        .fold([], (acc, v) => [...acc, ...v]);
  }

  static List<ClassDeclaration> findAllClassesAnnotatedWith(
      ResolvedLibraryResult library, String annotationName) {
    final classes = <ClassDeclaration>[];
    for (final unit in library.units) {
      for (final declaration in unit.unit.declarations) {
        if (declaration is ClassDeclaration &&
            declaration.metadata.any((m) => m.name.name == annotationName)) {
          classes.add(declaration);
        }
      }
    }
    return classes;
  }

  static bool containsElementAnnotatedWithAny<E extends CompilationUnitMember>(
      ResolvedLibraryResult library, List<String> annotationsNames) {
    return annotationsNames.any(
      (annotationName) =>
          containsElementAnnotatedWith<E>(library, annotationName),
    );
  }

  static bool containsElementAnnotatedWith<E extends CompilationUnitMember>(
      ResolvedLibraryResult library, String annotationName) {
    for (final unit in library.units) {
      for (final declaration in unit.unit.declarations) {
        if (declaration is E &&
            declaration.metadata.any((m) => m.name.name == annotationName)) {
          return true;
        }
      }
    }
    return false;
  }
}
