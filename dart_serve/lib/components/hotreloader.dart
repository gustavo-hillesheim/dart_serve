import 'dart:io';
import 'dart:async';

import 'package:shelf_hotreload/shelf_hotreload.dart';

void serveWithHotReload(
  FutureOr<HttpServer> Function() createServerFn,
) {
  withHotreload(createServerFn, logLevel: Level.WARNING);
}
