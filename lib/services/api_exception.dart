// Our own error type for API problems.
// toString() returns only the clean message, so the UI can show it directly
// (a normal Exception would print "Exception: ..." in front).
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}
