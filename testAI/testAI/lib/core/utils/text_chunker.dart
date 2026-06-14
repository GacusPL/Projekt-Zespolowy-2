import '../constants/app_constants.dart';

/// Dzieli tekst na chunki dla potrzeb RAG.
///
/// Strategia: chunk = ~`chunkSize` słów, z nakładaniem `overlap` słów
/// (zapewnia ciągłość kontekstu między fragmentami).
class TextChunker {
  TextChunker._();

  static List<String> chunk(
    String text, {
    int chunkSize = AppConstants.chunkSize,
    int overlap = AppConstants.chunkOverlap,
  }) {
    // Normalizacja białych znaków (line breaks z PDF-ów potrafią być chaotyczne).
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) return const [];

    final words = normalized.split(' ');
    if (words.length <= chunkSize) return [normalized];

    final step = math_max(1, chunkSize - overlap);
    final chunks = <String>[];

    for (int i = 0; i < words.length; i += step) {
      final end = math_min(i + chunkSize, words.length);
      chunks.add(words.sublist(i, end).join(' '));
      if (end == words.length) break;
    }
    return chunks;
  }

  // Małe lokalne pomocniki (dart:math import w tym samym pliku byłby tu de trop).
  static int math_max(int a, int b) => a > b ? a : b;
  static int math_min(int a, int b) => a < b ? a : b;
}
