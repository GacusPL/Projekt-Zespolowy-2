import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lekturai/core/utils/column_orderer.dart';

TextBlock block(double left, double top, double width, String text,
        {double height = 12}) =>
    TextBlock(Rect.fromLTWH(left, top, width, height), text);

void main() {
  group('ColumnOrderer.orderPage', () {
    test('pusta lista → pusty string', () {
      expect(ColumnOrderer.orderPage([]), '');
    });

    test('jedna kolumna → kolejność góra→dół', () {
      // Wszystkie linie pełnej szerokości, podane w losowej kolejności.
      final out = ColumnOrderer.orderPage([
        block(50, 300, 500, 'trzeci'),
        block(50, 100, 500, 'pierwszy'),
        block(50, 200, 500, 'drugi'),
      ]);
      expect(out, 'pierwszy\ndrugi\ntrzeci');
    });

    test('dwie kolumny → najpierw cała lewa, potem prawa (bez przeplatania)',
        () {
      // Lewa kolumna: x=50..250 (środek 150). Prawa: x=320..520 (środek 420).
      // Topy przeplatane, by udowodnić brak interleavingu.
      final out = ColumnOrderer.orderPage([
        block(320, 120, 200, 'P1'),
        block(50, 100, 200, 'L1'),
        block(320, 220, 200, 'P2'),
        block(50, 200, 200, 'L2'),
      ]);
      expect(out, 'L1\nL2\n\nP1\nP2');
    });

    test('nagłówek pełnej szerokości trafia przed kolumny', () {
      final out = ColumnOrderer.orderPage([
        block(50, 20, 470, 'NAGŁÓWEK'), // pełna szerokość (470/470)
        block(320, 120, 200, 'P1'),
        block(50, 100, 200, 'L1'),
        block(320, 220, 200, 'P2'),
        block(50, 200, 200, 'L2'),
      ]);
      expect(out, 'NAGŁÓWEK\nL1\nL2\n\nP1\nP2');
    });

    test('linie przecinające środek → traktowane jako jedna kolumna', () {
      // Każda linia rozciąga się przez środek strony → brak realnej rynny.
      final out = ColumnOrderer.orderPage([
        block(50, 100, 400, 'a'),
        block(60, 200, 400, 'b'),
        block(40, 300, 420, 'c'),
        block(55, 400, 400, 'd'),
      ]);
      expect(out, 'a\nb\nc\nd');
    });
  });
}
