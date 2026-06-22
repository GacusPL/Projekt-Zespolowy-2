import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/column_orderer.dart';

/// Ekstrakcja tekstu z PDF za pomocą `syncfusion_flutter_pdf`
/// (wymóg projektu — zgodnie ze specyfikacją prowadzącego).
///
/// Zamiast surowego `extractText()` (zwraca tekst w kolejności strumienia treści
/// → przeplata kolumny w dokumentach 2-kolumnowych) wyciągamy linie wraz z ich
/// pozycją (`extractTextLines`) i porządkujemy je przez [ColumnOrderer], który
/// wykrywa układ kolumnowy po geometrii.
///
/// Całość biegnie w osobnym isolate ([compute]) — duże PDF-y (kilkadziesiąt MB)
/// nie zawieszają UI. Ekstrakcja jest też odporna per strona: niektóre PDF-y
/// rzucają w `extractTextLines` `RangeError` (bug parsera glifów Syncfusion) —
/// wtedy dana strona spada do `extractText(layoutText: true)` zamiast wywalać
/// cały import.
class PdfTextExtractor {
  Future<String> extract(Uint8List bytes) async {
    try {
      return await compute(_extractPdfText, bytes);
    } on FileProcessingException {
      rethrow;
    } catch (e) {
      throw FileProcessingException('Nie udało się odczytać PDF: $e');
    }
  }
}

/// Funkcja uruchamiana w isolate. Musi być top-level (wymóg [compute]).
String _extractPdfText(Uint8List bytes) {
  final sf.PdfDocument document;
  try {
    document = sf.PdfDocument(inputBytes: bytes);
  } catch (e) {
    throw FileProcessingException('Nie udało się otworzyć PDF: $e');
  }
  try {
    final extractor = sf.PdfTextExtractor(document);
    final pageCount = document.pages.count;
    final buffer = StringBuffer();

    for (var i = 0; i < pageCount; i++) {
      final pageText = _extractPage(extractor, i);
      if (pageText.trim().isNotEmpty) {
        if (buffer.isNotEmpty) buffer.write('\n\n');
        buffer.write(pageText.trim());
      }
    }

    final result = buffer.toString().trim();
    // Awaryjnie: gdyby per-strona nic nie dało, spróbuj całości z układem.
    if (result.isEmpty) {
      try {
        return extractor.extractText(layoutText: true).trim();
      } catch (_) {
        return '';
      }
    }
    return result;
  } finally {
    document.dispose();
  }
}

/// Tekst jednej strony w poprawnej kolejności czytania, z odpornością na błędy
/// parsera dla tej konkretnej strony.
String _extractPage(sf.PdfTextExtractor extractor, int pageIndex) {
  // 1. Z pozycjami → porządkowanie kolumn.
  try {
    final lines = extractor.extractTextLines(
      startPageIndex: pageIndex,
      endPageIndex: pageIndex,
    );
    if (lines.isNotEmpty) {
      final blocks = lines
          .where((l) => l.text.trim().isNotEmpty)
          .map((l) => TextBlock(l.bounds, l.text.trim()))
          .toList();
      final ordered = ColumnOrderer.orderPage(blocks);
      if (ordered.trim().isNotEmpty) return ordered;
    }
  } catch (_) {
    // np. RangeError w parserze glifów — spadamy do fallbacku poniżej.
  }

  // 2. Fallback: zachowujący układ extractText dla tej strony.
  try {
    final t = extractor
        .extractText(
          startPageIndex: pageIndex,
          endPageIndex: pageIndex,
          layoutText: true,
        )
        .trim();
    if (t.isNotEmpty) return t;
  } catch (_) {
    // przejdź do ostatniego fallbacku
  }

  // 3. Ostatni fallback: surowy extractText (kolejność strumienia treści —
  //    może przeplatać kolumny, ale nie gubi tekstu strony).
  try {
    return extractor
        .extractText(startPageIndex: pageIndex, endPageIndex: pageIndex)
        .trim();
  } catch (_) {
    return '';
  }
}
