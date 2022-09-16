import 'dart:convert';
import 'dart:io';

import 'package:example/models/person.dart';
import 'package:shelf/shelf.dart';
import 'package:dart_serve/dart_serve.dart';
import 'package:example/services/person_service.dart';

@RestController(path: 'people')
class PersonController {
  final PersonService service;

  const PersonController(this.service);

  @Post(path: '/')
  Response create(@RequestBody() String body) {
    final person = Person.fromJson(jsonDecode(body));
    service.create(person);
    return Response(HttpStatus.created);
  }

  @Get(path: '/')
  List<Person> findAll() {
    return service.findAll();
  }

  @Get(path: '<id>')
  Response findOne(@PathParam() String? id) {
    if (id == null) {
      return Response.badRequest();
    }
    return Response.ok(jsonEncode(service.findById(id)));
  }

  @Delete(path: '<id>')
  Response delete(@PathParam() String? id) {
    if (id == null) {
      return Response.badRequest();
    }
    service.deleteById(id);
    return Response(HttpStatus.noContent);
  }
}
