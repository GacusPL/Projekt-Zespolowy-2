import 'package:flutter_test/flutter_test.dart';
import 'package:lekturai/core/utils/vector_math.dart';

void main() {
  group('VectorMath.cosineSimilarity', () {
    test('identyczne wektory → 1.0', () {
      expect(VectorMath.cosineSimilarity([1, 2, 3], [1, 2, 3]), closeTo(1.0, 1e-9));
    });

    test('wektory prostopadłe → 0.0', () {
      expect(VectorMath.cosineSimilarity([1, 0], [0, 1]), closeTo(0.0, 1e-9));
    });

    test('wektory przeciwne → -1.0', () {
      expect(VectorMath.cosineSimilarity([1, 2], [-1, -2]), closeTo(-1.0, 1e-9));
    });

    test('wektor zerowy → 0.0 (brak dzielenia przez zero)', () {
      expect(VectorMath.cosineSimilarity([0, 0], [1, 2]), 0.0);
    });

    test('różne długości → ArgumentError', () {
      expect(
        () => VectorMath.cosineSimilarity([1, 2], [1, 2, 3]),
        throwsArgumentError,
      );
    });
  });

  group('VectorMath blob roundtrip', () {
    test('vectorToBlob → blobToVector zachowuje wartości (Float32)', () {
      final v = [0.1, -2.5, 3.14159, 0.0, 768.0];
      final blob = VectorMath.vectorToBlob(v);
      final back = VectorMath.blobToVector(blob);
      expect(back.length, v.length);
      for (var i = 0; i < v.length; i++) {
        expect(back[i], closeTo(v[i], 1e-4)); // precyzja Float32
      }
    });

    test('blob ma 4 bajty na element', () {
      final blob = VectorMath.vectorToBlob([1, 2, 3]);
      expect(blob.length, 12);
    });
  });
}
