import 'dart:convert';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/ollama_client.dart';
import '../../../../core/settings/ollama_models.dart';
import '../../../../core/utils/text_chunker.dart';
import '../../../../core/utils/vector_math.dart';
import '../../../../shared/database/database_helper.dart';
import '../../domain/entities/document.dart';
import '../models/document_model.dart';
import '../models/document_chunk_model.dart';
import 'pdf_text_extractor.dart';

abstract class DocumentsLocalDataSource {
  Future<List<DocumentModel>> getBySubject(String subjectId);

  /// Wykonuje pełny pipeline: ekstrakcja → chunking → embedding → zapis.
  Future<DocumentModel> uploadDocument({
    required String subjectId,
    required String filename,
    required DocumentType type,
    required Uint8List bytes,
    void Function(double progress, String stage)? onProgress,
  });

  Future<void> delete(String documentId);

  Future<List<DocumentChunkModel>> searchRelevant({
    required String subjectId,
    required String query,
    required int topK,
  });

  Future<List<DocumentChunkModel>> getAllChunksForSubject(String subjectId);
}

class DocumentsLocalDataSourceImpl implements DocumentsLocalDataSource {
  final DatabaseHelper _db;
  final OllamaClient _ollama;
  final PdfTextExtractor _pdf;
  final Uuid _uuid;

  DocumentsLocalDataSourceImpl({
    required DatabaseHelper dbHelper,
    required OllamaClient ollamaClient,
    PdfTextExtractor? pdfExtractor,
    Uuid? uuid,
  })  : _db = dbHelper,
        _ollama = ollamaClient,
        _pdf = pdfExtractor ?? PdfTextExtractor(),
        _uuid = uuid ?? const Uuid();

  // ===========================================================  READS

