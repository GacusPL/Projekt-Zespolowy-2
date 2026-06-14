import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/subject.dart';
import '../../domain/repositories/subjects_repository.dart';
import '../datasources/subjects_local_datasource.dart';

class SubjectsRepositoryImpl implements SubjectsRepository {
  final SubjectsLocalDataSource _local;
  SubjectsRepositoryImpl(this._local);

  @override
  Future<Either<Failure, List<Subject>>> getAll() async {
    try {
      final list = await _local.getAll();
      return Right(list);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Subject>> create({
    required String name,
    String? description,
    required int colorValue,
  }) async {
    try {
      final s = await _local.create(
        name: name,
        description: description,
        colorValue: colorValue,
      );
      return Right(s);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> delete(String id) async {
    try {
      await _local.delete(id);
      return const Right(unit);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Subject>> getById(String id) async {
    try {
      final s = await _local.getById(id);
      return Right(s);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
