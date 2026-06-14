import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../entities/document.dart';
import '../entities/document_chunk.dart';
import '../repositories/documents_repository.dart';

class GetDocumentsUseCase {
  final DocumentsRepository repo;
  GetDocumentsUseCase(this.repo);
  Future<Either<Failure, List<Document>>> call(String subjectId) =>
      repo.getBySubject(subjectId);
}

class UploadDocumentUseCase {
  final DocumentsRepository repo;
  UploadDocumentUseCase(this.repo);

  Future<Either<Failure, Document>> call({
    required String subjectId,
    required String filename,
    required DocumentType type,
    required Uint8List bytes,
    void Function(double, String)? onProgress,
  }) =>
      repo.uploadDocument(
        subjectId: subjectId,
        filename: filename,
        type: type,
        bytes: bytes,
        onProgress: onProgress,
      );
}

class DeleteDocumentUseCase {
  final DocumentsRepository repo;
  DeleteDocumentUseCase(this.repo);
  Future<Either<Failure, Unit>> call(String id) => repo.delete(id);
}

class SearchRelevantChunksUseCase {
  final DocumentsRepository repo;
  SearchRelevantChunksUseCase(this.repo);
  Future<Either<Failure, List<DocumentChunk>>> call({
    required String subjectId,
    required String query,
    int topK = AppConstants.topKChunks,
  }) =>
      repo.searchRelevant(subjectId: subjectId, query: query, topK: topK);
}

class GetAllChunksUseCase {
  final DocumentsRepository repo;
  GetAllChunksUseCase(this.repo);
  Future<Either<Failure, List<DocumentChunk>>> call(String subjectId) =>
      repo.getAllChunksForSubject(subjectId);
}
