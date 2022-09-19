import 'endpoint.dart';
import '../models/models.dart';

class Patch extends Endpoint {
  const Patch([super.path]) : super(methods: const [HttpMethod.patch]);
}
