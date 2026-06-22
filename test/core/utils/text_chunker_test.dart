import 'package:flutter_test/flutter_test.dart';
import 'package:LekturAI/core/utils/text_chunker.dart';

void main() {
  group('TextChunker.chunk', () {
    test('pusty tekst → pusta lista', () {
      expect(TextChunker.chunk('   '), isEmpty);
    });

    test('tekst krótszy niż chunkSize → jeden chunk', () {
      final out = TextChunker.chunk('jedno dwa trzy', chunkSize: 10);
      expect(out, ['jedno dwa trzy']);
    });

    test('normalizuje białe znaki', () {
      final out = TextChunker.chunk('a\n\n  b\t c', chunkSize: 10);
      expect(out, ['a b c']);
    });

    test('dzieli długi tekst z nakładaniem', () {
      final words = List.generate(10, (i) => 'w$i').join(' ');
      final out = TextChunker.chunk(words, chunkSize: 4, overlap: 2);
      // step = 4-2 = 2 → start na indeksach 0,2,4,6 (do końca przy 6..10)
      expect(out.first, 'w0 w1 w2 w3');
      expect(out[1], 'w2 w3 w4 w5'); // nakładanie 2 słów
      expect(out.last.endsWith('w9'), isTrue);
    });

    test('overlap >= chunkSize nie zapętla (step>=1)', () {
      final words = List.generate(6, (i) => 'w$i').join(' ');
      final out = TextChunker.chunk(words, chunkSize: 2, overlap: 5);
      expect(out, isNotEmpty);
      expect(out.last.endsWith('w5'), isTrue);
    });
  });
}
