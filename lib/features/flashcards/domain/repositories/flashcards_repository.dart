import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/flashcard.dart';

abstract class FlashcardsRepository {
  Future<Either<Failure, List<Flashcard>>> getBySubject(String subjectId);
  Future<Either<Failure, List<Flashcard>>> getDueForReview(String subjectId);

  /// Generuje fiszki z materiałów przedmiotu za pomocą LLM.
  Future<Either<Failure, List<Flashcard>>> generateFromMaterials({
    required String subjectId,
    required int count,
  });

  Future<Either<Failure, Flashcard>> update(Flashcard card);
  Future<Either<Failure, Unit>> delete(String id);
  Future<Either<Failure, Flashcard>> create({
    required String subjectId,
    required String question,
    required String answer,
  });
}
