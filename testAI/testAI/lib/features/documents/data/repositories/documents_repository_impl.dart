import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/document.dart';
import '../../domain/entities/document_chunk.dart';
import '../../domain/repositories/documents_repository.dart';
import '../datasources/documents_local_datasource.dart';

class DocumentsRepositoryImpl implements DocumentsRepository {
  final DocumentsLocalDataSource _local;
  DocumentsRepositoryImpl(this._local);

  @override
  Future<Either<Failure, List<Document>>> getBySubject(String subjectId) async {
    try {
      final list = await _local.getBySubject(subjectId);
      return Right(list);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Document>> uploadDocument({
    required String subjectId,
    required String filename,
    required DocumentType type,
    required Uint8List bytes,
    void Function(double progress, String stage)? onProgress,
  }) async {
    try {
      final d = await _local.uploadDocument(
        subjectId: subjectId,
        filename: filename,
        type: type,
        bytes: bytes,
        onProgress: onProgress,
      );
      return Right(d);
    } on OllamaException catch (e) {
      return Left(OllamaFailure(e.message));
    } on FileProcessingException catch (e) {
      return Left(FileProcessingFailure(e.message));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> delete(String documentId) async {
    try {
      await _local.delete(documentId);
      return const Right(unit);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DocumentChunk>>> searchRelevant({
    required String subjectId,
    required String query,
    int topK = 5,
  }) async {
    try {
      final list = await _local.searchRelevant(
        subjectId: subjectId,
        query: query,
        topK: topK,
      );
      return Right(list);
    } on OllamaException catch (e) {
      return Left(OllamaFailure(e.message));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DocumentChunk>>> getAllChunksForSubject(
    String subjectId,
  ) async {
    try {
      final list = await _local.getAllChunksForSubject(subjectId);
      return Right(list);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
