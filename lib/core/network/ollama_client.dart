import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../errors/exceptions.dart';
import '../settings/app_settings.dart';

/// Klient lokalnej instancji Ollama.
///
/// Obsługuje trzy typy zapytań:
/// 1. `generateEmbedding`   – jednorazowe (nomic-embed-text → 768D).
/// 2. `generateStream`      – streamowana odpowiedź NDJSON (RAG chat).
/// 3. `generateOnce`        – pojedyncza odpowiedź (do fiszek/quizów/JSON).
/// 4. `describeImage`       – multimodal (llava) — używamy jako "OCR z AI"
///    dla zdjęć notatek (radzi sobie też z pismem odręcznym).
class OllamaClient {
  final http.Client _client;
  final AppSettings _settings;
  String? _lastError;

  /// Ostatni zarejestrowany błąd podczas sprawdzania połączenia z Ollamą.
  String? get lastError => _lastError;

  OllamaClient({
    required AppSettings settings,
    http.Client? client,
  })  : _settings = settings,
        _client = client ?? http.Client();

  /// Aktualny adres serwera Ollama — czytany na żywo z [AppSettings], dzięki
  /// czemu zmiana w ustawieniach działa natychmiast (ten sam singleton).
  String get baseUrl => _settings.ollamaBaseUrl;

  /// Aktualnie wybrany model embeddingów (czytany na żywo z [AppSettings]).
  String get embeddingModel => _settings.embeddingModel;

  // ------------------------------------------------------------------ ping

  /// Sprawdza, czy Ollama jest osiągalna. Pomocne by w UI pokazać czytelny
  /// komunikat zamiast wybuchu na pierwszym zapytaniu.
  ///
  /// [baseUrlOverride] pozwala przetestować jeszcze niezapisany adres
  /// (np. z pola w ustawieniach, zanim użytkownik kliknie "Zapisz").
  Future<bool> isReachable({String? baseUrlOverride}) async {
    final url = baseUrlOverride != null
        ? AppSettings.normalizeUrl(baseUrlOverride)
        : baseUrl;
    try {
      final r = await _client.get(
        Uri.parse('$url/api/tags'),
        headers: {
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 3));
      
      if (r.statusCode != 200) {
        final bodyText = r.body.length > 100 ? '${r.body.substring(0, 100)}...' : r.body;
        _lastError = 'HTTP status ${r.statusCode}: $bodyText';
        debugPrint('[OllamaClient] Reachability check failed: $_lastError');
        return false;
      }
      
      // Jeśli ngrok zwraca HTML (np. błąd 104, 502), to nie jest to działająca Ollama
      final contentType = r.headers['content-type'] ?? '';
      if (contentType.contains('text/html')) {
        final ngrokCode = r.headers['ngrok-error-code'];
        final ngrokDesc = r.headers['ngrok-error-description'];
        if (ngrokCode != null) {
          _lastError = 'Błąd ngrok $ngrokCode: $ngrokDesc';
        } else {
          _lastError = 'Serwer zwrócił HTML zamiast JSON (prawdopodobnie błąd lub ostrzeżenie ngrok)';
        }
        debugPrint('[OllamaClient] Reachability check failed: $_lastError');
        return false;
      }
      
      _lastError = null;
      return true;
    } catch (e, stack) {
      _lastError = 'Wyjątek: $e';
      debugPrint('[OllamaClient] Reachability check failed: $_lastError\n$stack');
      return false;
    }
  }

  // ----------------------------------------------------------- embeddings

