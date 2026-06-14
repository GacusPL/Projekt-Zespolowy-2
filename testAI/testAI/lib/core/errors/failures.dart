import 'package:equatable/equatable.dart';

/// Bazowa klasa błędów domeny – używana z `Either<Failure, T>`.
sealed class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Błąd komunikacji z lokalnym serwerem Ollama
/// (np. Ollama nie uruchomiona, brak modelu, time-out).
class OllamaFailure extends Failure {
  const OllamaFailure(super.message);
}

/// Błąd dostępu do lokalnej bazy SQLite.
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

/// Błąd parsowania pliku (PDF uszkodzony, nieobsługiwany typ obrazu...).
class FileProcessingFailure extends Failure {
  const FileProcessingFailure(super.message);
}

/// Walidacja danych użytkownika (puste pole, zły format itd.).
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Niespodziewany błąd – fallback.
class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
