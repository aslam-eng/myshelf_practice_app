import 'dart:async'; // TimeoutException
import 'dart:io'; // SocketException

// Our own error type for API problems.
// toString() returns only the clean message, so the UI can show it directly
// (a normal Exception would print "Exception: ..." in front).
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  // Turns ANY error into a clean ApiException, in ONE place.
  // Checked top to bottom: the first match wins,
  // so the most specific types come first.
  factory ApiException.from(Object error) {
    // Already clean (e.g. "Server error (500)"): keep its message.
    if (error is ApiException) return error;
    if (error is SocketException) {
      return ApiException('No internet connection');
    }
    if (error is TimeoutException) {
      return ApiException('Request timed out. Please try again.');
    }
    if (error is FormatException || error is TypeError) {
      return ApiException('Unexpected response from server');
    }
    // Safety net: an error we did not plan for still gets a friendly message.
    return ApiException('Something went wrong. Please try again.');
  }

  @override
  String toString() => message;
}
