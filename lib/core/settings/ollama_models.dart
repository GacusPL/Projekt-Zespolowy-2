/// Pojedyncza pozycja na liście modeli Ollama do wyboru w ustawieniach.
class OllamaModelOption {
  /// Nazwa modelu używana w API Ollama (np. `llama3.1`, `qwen2.5:14b`).
  final String name;

  /// Przybliżony rozmiar / zajętość VRAM w GB (wariant kwantyzowany Q4).
  final double sizeGb;

  /// Wymiarowość produkowanego wektora embeddingu (np. 768, 1024, 384).
  /// `null` dla modeli czatu / wizji, które nie generują embeddingów.
  final int? dimension;

  const OllamaModelOption(this.name, this.sizeGb, {this.dimension});

  /// Etykieta pokazywana w UI, np. `llama3.1 (4.9 GB)`.
  String get label => '$name (${sizeGb.toStringAsFixed(1)} GB)';
}

/// Skatalogowane modele Ollama, z których użytkownik wybiera w ustawieniach.
///
/// Lista jest dobrana tak, by każdy model zmieścił się w budżecie VRAM
/// ([maxVramGb]). Dzięki wyborowi z listy (zamiast wpisywania nazwy ręcznie)
/// unikamy literówek i przypadkowego wpisania modelu, który nie zmieści się
/// w pamięci karty.
///
/// Rozmiary są przybliżone (warianty Q4) — realna zajętość VRAM rośnie nieco
/// wraz z długością kontekstu.
class OllamaModels {
  OllamaModels._();

  /// Budżet pamięci karty graficznej (≈16 GB).
  static const double maxVramGb = 16.0;

  /// Modele czatu (generowanie odpowiedzi RAG, fiszek, quizów).
  ///
  /// Rozmiary modeli Gemma 4 wg strony Ollamy (Size / Usage). Warianty 26B
  /// (18 GB) i 31B (20 GB) pominięto — nie mieszczą się w budżecie [maxVramGb].
  static const List<OllamaModelOption> chat = [
    OllamaModelOption('llama3.1', 4.9), // 8B — domyślny
    OllamaModelOption('llama3.2', 2.0), // 3B — szybki, lekki
    OllamaModelOption('gemma4:e2b', 7.2), // Gemma 4 E2B
    OllamaModelOption('gemma4:e4b', 9.6), // Gemma 4 E4B
    OllamaModelOption('gemma4:12b', 7.6), // Gemma 4 12B
    OllamaModelOption('gemma3', 3.3), // 4B
    OllamaModelOption('gemma2', 5.4), // 9B
    OllamaModelOption('mistral', 4.1), // 7B
    OllamaModelOption('qwen2.5', 4.7), // 7B
    OllamaModelOption('qwen2.5:14b', 9.0), // 14B
    OllamaModelOption('phi3', 2.2), // 3.8B
  ];

  /// Modele embeddingów (wektoryzacja fragmentów do wyszukiwania RAG).
  ///
  /// Uwaga: różne modele dają wektory o różnej wymiarowości. Po zmianie modelu
  /// embeddingów wcześniej zapisane fragmenty trzeba wgrać ponownie.
  static const List<OllamaModelOption> embedding = [
    OllamaModelOption('nomic-embed-text', 0.3, dimension: 768), // domyślny
    OllamaModelOption('mxbai-embed-large', 0.7, dimension: 1024),
    OllamaModelOption('bge-m3', 1.2, dimension: 1024),
    OllamaModelOption('all-minilm', 0.05, dimension: 384), // najlżejszy
  ];

  /// Zwraca znaną wymiarowość wektora dla danego modelu embeddingów lub `null`,
  /// gdy model nie figuruje w katalogu (model spoza listy — wymiar nieznany,
  /// nie da się go zweryfikować z góry).
  ///
  /// Dopasowanie ignoruje tag wersji (np. `bge-m3:latest` → `bge-m3`).
  static int? embeddingDimensionFor(String model) {
    final name = model.split(':').first.trim();
    for (final opt in embedding) {
      if (opt.name == name) return opt.dimension;
    }
    return null;
  }

  /// Modele wizyjne (ekstrakcja tekstu ze zdjęć notatek — „OCR z AI").
  static const List<OllamaModelOption> vision = [
    OllamaModelOption('llava', 4.7), // 7B — domyślny
    OllamaModelOption('llava:13b', 8.0), // 13B
    OllamaModelOption('llama3.2-vision', 7.9), // 11B
    OllamaModelOption('bakllava', 4.7), // 7B
    OllamaModelOption('moondream', 1.7), // 1.8B — najlżejszy
  ];
}
