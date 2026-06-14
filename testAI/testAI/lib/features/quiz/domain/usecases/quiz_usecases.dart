import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/quiz.dart';
import '../repositories/quiz_repository.dart';

class GetQuizzesUseCase {
  final QuizRepository repo;
  GetQuizzesUseCase(this.repo);
  Future<Either<Failure, List<Quiz>>> call(String subjectId) =>
      repo.getQuizzesBySubject(subjectId);
}

class GetQuizByIdUseCase {
  final QuizRepository repo;
  GetQuizByIdUseCase(this.repo);
  Future<Either<Failure, Quiz>> call(String id) => repo.getQuizById(id);
}

class GenerateQuizUseCase {
  final QuizRepository repo;
  GenerateQuizUseCase(this.repo);
  Future<Either<Failure, Quiz>> call({
    required String subjectId,
    required String title,
    required int questionCount,
  }) =>
      repo.generateQuiz(
        subjectId: subjectId,
        title: title,
        questionCount: questionCount,
      );
}

class DeleteQuizUseCase {
  final QuizRepository repo;
  DeleteQuizUseCase(this.repo);
  Future<Either<Failure, Unit>> call(String id) => repo.deleteQuiz(id);
}

class SaveQuizAttemptUseCase {
  final QuizRepository repo;
  SaveQuizAttemptUseCase(this.repo);
  Future<Either<Failure, QuizAttempt>> call({
    required String quizId,
    required String subjectId,
    required int score,
    required int totalQuestions,
  }) =>
      repo.saveAttempt(
        quizId: quizId,
        subjectId: subjectId,
        score: score,
        totalQuestions: totalQuestions,
      );
}

class GetQuizAttemptsUseCase {
  final QuizRepository repo;
  GetQuizAttemptsUseCase(this.repo);
  Future<Either<Failure, List<QuizAttempt>>> call(String subjectId) =>
      repo.getAttemptsBySubject(subjectId);
}
