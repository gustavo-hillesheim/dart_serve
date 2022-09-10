import 'package:analyzer/dart/ast/ast.dart';

class DeclarationUtils {
  static bool hasAnnotationNamed(
      Declaration declaration, String annotationName) {
    return declaration.metadata.any((m) => m.name.name == annotationName);
  }
}
