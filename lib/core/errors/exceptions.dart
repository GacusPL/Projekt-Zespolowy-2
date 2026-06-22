/// Wyjątek rzucany przez warstwę data przy problemach z Ollama.
class OllamaException implements Exception {
  final String message;
  OllamaException(this.message);
  @override
  String toString() => 'OllamaException: $message';
}

/// Wyjątek rzucany przez warstwę data przy problemach z bazą.
class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);
  @override
  String toString() => 'DatabaseException: $message';
}

/// Wyjątek przy parsowaniu plików (PDF/obraz).
class FileProcessingException implements Exception {
  final String message;
  FileProcessingException(this.message);
  @override
  String toString() => 'FileProcessingException: $message';
}
