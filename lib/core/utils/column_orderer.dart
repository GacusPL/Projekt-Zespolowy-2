import 'dart:ui';

/// Pojedynczy blok tekstu (linia) z PDF wraz z jego prostokątem na stronie.
class TextBlock {
  /// Prostokąt w układzie strony (origin lewy-górny, y rośnie w dół).
  final Rect bounds;
  final String text;
  const TextBlock(this.bounds, this.text);
}

/// Porządkuje linie tekstu jednej strony PDF w poprawnej kolejności czytania,
/// wykrywając układ wielokolumnowy po geometrii.
///
/// Problem: parser PDF zwraca tekst w kolejności strumienia treści. Przy 2
/// kolumnach przeplata to lewą i prawą kolumnę, co psuje sens chunków i RAG.
/// Tutaj wykrywamy pionową „rynnę" (gutter) między kolumnami i emitujemy
/// najpierw całą lewą kolumnę, potem prawą — bez przeplatania.
///
/// Logika jest czysta (operuje na [TextBlock], nie na typach Syncfusion), więc
/// jest w pełni testowalna jednostkowo.
class ColumnOrderer {
  ColumnOrderer._();

  /// Linia uznawana za „pełnoszerokią" (nagłówek/stopka/tytuł), gdy zajmuje co
  /// najmniej tyle szerokości strony — takie linie nie biorą udziału w detekcji
  /// kolumn i trafiają do strumienia lewej kolumny na właściwej wysokości.
  static const double _fullWidthFraction = 0.75;

  /// Minimalna liczba linii „body", by w ogóle rozważać układ dwukolumnowy.
  static const int _minBodyLinesForColumns = 4;

  /// Minimalna szerokość rynny (jako ułamek szerokości strony), by uznać ją za
  /// realny rozdział kolumn.
  static const double _minGutterFraction = 0.08;

  /// Minimalna liczba linii w każdej z kolumn.
  static const int _minLinesPerColumn = 2;

  /// Maksymalny ułamek linii „body" mogących przecinać rynnę. Powyżej tego
  /// uznajemy, że to jednak jedna kolumna.
  static const double _gutterStraddleMaxFraction = 0.1;

  /// Zwraca tekst jednej strony w kolejności czytania.
  static String orderPage(List<TextBlock> lines) {
    final blocks = lines.where((b) => b.text.trim().isNotEmpty).toList();
    if (blocks.isEmpty) return '';
    if (blocks.length == 1) return blocks.first.text.trim();

    double minLeft = double.infinity;
    double maxRight = double.negativeInfinity;
    for (final b in blocks) {
      if (b.bounds.left < minLeft) minLeft = b.bounds.left;
      if (b.bounds.right > maxRight) maxRight = b.bounds.right;
    }
    final pageWidth = maxRight - minLeft;
    if (pageWidth <= 0) return _joinByReadingOrder(blocks);

    final fullWidth = <TextBlock>[];
    final body = <TextBlock>[];
    for (final b in blocks) {
      if (b.bounds.width >= _fullWidthFraction * pageWidth) {
        fullWidth.add(b);
      } else {
        body.add(b);
      }
    }

    final split = _detectColumnSplit(body, pageWidth);
    if (split == null) {
      // Jedna kolumna — zwykła kolejność góra→dół.
      return _joinByReadingOrder(blocks);
    }

    final left = <TextBlock>[];
    final right = <TextBlock>[];
    for (final b in body) {
      if (b.bounds.center.dx < split) {
        left.add(b);
      } else {
        right.add(b);
      }
    }
    // Pełnoszerokie (nagłówki/stopki) wpinamy w lewą kolumnę na właściwej
    // wysokości — nie przeplatają wtedy kolumn.
    left.addAll(fullWidth);

    left.sort(_byTop);
    right.sort(_byTop);

    final leftText = left.map((b) => b.text.trim()).join('\n');
    final rightText = right.map((b) => b.text.trim()).join('\n');
    if (leftText.isEmpty) return rightText;
    if (rightText.isEmpty) return leftText;
    return '$leftText\n\n$rightText';
  }

  /// Zwraca pozycję X rozdziału kolumn lub `null`, gdy strona jest jednokolumnowa.
  static double? _detectColumnSplit(List<TextBlock> body, double pageWidth) {
    if (body.length < _minBodyLinesForColumns) return null;

    final centers = body.map((b) => b.bounds.center.dx).toList()..sort();
    double bestGap = 0;
    double split = 0;
    for (var i = 0; i < centers.length - 1; i++) {
      final gap = centers[i + 1] - centers[i];
      if (gap > bestGap) {
        bestGap = gap;
        split = (centers[i] + centers[i + 1]) / 2;
      }
    }
    if (bestGap < _minGutterFraction * pageWidth) return null;

    final leftCount = body.where((b) => b.bounds.center.dx < split).length;
    final rightCount = body.length - leftCount;
    if (leftCount < _minLinesPerColumn || rightCount < _minLinesPerColumn) {
      return null;
    }

    final straddlers = body
        .where((b) => b.bounds.left < split && b.bounds.right > split)
        .length;
    if (straddlers > _gutterStraddleMaxFraction * body.length) return null;

    return split;
  }

  static String _joinByReadingOrder(List<TextBlock> blocks) {
    final sorted = [...blocks]..sort(_byTop);
    return sorted.map((b) => b.text.trim()).join('\n');
  }

  static int _byTop(TextBlock a, TextBlock b) {
    final c = a.bounds.top.compareTo(b.bounds.top);
    if (c != 0) return c;
    return a.bounds.left.compareTo(b.bounds.left);
  }
}
