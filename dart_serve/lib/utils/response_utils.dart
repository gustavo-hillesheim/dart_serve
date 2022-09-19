import 'dart:convert';

import 'package:shelf/shelf.dart';

Future<Response> createResponseFrom(Object? obj) async {
  if (obj is Future) {
    obj = await obj;
  }
  if (obj is Response) {
    return obj;
  } else if (obj is Stream<List<int>>) {
    return Response.ok(obj);
  } else {
    return Response.ok(jsonEncode(obj));
  }
}
