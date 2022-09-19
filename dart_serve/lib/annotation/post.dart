import 'endpoint.dart';
import '../models/models.dart';

class Post extends Endpoint {
  const Post([super.path]) : super(methods: const [HttpMethod.post]);
}
