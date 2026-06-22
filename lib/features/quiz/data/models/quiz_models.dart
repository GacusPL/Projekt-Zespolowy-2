import 'dart:convert';

import '../../domain/entities/quiz.dart';

class QuizModel extends Quiz {
  const QuizModel({
    required super.id,
    required super.subjectId,
    required super.title,
    required super.createdAt,
    super.questions,
  });

  factory QuizModel.fromMap(
    Map<String, dynamic> m, {
    List<QuizQuestion> questions = const [],
  }) =>
      QuizModel(
        id: m['id'] as String,
        subjectId: m['subject_id'] as String,
        title: m['title'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        questions: questions,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'subject_id': subjectId,
        'title': title,
        'created_at': createdAt.millisecondsSinceEpoch,
      };
}

class QuizQuestionModel extends QuizQuestion {
  const QuizQuestionModel({
    required super.id,
    required super.quizId,
    required super.question,
    required super.options,
    required super.correctIndex,
    super.explanation,
  });

  factory QuizQuestionModel.fromMap(Map<String, dynamic> m) =>
      QuizQuestionModel(
        id: m['id'] as String,
        quizId: m['quiz_id'] as String,
        question: m['question'] as String,
        options:
            (jsonDecode(m['options_json'] as String) as List).cast<String>(),
        correctIndex: m['correct_index'] as int,
        explanation: m['explanation'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'quiz_id': quizId,
        'question': question,
        'options_json': jsonEncode(options),
        'correct_index': correctIndex,
        'explanation': explanation,
      };
}

class QuizAttemptModel extends QuizAttempt {
  const QuizAttemptModel({
    required super.id,
    required super.quizId,
    required super.subjectId,
    required super.score,
    required super.totalQuestions,
    required super.completedAt,
  });

  factory QuizAttemptModel.fromMap(Map<String, dynamic> m) => QuizAttemptModel(
        id: m['id'] as String,
        quizId: m['quiz_id'] as String,
        subjectId: m['subject_id'] as String,
        score: m['score'] as int,
        totalQuestions: m['total_questions'] as int,
        completedAt:
            DateTime.fromMillisecondsSinceEpoch(m['completed_at'] as int),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'quiz_id': quizId,
        'subject_id': subjectId,
        'score': score,
        'total_questions': totalQuestions,
        'completed_at': completedAt.millisecondsSinceEpoch,
      };
}
