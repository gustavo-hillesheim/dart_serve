import 'endpoint.dart';
import '../models/models.dart';

class Get extends Endpoint {
  const Get({super.path}) : super(methods: const [HttpMethod.get]);
}
