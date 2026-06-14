import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/flashcard.dart';
import '../../domain/usecases/flashcard_usecases.dart';

// EVENTS
sealed class FlashcardsEvent extends Equatable {
  const FlashcardsEvent();
  @override
  List<Object?> get props => [];
}

class FlashcardsLoadRequested extends FlashcardsEvent {
  final String subjectId;
  const FlashcardsLoadRequested(this.subjectId);
  @override
  List<Object?> get props => [subjectId];
}

class FlashcardsGenerateRequested extends FlashcardsEvent {
  final String subjectId;
  final int count;
  const FlashcardsGenerateRequested(
      {required this.subjectId, required this.count});
  @override
  List<Object?> get props => [subjectId, count];
}

class FlashcardsCreateRequested extends FlashcardsEvent {
  final String subjectId;
  final String question;
  final String answer;
  const FlashcardsCreateRequested({
    required this.subjectId,
    required this.question,
    required this.answer,
  });
  @override
  List<Object?> get props => [subjectId, question, answer];
}

class FlashcardsDeleteRequested extends FlashcardsEvent {
  final String id;
  const FlashcardsDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class FlashcardReviewed extends FlashcardsEvent {
  final Flashcard card;
  final ReviewGrade grade;
  const FlashcardReviewed({required this.card, required this.grade});
  @override
  List<Object?> get props => [card, grade];
}

// STATE
class FlashcardsState extends Equatable {
  final bool loading;
  final bool generating;
  final List<Flashcard> cards;
  final String? error;

  const FlashcardsState({
    this.loading = false,
    this.generating = false,
    this.cards = const [],
    this.error,
  });

  List<Flashcard> get dueCards => cards.where((c) => c.isDue).toList();

  FlashcardsState copyWith({
    bool? loading,
    bool? generating,
    List<Flashcard>? cards,
    String? error,
    bool clearError = false,
  }) =>
      FlashcardsState(
        loading: loading ?? this.loading,
        generating: generating ?? this.generating,
        cards: cards ?? this.cards,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [loading, generating, cards, error];
}

// BLOC
class FlashcardsBloc extends Bloc<FlashcardsEvent, FlashcardsState> {
  final GetFlashcardsUseCase _get;
  final GenerateFlashcardsUseCase _generate;
  final CreateFlashcardUseCase _create;
  final DeleteFlashcardUseCase _delete;
  final ReviewFlashcardUseCase _review;

  FlashcardsBloc({
    required GetFlashcardsUseCase getFlashcards,
    required GenerateFlashcardsUseCase generateFlashcards,
    required CreateFlashcardUseCase createFlashcard,
    required DeleteFlashcardUseCase deleteFlashcard,
    required ReviewFlashcardUseCase reviewFlashcard,
  })  : _get = getFlashcards,
        _generate = generateFlashcards,
        _create = createFlashcard,
        _delete = deleteFlashcard,
        _review = reviewFlashcard,
        super(const FlashcardsState()) {
    on<FlashcardsLoadRequested>(_onLoad);
    on<FlashcardsGenerateRequested>(_onGenerate);
    on<FlashcardsCreateRequested>(_onCreate);
    on<FlashcardsDeleteRequested>(_onDelete);
    on<FlashcardReviewed>(_onReviewed);
  }

  Future<void> _onLoad(FlashcardsLoadRequested e, Emitter emit) async {
    emit(state.copyWith(loading: true, clearError: true));
    final r = await _get(e.subjectId);
    r.fold(
      (f) => emit(state.copyWith(loading: false, error: f.message)),
      (list) => emit(state.copyWith(loading: false, cards: list)),
    );
  }

  Future<void> _onGenerate(FlashcardsGenerateRequested e, Emitter emit) async {
    emit(state.copyWith(generating: true, clearError: true));
    final r =
        await _generate(subjectId: e.subjectId, count: e.count);
    r.fold(
      (f) => emit(state.copyWith(generating: false, error: f.message)),
      (newCards) => emit(state.copyWith(
        generating: false,
        cards: [...newCards, ...state.cards],
      )),
    );
  }

  Future<void> _onCreate(FlashcardsCreateRequested e, Emitter emit) async {
    final r = await _create(
      subjectId: e.subjectId,
      question: e.question,
      answer: e.answer,
    );
    r.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (c) => emit(state.copyWith(cards: [c, ...state.cards])),
    );
  }

  Future<void> _onDelete(FlashcardsDeleteRequested e, Emitter emit) async {
    final r = await _delete(e.id);
    r.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (_) => emit(state.copyWith(
        cards: state.cards.where((c) => c.id != e.id).toList(),
      )),
    );
  }

  Future<void> _onReviewed(FlashcardReviewed e, Emitter emit) async {
    final r = await _review(card: e.card, grade: e.grade);
    r.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (updated) {
        final list = state.cards
            .map((c) => c.id == updated.id ? updated : c)
            .toList();
        emit(state.copyWith(cards: list));
      },
    );
  }
}