  @override
  Future<List<DocumentModel>> getBySubject(String subjectId) async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        'documents',
        where: 'subject_id = ?',
        whereArgs: [subjectId],
        orderBy: 'uploaded_at DESC',
      );
      return rows.map(DocumentModel.fromMap).toList();
    } catch (e) {
      throw DatabaseException('Nie udało się odczytać dokumentów: $e');
    }
  }

  @override
  Future<List<DocumentChunkModel>> getAllChunksForSubject(
    String subjectId,
  ) async {
    try {
      final db = await _db.database;
      final rows = await db.rawQuery(
        '''
        SELECT c.*, d.filename AS doc_filename
        FROM chunks c
        JOIN documents d ON d.id = c.document_id
        WHERE c.subject_id = ?
        ORDER BY d.uploaded_at DESC, c.chunk_index ASC
        ''',
        [subjectId],
      );
      return rows.map(DocumentChunkModel.fromMap).toList();
    } catch (e) {
      throw DatabaseException('Błąd odczytu chunków: $e');
    }
  }

  // ===========================================================  UPLOAD

  @override
  Future<DocumentModel> uploadDocument({
    required String subjectId,
    required String filename,
    required DocumentType type,
    required Uint8List bytes,
    void Function(double progress, String stage)? onProgress,
  }) async {
    // ----- 1. Ekstrakcja tekstu z pliku -----
    onProgress?.call(0.05, 'Ekstrakcja treści…');
    final String text;
    switch (type) {
      case DocumentType.pdf:
        text = _pdf.extract(bytes);
        break;
      case DocumentType.image:
        // Multimodalny "OCR" przez Ollama vision (llava). Działa też na
        // pisemnych notatkach i rozumie schematy.
        text = await _ollama.describeImage(imageBytes: bytes);
        break;
      case DocumentType.text:
        text = utf8.decode(bytes, allowMalformed: true);
        break;
    }

    if (text.trim().isEmpty) {
      throw FileProcessingException(
        'Z pliku nie udało się wyciągnąć żadnego tekstu.',
      );
    }

    // ----- 2. Chunking -----
    onProgress?.call(0.20, 'Dzielenie na fragmenty…');
    final chunks = TextChunker.chunk(text);
    if (chunks.isEmpty) {
      throw FileProcessingException('Tekst jest pusty po normalizacji.');
    }

    // ----- 3. Wstaw rekord dokumentu (jeszcze bez chunk_count) -----
    final db = await _db.database;
    final doc = DocumentModel(
      id: _uuid.v4(),
      subjectId: subjectId,
      filename: filename,
      fileType: type,
      chunkCount: 0,
      uploadedAt: DateTime.now(),
    );
    await db.insert('documents', doc.toMap());

    // ----- 4. Generuj embeddingi i zapisuj porcjami -----
    final batchSize = chunks.length;
    int idx = 0;
    final batch = db.batch();

    for (final content in chunks) {
      onProgress?.call(
        0.25 + 0.7 * (idx / batchSize),
        'Embedding ${idx + 1} / $batchSize…',
      );

      final embedding = await _ollama.generateEmbedding(content);
      // Wymiar oczekiwany zależy od wybranego modelu (np. nomic-embed-text=768,
      // bge-m3=1024). Dla modeli spoza katalogu wymiar jest nieznany — wtedy
      // akceptujemy to, co zwróci Ollama (brak twardej walidacji).
      final expectedDim =
          OllamaModels.embeddingDimensionFor(_ollama.embeddingModel);
      if (expectedDim != null && embedding.length != expectedDim) {
        throw OllamaException(
          'Nieoczekiwany wymiar embeddingu: ${embedding.length} '
          '(model ${_ollama.embeddingModel} oczekuje $expectedDim).',
        );
      }
      batch.insert('chunks', {
        'id': _uuid.v4(),
        'document_id': doc.id,
        'subject_id': subjectId,
        'chunk_index': idx,
        'content': content,
        'embedding': VectorMath.vectorToBlob(embedding),
      });
      idx++;
    }
    await batch.commit(noResult: true);

    // ----- 5. Zaktualizuj chunk_count -----
    await db.update(
      'documents',
      {'chunk_count': chunks.length},
      where: 'id = ?',
      whereArgs: [doc.id],
    );
    onProgress?.call(1.0, 'Gotowe!');

    return DocumentModel(
      id: doc.id,
      subjectId: doc.subjectId,
      filename: doc.filename,
      fileType: doc.fileType,
      chunkCount: chunks.length,
      uploadedAt: doc.uploadedAt,
    );
  }

  // ===========================================================  DELETE

  @override
  Future<void> delete(String documentId) async {
    try {
      final db = await _db.database;
      // Chunki znikną przez ON DELETE CASCADE.
      await db.delete('documents', where: 'id = ?', whereArgs: [documentId]);
    } catch (e) {
      throw DatabaseException('Błąd usuwania dokumentu: $e');
    }
  }

  // ===========================================================  SEARCH

  @override
  Future<List<DocumentChunkModel>> searchRelevant({
    required String subjectId,
    required String query,
    required int topK,
  }) async {
    // 1. Embedding zapytania
    final queryEmb = await _ollama.generateEmbedding(query);

    // 2. Wczytaj wszystkie chunki przedmiotu
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT c.*, d.filename AS doc_filename
      FROM chunks c
      JOIN documents d ON d.id = c.document_id
      WHERE c.subject_id = ?
      ''',
      [subjectId],
    );
    if (rows.isEmpty) return [];

    // 3. Cosine similarity dla każdego chunku
    final scored = <_ScoredRow>[];
    for (final row in rows) {
      final blob = row['embedding'] as Uint8List;
      final emb = VectorMath.blobToVector(blob);
      // Pomijamy chunki zapisane innym modelem embeddingów (inny wymiar) —
      // cosine similarity wymaga zgodnych długości. Inaczej zmiana modelu bez
      // ponownego wgrania dokumentów wywaliłaby wyszukiwanie.
      if (emb.length != queryEmb.length) continue;
      final sim = VectorMath.cosineSimilarity(queryEmb, emb);
      if (sim < AppConstants.minSimilarityThreshold) continue;
      scored.add(_ScoredRow(row, sim));
    }

    // 4. Sortuj malejąco i weź topK
    scored.sort((a, b) => b.score.compareTo(a.score));
    final top = scored.take(topK);

    return top.map((s) => DocumentChunkModel.fromMap(s.row, similarity: s.score)).toList();
  }
}

class _ScoredRow {
  final Map<String, dynamic> row;
  final double score;
  _ScoredRow(this.row, this.score);
}
