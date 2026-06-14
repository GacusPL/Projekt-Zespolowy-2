import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/document.dart';
import '../entities/document_chunk.dart';

abstract class DocumentsRepository {
  Future<Either<Failure, List<Document>>> getBySubject(String subjectId);

  /// Pełny pipeline RAG dla pliku:
  /// PDF/obraz → ekstrakcja tekstu → chunking → embeddingi → zapis w DB.
  Future<Either<Failure, Document>> uploadDocument({
    required String subjectId,
    required String filename,
    required DocumentType type,
    required Uint8List bytes,
    void Function(double progress, String stage)? onProgress,
  });

  Future<Either<Failure, Unit>> delete(String documentId);

  /// Wyszukiwanie semantyczne wśród chunków danego przedmiotu.
  Future<Either<Failure, List<DocumentChunk>>> searchRelevant({
    required String subjectId,
    required String query,
    int topK,
  });

  /// Wszystkie chunki przedmiotu (do generowania fiszek / quizów).
  Future<Either<Failure, List<DocumentChunk>>> getAllChunksForSubject(
    String subjectId,
  );
}
