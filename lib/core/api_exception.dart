class ApiException implements Exception {
  const ApiException(this.message, {this.status = 0});

  final String message;
  final int status;

  @override
  String toString() => message;
}

String errorText(Object error) {
  if (error is ApiException) return error.message;
  return 'خطایی رخ داد. دوباره تلاش کنید.';
}
