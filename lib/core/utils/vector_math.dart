import 'dart:math' as math;
import 'dart:typed_data';

/// Narzędzia matematyczne dla wektorów embeddingów.
///
/// Embeddingi są przechowywane w SQLite jako BLOB (Float32List) — przy
/// wczytywaniu konwertujemy je z powrotem na `List<double>`, a podobieństwo
/// obliczamy jako klasyczny cosine similarity:
///
/// `cos(θ) = (A·B) / (||A|| · ||B||)`
class VectorMath {
  VectorMath._();

  /// Cosine similarity dwóch wektorów. Zwraca wartość w przedziale [-1, 1];
  /// dla embeddingów semantycznych zazwyczaj 0..1.
  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError(
        'Wektory mają różną długość: ${a.length} vs ${b.length}',
      );
    }
    double dot = 0.0, normA = 0.0, normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    final denom = math.sqrt(normA) * math.sqrt(normB);
    if (denom == 0) return 0.0;
    return dot / denom;
  }

  /// Konwersja `List<double>` → `Uint8List` (binary BLOB do zapisu w SQLite).
  /// Używamy reprezentacji 32-bitowej (4 B na element) — wystarczająca
  /// precyzja dla embeddingów, a oszczędza ~50% miejsca względem Float64.
  static Uint8List vectorToBlob(List<double> vector) {
    final f32 = Float32List.fromList(vector);
    return f32.buffer.asUint8List();
  }

  /// Konwersja BLOB → `List<double>`.
  static List<double> blobToVector(Uint8List blob) {
    // Float32List wymaga aligned ByteBuffer — kopiujemy bajty by tego uniknąć.
    final bytes = Uint8List.fromList(blob);
    final f32 = bytes.buffer.asFloat32List();
    return List<double>.from(f32);
  }
}
