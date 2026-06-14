import 'dart:math' as math;

import '../../../../core/constants/app_constants.dart';
import '../entities/flashcard.dart';

/// Implementacja algorytmu SuperMemo SM-2 (Piotr Woźniak, 1990).
/// Klasyczna formuła używana m.in. w Anki.
///
/// q – ocena 0..5
/// EF' = EF + (0.1 − (5 − q) × (0.08 + (5 − q) × 0.02))   ; min 1.3
/// jeśli q < 3: reset (interval=0, repetitions=0)
/// w przeciwnym razie:
///   repetitions==0 → interval = 1 dzień
///   repetitions==1 → interval = 6 dni
///   repetitions>=2 → interval = round(prevInterval * EF')
class Sm2Algorithm {
  Sm2Algorithm._();

  static Flashcard applyReview(Flashcard card, ReviewGrade grade) {
    final q = grade.q;
    double ef = card.easeFactor +
        (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
    if (ef < AppConstants.sm2MinEaseFactor) {
      ef = AppConstants.sm2MinEaseFactor;
    }

    int repetitions;
    int interval;

    if (q < 3) {
      // niepowodzenie — wracamy do początku
      repetitions = 0;
      interval = 0;
    } else {
      repetitions = card.repetitions + 1;
      if (repetitions == 1) {
        interval = 1;
      } else if (repetitions == 2) {
        interval = 6;
      } else {
        interval = math.max(1, (card.intervalDays * ef).round());
      }
    }

    final dueDate = DateTime.now().add(Duration(
      days: interval == 0 ? 0 : interval,
      // interval=0 (q<3) ustawiamy "teraz" — fiszka znów wpadnie do kolejki
      minutes: interval == 0 ? 10 : 0,
    ));

    return card.copyWithReview(
      easeFactor: ef,
      intervalDays: interval,
      repetitions: repetitions,
      dueDate: dueDate,
    );
  }
}
