import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/quiz.dart';

abstract class QuizRepository {
  Future<Either<Failure, List<Quiz>>> getQuizzesBySubject(String subjectId);
  Future<Either<Failure, Quiz>> getQuizById(String id);
  Future<Either<Failure, Quiz>> generateQuiz({
    required String subjectId,
    required String title,
    required int questionCount,
  });
  Future<Either<Failure, Unit>> deleteQuiz(String id);
  Future<Either<Failure, QuizAttempt>> saveAttempt({
    required String quizId,
    required String subjectId,
    required int score,
    required int totalQuestions,
  });
  Future<Either<Failure, List<QuizAttempt>>> getAttemptsBySubject(
      String subjectId);
}
