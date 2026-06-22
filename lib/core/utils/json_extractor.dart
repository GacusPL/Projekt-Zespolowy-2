import 'dart:convert';

/// Pomocnik wyciągający JSON z odpowiedzi LLM.
///
/// Modele lubią owijać JSON w ```json … ``` albo dodawać "Oto wynik:" przed
/// nim. Tu próbujemy znaleźć i sparsować pierwszy poprawny obiekt JSON.
class JsonExtractor {
  JsonExtractor._();

  static Map<String, dynamic>? tryExtractObject(String raw) {
    final text = raw.trim();

    // 1. Najpierw spróbuj wprost
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}

    // 2. Zdejmij ewentualne ```json … ```
    final fenceMatch =
        RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(text);
    if (fenceMatch != null) {
      try {
        final decoded = jsonDecode(fenceMatch.group(1)!);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }

    // 3. Wytnij od pierwszego '{' do ostatniego '}'
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end > start) {
      try {
        final decoded = jsonDecode(text.substring(start, end + 1));
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return null;
  }
}
