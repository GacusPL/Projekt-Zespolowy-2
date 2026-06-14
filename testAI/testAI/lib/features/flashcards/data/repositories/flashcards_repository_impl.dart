import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/flashcard.dart';
import '../../domain/repositories/flashcards_repository.dart';
import '../datasources/flashcards_datasource.dart';

class FlashcardsRepositoryImpl implements FlashcardsRepository {
  final FlashcardsDataSource _ds;
  FlashcardsRepositoryImpl(this._ds);

  Either<Failure, T> _wrap<T>(T value) => Right(value);
  Failure _toFailure(Object e) {
    if (e is OllamaException) return OllamaFailure(e.message);
    if (e is DatabaseException) return DatabaseFailure(e.message);
    if (e is FileProcessingException) return FileProcessingFailure(e.message);
    return UnknownFailure(e.toString());
  }

  @override
  Future<Either<Failure, List<Flashcard>>> getBySubject(String s) async {
    try {
      return _wrap(await _ds.getBySubject(s));
    } catch (e) {
      return Left(_toFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<Flashcard>>> getDueForReview(String s) async {
    try {
      return _wrap(await _ds.getDueForReview(s));
    } catch (e) {
      return Left(_toFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<Flashcard>>> generateFromMaterials({
    required String subjectId,
    required int count,
  }) async {
    try {
      return _wrap(await _ds.generateFromMaterials(
        subjectId: subjectId,
        count: count,
      ));
    } catch (e) {
      return Left(_toFailure(e));
    }
  }

  @override
  Future<Either<Failure, Flashcard>> create({
    required String subjectId,
    required String question,
    required String answer,
  }) async {
    try {
      return _wrap(await _ds.create(
        subjectId: subjectId,
        question: question,
        answer: answer,
      ));
    } catch (e) {
      return Left(_toFailure(e));
    }
  }

  @override
  Future<Either<Failure, Flashcard>> update(Flashcard card) async {
    try {
      return _wrap(await _ds.update(card));
    } catch (e) {
      return Left(_toFailure(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> delete(String id) async {
    try {
      await _ds.delete(id);
      return const Right(unit);
    } catch (e) {
      return Left(_toFailure(e));
    }
  }
}
