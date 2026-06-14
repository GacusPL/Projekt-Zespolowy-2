import '../../domain/entities/flashcard.dart';

class FlashcardModel extends Flashcard {
  const FlashcardModel({
    required super.id,
    required super.subjectId,
    required super.question,
    required super.answer,
    required super.createdAt,
    super.easeFactor,
    super.intervalDays,
    super.repetitions,
    required super.dueDate,
    super.lastReviewed,
  });

  factory FlashcardModel.fromMap(Map<String, dynamic> m) => FlashcardModel(
        id: m['id'] as String,
        subjectId: m['subject_id'] as String,
        question: m['question'] as String,
        answer: m['answer'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        easeFactor: (m['ease_factor'] as num).toDouble(),
        intervalDays: m['interval_days'] as int,
        repetitions: m['repetitions'] as int,
        dueDate: DateTime.fromMillisecondsSinceEpoch(m['due_date'] as int),
        lastReviewed: m['last_reviewed'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['last_reviewed'] as int)
            : null,
      );

  factory FlashcardModel.fromEntity(Flashcard f) => FlashcardModel(
        id: f.id,
        subjectId: f.subjectId,
        question: f.question,
        answer: f.answer,
        createdAt: f.createdAt,
        easeFactor: f.easeFactor,
        intervalDays: f.intervalDays,
        repetitions: f.repetitions,
        dueDate: f.dueDate,
        lastReviewed: f.lastReviewed,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'subject_id': subjectId,
        'question': question,
        'answer': answer,
        'created_at': createdAt.millisecondsSinceEpoch,
        'ease_factor': easeFactor,
        'interval_days': intervalDays,
        'repetitions': repetitions,
        'due_date': dueDate.millisecondsSinceEpoch,
        'last_reviewed': lastReviewed?.millisecondsSinceEpoch,
      };
}
