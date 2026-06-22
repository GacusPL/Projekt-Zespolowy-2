import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/flashcard.dart';
import '../repositories/flashcards_repository.dart';
import 'sm2_algorithm.dart';

class GetFlashcardsUseCase {
  final FlashcardsRepository repo;
  GetFlashcardsUseCase(this.repo);
  Future<Either<Failure, List<Flashcard>>> call(String subjectId) =>
      repo.getBySubject(subjectId);
}

class GetDueFlashcardsUseCase {
  final FlashcardsRepository repo;
  GetDueFlashcardsUseCase(this.repo);
  Future<Either<Failure, List<Flashcard>>> call(String subjectId) =>
      repo.getDueForReview(subjectId);
}

class GenerateFlashcardsUseCase {
  final FlashcardsRepository repo;
  GenerateFlashcardsUseCase(this.repo);
  Future<Either<Failure, List<Flashcard>>> call({
    required String subjectId,
    required int count,
  }) =>
      repo.generateFromMaterials(subjectId: subjectId, count: count);
}

class CreateFlashcardUseCase {
  final FlashcardsRepository repo;
  CreateFlashcardUseCase(this.repo);
  Future<Either<Failure, Flashcard>> call({
    required String subjectId,
    required String question,
    required String answer,
  }) =>
      repo.create(subjectId: subjectId, question: question, answer: answer);
}

class DeleteFlashcardUseCase {
  final FlashcardsRepository repo;
  DeleteFlashcardUseCase(this.repo);
  Future<Either<Failure, Unit>> call(String id) => repo.delete(id);
}

class EditFlashcardUseCase {
  final FlashcardsRepository repo;
  EditFlashcardUseCase(this.repo);
  Future<Either<Failure, Flashcard>> call({
    required Flashcard card,
    required String question,
    required String answer,
  }) =>
      repo.update(card.copyWith(question: question, answer: answer));
}

class ReviewFlashcardUseCase {
  final FlashcardsRepository repo;
  ReviewFlashcardUseCase(this.repo);
  Future<Either<Failure, Flashcard>> call({
    required Flashcard card,
    required ReviewGrade grade,
  }) {
    final updated = Sm2Algorithm.applyReview(card, grade);
    return repo.update(updated);
  }
}
