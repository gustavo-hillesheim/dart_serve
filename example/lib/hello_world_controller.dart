import 'package:dart_serve/dart_serve.dart';

@RestController()
class HelloWorldController {
  @Get(path: 'hello-world')
  Future<String> helloWorld() async {
    return 'Hello World!';
  }
}
