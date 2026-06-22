import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/subject.dart';
import '../repositories/subjects_repository.dart';

// Use case-y są celowo cienkie - to "intencje" w terminologii biznesowej.
// Dzięki nim BLoCi nie zależą bezpośrednio od repozytoriów.

class GetSubjectsUseCase {
  final SubjectsRepository repo;
  GetSubjectsUseCase(this.repo);
  Future<Either<Failure, List<Subject>>> call() => repo.getAll();
}

class CreateSubjectUseCase {
  final SubjectsRepository repo;
  CreateSubjectUseCase(this.repo);

  Future<Either<Failure, Subject>> call({
    required String name,
    String? description,
    required int colorValue,
  }) {
    if (name.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure('Nazwa przedmiotu nie może być pusta.')),
      );
    }
    return repo.create(
      name: name.trim(),
      description: description?.trim(),
      colorValue: colorValue,
    );
  }
}

class DeleteSubjectUseCase {
  final SubjectsRepository repo;
  DeleteSubjectUseCase(this.repo);
  Future<Either<Failure, Unit>> call(String id) => repo.delete(id);
}

class GetSubjectByIdUseCase {
  final SubjectsRepository repo;
  GetSubjectByIdUseCase(this.repo);
  Future<Either<Failure, Subject>> call(String id) => repo.getById(id);
}