  Future<List<double>> generateEmbedding(String text) async {
    try {
      final r = await _client.post(
        Uri.parse('$baseUrl/api/embeddings'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'model': _settings.embeddingModel,
          'prompt': text,
        }),
      );

      if (r.statusCode != 200) {
        throw OllamaException(
          'Embedding error ${r.statusCode}: ${r.body}',
        );
      }
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final embedding = (data['embedding'] as List).cast<num>();
      return embedding.map((e) => e.toDouble()).toList();
    } on OllamaException catch (e, stack) {
      debugPrint('[OllamaClient] generateEmbedding exception: $e\n$stack');
      rethrow;
    } catch (e, stack) {
      debugPrint('[OllamaClient] generateEmbedding exception: $e\n$stack');
      throw OllamaException('Nie udało się połączyć z Ollama: $e');
    }
  }

  // -------------------------------------------------------- generate once

  /// Pojedyncze (niestreamowane) wywołanie modelu — używane gdy potrzebujemy
  /// całej odpowiedzi naraz (np. wygenerowanego JSON-a z fiszkami).
  Future<String> generateOnce({
    required String prompt,
    String? model,
    String? system,
    double? temperature,
  }) async {
    try {
      final r = await _client.post(
        Uri.parse('$baseUrl/api/generate'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'model': model ?? _settings.chatModel,
          'prompt': prompt,
          if (system != null) 'system': system,
          'stream': false,
          'options': {
            if (temperature != null) 'temperature': temperature,
          },
        }),
      );
      if (r.statusCode != 200) {
        throw OllamaException(
          'Generate error ${r.statusCode}: ${r.body}',
        );
      }
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      return (data['response'] as String? ?? '').trim();
    } on OllamaException catch (e, stack) {
      debugPrint('[OllamaClient] generateOnce exception: $e\n$stack');
      rethrow;
    } catch (e, stack) {
      debugPrint('[OllamaClient] generateOnce exception: $e\n$stack');
      throw OllamaException('Błąd generowania: $e');
    }
  }

  // ------------------------------------------------------ generate stream

  /// Streamowana generacja — zwraca `Stream<String>` z fragmentami tekstu
  /// w miarę jak model je produkuje.
  ///
  /// Ollama serwuje NDJSON (każda linia to JSON typu `{"response": "...",
  /// "done": false}`). Parsujemy linia po linii i emitujemy tylko pole
  /// `response`. To jest nasz odpowiednik Server-Sent Events.
  Stream<String> generateStream({
    required String prompt,
    String? model,
    String? system,
    double? temperature,
  }) async* {
    final request = http.Request('POST', Uri.parse('$baseUrl/api/generate'));
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    });
    request.body = jsonEncode({
      'model': model ?? _settings.chatModel,
      'prompt': prompt,
      if (system != null) 'system': system,
      'stream': true,
      'options': {
        if (temperature != null) 'temperature': temperature,
      },
    });

    final http.StreamedResponse response;
    try {
      response = await _client.send(request);
    } catch (e, stack) {
      debugPrint('[OllamaClient] generateStream connection exception: $e\n$stack');
      throw OllamaException('Nie udało się połączyć z Ollama: $e');
    }

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw OllamaException('Stream error ${response.statusCode}: $body');
    }

    // NDJSON: każda linia = osobny obiekt JSON.
    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      if (line.trim().isEmpty) continue;
      try {
        final data = jsonDecode(line) as Map<String, dynamic>;
        final piece = data['response'] as String?;
        if (piece != null && piece.isNotEmpty) yield piece;
        if (data['done'] == true) break;
      } catch (_) {
        // Pomijamy niekompletne fragmenty.
      }
    }
  }

  // ------------------------------------------------------ vision (images)

  /// Wyciąga tekst ze zdjęcia notatki używając modelu wizyjnego (llava).
  /// To naszą wersja OCR — radzi sobie z pismem odręcznym, schematami i
  /// zachowuje strukturę logiczną notatki.
  Future<String> describeImage({
    required List<int> imageBytes,
    String prompt =
        'Przeanalizuj zdjęcie notatek/dokumentu. Wyciągnij CAŁY widoczny tekst '
        'zachowując strukturę (nagłówki, listy, akapity). Jeśli są diagramy '
        'lub wzory matematyczne, opisz je słownie. Nie dodawaj komentarzy '
        'ani interpretacji — sam ekstrakt tekstu.',
  }) async {
    try {
      final r = await _client.post(
        Uri.parse('$baseUrl/api/generate'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'model': _settings.visionModel,
          'prompt': prompt,
          'images': [base64Encode(imageBytes)],
          'stream': false,
        }),
      );
      if (r.statusCode != 200) {
        throw OllamaException(
          'Vision error ${r.statusCode}: ${r.body}',
        );
      }
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      return (data['response'] as String? ?? '').trim();
    } on OllamaException catch (e, stack) {
      debugPrint('[OllamaClient] describeImage exception: $e\n$stack');
      rethrow;
    } catch (e, stack) {
      debugPrint('[OllamaClient] describeImage exception: $e\n$stack');
      throw OllamaException('Błąd analizy obrazu: $e');
    }
  }

  void dispose() => _client.close();
}
