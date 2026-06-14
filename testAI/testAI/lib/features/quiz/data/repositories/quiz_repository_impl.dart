import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/quiz.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../datasources/quiz_datasource.dart';

class QuizRepositoryImpl implements QuizRepository {
  final QuizDataSource _ds;
  QuizRepositoryImpl(this._ds);

  Failure _toFailure(Object e) {
    if (e is OllamaException) return OllamaFailure(e.message);
    if (e is DatabaseException) return DatabaseFailure(e.message);
    if (e is FileProcessingException) return FileProcessingFailure(e.message);
    return UnknownFailure(e.toString());
  }

  @override
  Future<Either<Failure, List<Quiz>>> getQuizzesBySubject(
      String subjectId) async {
    try {
      return Right(await _ds.getQuizzesBySubject(subjectId));
    } catch (e) {
      return Left(_toFailure(e));
    }
  }

  @override
  Future<Either<Failure, Quiz>> getQuizById(String id) async {
    try {
      return Right(await _ds.getQuizById(id));
    } catch (e) {
      return Left(_toFailure(e));
    }
  }

  @override
  Future<Either<Failure, Quiz>> generateQuiz({
    required String subjectId,
    required String title,
    required int questionCount,
  }) async {
    try {
      return Right(await _ds.generateQuiz(
        subjectId: subjectId,
        title: title,
        questionCount: questionCount,
      ));
    } catch (e) {
      return Left(_toFailure(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteQuiz(String id) async {
    try {
      await _ds.deleteQuiz(id);
      return const Right(unit);
    } catch (e) {
      return Left(_toFailure(e));
    }
  }

  @override
  Future<Either<Failure, QuizAttempt>> saveAttempt({
    required String quizId,
    required String subjectId,
    required int score,
    required int totalQuestions,
  }) async {
    try {
      return Right(await _ds.saveAttempt(
        quizId: quizId,
        subjectId: subjectId,
        score: score,
        totalQuestions: totalQuestions,
      ));
    } catch (e) {
      return Left(_toFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<QuizAttempt>>> getAttemptsBySubject(
      String subjectId) async {
    try {
      return Right(await _ds.getAttemptsBySubject(subjectId));
    } catch (e) {
      return Left(_toFailure(e));
    }
  }
}
