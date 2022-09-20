import 'dart:convert';
import 'dart:io';

import 'package:example/models/person.dart';
import 'package:shelf/shelf.dart';
import 'package:dart_serve/dart_serve.dart';
import 'package:example/services/person_service.dart';

@RestController('people')
class PersonController {
  final PersonService service;

  const PersonController(this.service);

  @Post()
  Response create(@RequestBody() String body) {
    final person = Person.fromJson(jsonDecode(body));
    service.create(person);
    return Response(HttpStatus.created);
  }

  @Get()
  List<Person> findAll() {
    return service.findAll();
  }

  @Get('<id>')
  Person? findOne(@PathParam() String id) {
    return service.findById(id);
  }

  @Delete('<id>')
  Response delete(@PathParam() String id) {
    service.deleteById(id);
    return Response(HttpStatus.noContent);
  }
}
