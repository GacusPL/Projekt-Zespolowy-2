import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/subject.dart';

/// Kontrakt repozytorium przedmiotów (warstwa domeny).
/// Implementacja znajduje się w warstwie data — domena nie wie o SQLite.
abstract class SubjectsRepository {
  Future<Either<Failure, List<Subject>>> getAll();
  Future<Either<Failure, Subject>> create({
    required String name,
    String? description,
    required int colorValue,
  });
  Future<Either<Failure, Unit>> delete(String id);
  Future<Either<Failure, Subject>> getById(String id);
}
