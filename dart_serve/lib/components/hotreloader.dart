import 'dart:io';
import 'dart:async';

import 'package:shelf_hotreload/shelf_hotreload.dart';

void serveWithHotReload(
  FutureOr<HttpServer> Function() createServerFn,
) {
  // TODO: Add delay to only reload application after code generation finishes
  // TODO: Add custom logs on reload
  withHotreload(
    createServerFn,
    logLevel: Level.WARNING,
  );
}
