/// Stałe globalne aplikacji LekturAI.
class AppConstants {
  AppConstants._();

  // --- Ollama -------------------------------------------------------------

  /// Domyślny URL lokalnej instancji Ollama. Można go zmienić w ustawieniach
  /// (np. gdy Ollama działa na innej maszynie w sieci LAN).
  static const String defaultOllamaBaseUrl = 'http://localhost:11434';

  /// Model używany do generowania embeddingów (768-wymiarowy).
  /// Wymaga: `ollama pull nomic-embed-text`
  static const String embeddingModel = 'nomic-embed-text';

  /// Główny model czatu RAG.
  /// Wymaga: `ollama pull llama3.1`
  static const String chatModel = 'llama3.1';

  /// Model wizyjny używany do ekstrakcji tekstu ze zdjęć notatek
  /// (zastępuje klasyczny OCR — radzi sobie nawet z pismem odręcznym).
  /// Wymaga: `ollama pull llava`
  static const String visionModel = 'llava';

  /// Wymiarowość embeddingu produkowanego przez `nomic-embed-text`.
  static const int embeddingDimension = 768;

  // --- RAG ----------------------------------------------------------------

  /// Liczba słów na chunk podczas dzielenia dokumentu.
  static const int chunkSize = 500;

  /// Liczba słów nakładania się sąsiednich chunków (zachowanie kontekstu).
  static const int chunkOverlap = 50;

  /// Liczba najlepszych fragmentów dołączanych do promptu RAG.
  static const int topKChunks = 5;

  /// Minimalna wartość cosine similarity, by chunk został uznany za trafny.
  static const double minSimilarityThreshold = 0.25;

  // --- UI -----------------------------------------------------------------

  static const Duration animDurShort = Duration(milliseconds: 200);
  static const Duration animDurMedium = Duration(milliseconds: 350);

  // --- Spaced Repetition (SM-2) ------------------------------------------

  static const double sm2InitialEaseFactor = 2.5;
  static const double sm2MinEaseFactor = 1.3;
}
