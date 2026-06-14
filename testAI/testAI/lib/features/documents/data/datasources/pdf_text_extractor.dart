import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import '../../../../core/errors/exceptions.dart';

/// Ekstrakcja tekstu z PDF za pomocą `syncfusion_flutter_pdf`
/// (wymóg projektu — zgodnie ze specyfikacją prowadzącego).
class PdfTextExtractor {
  String extract(Uint8List bytes) {
    try {
      final document = sf.PdfDocument(inputBytes: bytes);
      try {
        final extractor = sf.PdfTextExtractor(document);
        return extractor.extractText();
      } finally {
        document.dispose();
      }
    } catch (e) {
      throw FileProcessingException(
        'Nie udało się odczytać PDF: $e',
      );
    }
  }
}
