import 'package:flutter_test/flutter_test.dart';
import 'package:LekturAI/core/utils/json_extractor.dart';

void main() {
  group('JsonExtractor.tryExtractObject', () {
    test('czysty obiekt JSON', () {
      final r = JsonExtractor.tryExtractObject('{"a": 1, "b": "x"}');
      expect(r, {'a': 1, 'b': 'x'});
    });

    test('JSON owinięty w ```json ... ```', () {
      const raw = '```json\n{"cards": [1, 2]}\n```';
      final r = JsonExtractor.tryExtractObject(raw);
      expect(r?['cards'], [1, 2]);
    });

    test('JSON poprzedzony tekstem ("Oto wynik:")', () {
      const raw = 'Oto wynik:\n{"questions": []} dziękuję';
      final r = JsonExtractor.tryExtractObject(raw);
      expect(r, {'questions': []});
    });

    test('niepoprawny tekst → null', () {
      expect(JsonExtractor.tryExtractObject('to nie jest json'), isNull);
    });

    test('tablica na najwyższym poziomie → null (oczekiwany obiekt)', () {
      expect(JsonExtractor.tryExtractObject('[1, 2, 3]'), isNull);
    });
  });
}
