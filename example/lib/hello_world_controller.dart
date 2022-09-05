import 'package:dart_serve/dart_serve.dart';

@RestController('/')
class HelloWorldController {
  @Get()
  Future<String> helloWorld() async {
    return 'Hello World!';
  }
}
