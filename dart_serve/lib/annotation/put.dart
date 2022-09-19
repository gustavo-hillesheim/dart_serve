import 'endpoint.dart';
import '../models/models.dart';

class Put extends Endpoint {
  const Put([super.path]) : super(methods: const [HttpMethod.put]);
}
