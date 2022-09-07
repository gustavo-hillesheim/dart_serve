import 'endpoint.dart';
import '../models/models.dart';

class Delete extends Endpoint {
  const Delete({super.path}) : super(methods: const [HttpMethod.delete]);
}
