enum HttpMethod {
  get,
  put,
  post,
  delete,
  patch,
  head,
  connect,
  options,
  trace;

  static HttpMethod? fromString(String? str) {
    if (str == null) {
      return null;
    }
    for (final value in values) {
      if (value.name == str) {
        return value;
      }
    }
    return null;
  }
}
