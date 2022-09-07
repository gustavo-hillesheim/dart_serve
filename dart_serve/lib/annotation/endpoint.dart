import '../models/models.dart';

class Endpoint {
  final String? path;
  final List<HttpMethod> methods;

  const Endpoint({
    this.path,
    required this.methods,
  });
}
