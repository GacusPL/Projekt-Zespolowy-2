import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

/// Fiszka + stan algorytmu SM-2 (spaced repetition).
///
/// Pola algorytmu:
/// - `easeFactor` – współczynnik łatwości (start 2.5, min 1.3)
/// - `intervalDays` – aktualna długość interwału powtórki
/// - `repetitions` – ile razy z rzędu odpowiedź była poprawna (q>=3)
/// - `dueDate` – kiedy fiszka jest należna do powtórki
class Flashcard extends Equatable {
  final String id;
  final String subjectId;
  final String question;
  final String answer;
  final DateTime createdAt;
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime dueDate;
  final DateTime? lastReviewed;

  const Flashcard({
    required this.id,
    required this.subjectId,
    required this.question,
    required this.answer,
    required this.createdAt,
    this.easeFactor = AppConstants.sm2InitialEaseFactor,
    this.intervalDays = 0,
    this.repetitions = 0,
    required this.dueDate,
    this.lastReviewed,
  });

  bool get isDue =>
      dueDate.isBefore(DateTime.now()) ||
      dueDate.isAtSameMomentAs(DateTime.now());

  Flashcard copyWithReview({
    required double easeFactor,
    required int intervalDays,
    required int repetitions,
    required DateTime dueDate,
  }) =>
      Flashcard(
        id: id,
        subjectId: subjectId,
        question: question,
        answer: answer,
        createdAt: createdAt,
        easeFactor: easeFactor,
        intervalDays: intervalDays,
        repetitions: repetitions,
        dueDate: dueDate,
        lastReviewed: DateTime.now(),
      );

  @override
  List<Object?> get props => [
        id,
        subjectId,
        question,
        answer,
        easeFactor,
        intervalDays,
        repetitions,
        dueDate,
        lastReviewed,
      ];
}

/// Ocena studenta przy powtórce — mapuje się na q∈{0..5} algorytmu SM-2.
enum ReviewGrade {
  again, // 0 – nie pamiętam
  hard,  // 3 – z trudem
  good,  // 4 – ok
  easy,  // 5 – łatwo
}

extension ReviewGradeX on ReviewGrade {
  int get q => switch (this) {
        ReviewGrade.again => 0,
        ReviewGrade.hard => 3,
        ReviewGrade.good => 4,
        ReviewGrade.easy => 5,
      };
  String get label => switch (this) {
        ReviewGrade.again => 'Powtórz',
        ReviewGrade.hard => 'Trudne',
        ReviewGrade.good => 'OK',
        ReviewGrade.easy => 'Łatwe',
      };
}
