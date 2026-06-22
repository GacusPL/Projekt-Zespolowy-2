import 'package:flutter_test/flutter_test.dart';
import 'package:LekturAI/core/constants/app_constants.dart';
import 'package:LekturAI/features/flashcards/domain/entities/flashcard.dart';
import 'package:LekturAI/features/flashcards/domain/usecases/sm2_algorithm.dart';

Flashcard _newCard({
  double easeFactor = AppConstants.sm2InitialEaseFactor,
  int intervalDays = 0,
  int repetitions = 0,
}) {
  final now = DateTime.now();
  return Flashcard(
    id: '1',
    subjectId: 's',
    question: 'q',
    answer: 'a',
    createdAt: now,
    easeFactor: easeFactor,
    intervalDays: intervalDays,
    repetitions: repetitions,
    dueDate: now,
  );
}

void main() {
  group('Sm2Algorithm.applyReview', () {
    test('pierwsza poprawna powtórka (good): interval=1, repetitions=1', () {
      final r = Sm2Algorithm.applyReview(_newCard(), ReviewGrade.good);
      expect(r.repetitions, 1);
      expect(r.intervalDays, 1);
      expect(r.easeFactor, closeTo(2.5, 1e-9)); // q=4 nie zmienia EF
    });

    test('druga poprawna powtórka: interval=6', () {
      final r = Sm2Algorithm.applyReview(
        _newCard(repetitions: 1, intervalDays: 1),
        ReviewGrade.good,
      );
      expect(r.repetitions, 2);
      expect(r.intervalDays, 6);
    });

    test('trzecia powtórka: interval=round(prevInterval*EF)', () {
      final card = _newCard(repetitions: 2, intervalDays: 6, easeFactor: 2.5);
      final r = Sm2Algorithm.applyReview(card, ReviewGrade.good);
      expect(r.repetitions, 3);
      expect(r.intervalDays, 15); // round(6 * 2.5)
    });

    test('grade easy (q=5) podnosi EF o 0.1', () {
      final r = Sm2Algorithm.applyReview(_newCard(), ReviewGrade.easy);
      expect(r.easeFactor, closeTo(2.6, 1e-9));
    });

    test('grade again (q<3) resetuje repetitions i interval', () {
      final card = _newCard(repetitions: 5, intervalDays: 30);
      final r = Sm2Algorithm.applyReview(card, ReviewGrade.again);
      expect(r.repetitions, 0);
      expect(r.intervalDays, 0);
    });

    test('EF nie spada poniżej minimum (1.3)', () {
      final card = _newCard(easeFactor: AppConstants.sm2MinEaseFactor);
      final r = Sm2Algorithm.applyReview(card, ReviewGrade.again);
      expect(r.easeFactor, AppConstants.sm2MinEaseFactor);
    });

    test('lastReviewed jest ustawiane po powtórce', () {
      final r = Sm2Algorithm.applyReview(_newCard(), ReviewGrade.good);
      expect(r.lastReviewed, isNotNull);
    });
  });
}
