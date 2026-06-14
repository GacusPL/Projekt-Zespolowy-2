import 'package:equatable/equatable.dart';

/// Pojedyncze pytanie quizu — zawsze 4 opcje, jedna poprawna.
class QuizQuestion extends Equatable {
  final String id;
  final String quizId;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? explanation;

  const QuizQuestion({
    required this.id,
    required this.quizId,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
  });

  @override
  List<Object?> get props =>
      [id, quizId, question, options, correctIndex, explanation];
}

/// Quiz wygenerowany z materiałów przedmiotu.
class Quiz extends Equatable {
  final String id;
  final String subjectId;
  final String title;
  final DateTime createdAt;
  final List<QuizQuestion> questions;

  const Quiz({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.createdAt,
    this.questions = const [],
  });

  Quiz copyWith({List<QuizQuestion>? questions}) => Quiz(
        id: id,
        subjectId: subjectId,
        title: title,
        createdAt: createdAt,
        questions: questions ?? this.questions,
      );

  @override
  List<Object?> get props => [id, subjectId, title, createdAt, questions];
}

/// Podejście studenta do quizu — używamy w statystykach.
class QuizAttempt extends Equatable {
  final String id;
  final String quizId;
  final String subjectId;
  final int score;
  final int totalQuestions;
  final DateTime completedAt;

  const QuizAttempt({
    required this.id,
    required this.quizId,
    required this.subjectId,
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
  });

  double get percentage =>
      totalQuestions == 0 ? 0 : (score / totalQuestions) * 100;

  @override
  List<Object?> get props =>
      [id, quizId, subjectId, score, totalQuestions, completedAt];
}
