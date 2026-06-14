import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/quiz.dart';
import '../../domain/usecases/quiz_usecases.dart';

// ============================================================== EVENTS
sealed class QuizEvent extends Equatable {
  const QuizEvent();
  @override
  List<Object?> get props => [];
}

class QuizListLoadRequested extends QuizEvent {
  final String subjectId;
  const QuizListLoadRequested(this.subjectId);
  @override
  List<Object?> get props => [subjectId];
}

class QuizGenerateRequested extends QuizEvent {
  final String subjectId;
  final String title;
  final int questionCount;
  const QuizGenerateRequested({
    required this.subjectId,
    required this.title,
    required this.questionCount,
  });
  @override
  List<Object?> get props => [subjectId, title, questionCount];
}

class QuizDeleteRequested extends QuizEvent {
  final String id;
  const QuizDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class QuizOpenRequested extends QuizEvent {
  final String id;
  const QuizOpenRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class QuizAttemptSaveRequested extends QuizEvent {
  final String quizId;
  final String subjectId;
  final int score;
  final int totalQuestions;
  const QuizAttemptSaveRequested({
    required this.quizId,
    required this.subjectId,
    required this.score,
    required this.totalQuestions,
  });
  @override
  List<Object?> get props => [quizId, subjectId, score, totalQuestions];
}

// ============================================================== STATE
class QuizState extends Equatable {
  final bool loading;
  final bool generating;
  final List<Quiz> quizzes;
  final Quiz? activeQuiz;
  final String? error;

  const QuizState({
    this.loading = false,
    this.generating = false,
    this.quizzes = const [],
    this.activeQuiz,
    this.error,
  });

  QuizState copyWith({
    bool? loading,
    bool? generating,
    List<Quiz>? quizzes,
    Quiz? activeQuiz,
    bool clearActive = false,
    String? error,
    bool clearError = false,
  }) =>
      QuizState(
        loading: loading ?? this.loading,
        generating: generating ?? this.generating,
        quizzes: quizzes ?? this.quizzes,
        activeQuiz:
            clearActive ? null : (activeQuiz ?? this.activeQuiz),
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [loading, generating, quizzes, activeQuiz, error];
}

// ============================================================== BLOC
class QuizBloc extends Bloc<QuizEvent, QuizState> {
  final GetQuizzesUseCase _getQuizzes;
  final GetQuizByIdUseCase _getById;
  final GenerateQuizUseCase _generate;
  final DeleteQuizUseCase _delete;
  final SaveQuizAttemptUseCase _saveAttempt;

  QuizBloc({
    required GetQuizzesUseCase getQuizzes,
    required GetQuizByIdUseCase getQuizById,
    required GenerateQuizUseCase generateQuiz,
    required DeleteQuizUseCase deleteQuiz,
    required SaveQuizAttemptUseCase saveAttempt,
  })  : _getQuizzes = getQuizzes,
        _getById = getQuizById,
        _generate = generateQuiz,
        _delete = deleteQuiz,
        _saveAttempt = saveAttempt,
        super(const QuizState()) {
    on<QuizListLoadRequested>(_onLoadList);
    on<QuizGenerateRequested>(_onGenerate);
    on<QuizDeleteRequested>(_onDelete);
    on<QuizOpenRequested>(_onOpen);
    on<QuizAttemptSaveRequested>(_onAttemptSave);
  }

  Future<void> _onLoadList(QuizListLoadRequested e, Emitter emit) async {
    emit(state.copyWith(loading: true, clearError: true));
    final r = await _getQuizzes(e.subjectId);
    r.fold(
      (f) => emit(state.copyWith(loading: false, error: f.message)),
      (list) => emit(state.copyWith(loading: false, quizzes: list)),
    );
  }

  Future<void> _onGenerate(QuizGenerateRequested e, Emitter emit) async {
    emit(state.copyWith(generating: true, clearError: true));
    final r = await _generate(
      subjectId: e.subjectId,
      title: e.title,
      questionCount: e.questionCount,
    );
    r.fold(
      (f) => emit(state.copyWith(generating: false, error: f.message)),
      (quiz) => emit(state.copyWith(
        generating: false,
        quizzes: [quiz, ...state.quizzes],
        activeQuiz: quiz,
      )),
    );
  }

  Future<void> _onDelete(QuizDeleteRequested e, Emitter emit) async {
    final r = await _delete(e.id);
    r.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (_) => emit(state.copyWith(
        quizzes: state.quizzes.where((q) => q.id != e.id).toList(),
        clearActive: state.activeQuiz?.id == e.id,
      )),
    );
  }

  Future<void> _onOpen(QuizOpenRequested e, Emitter emit) async {
    emit(state.copyWith(loading: true, clearError: true));
    final r = await _getById(e.id);
    r.fold(
      (f) => emit(state.copyWith(loading: false, error: f.message)),
      (quiz) => emit(state.copyWith(loading: false, activeQuiz: quiz)),
    );
  }

  Future<void> _onAttemptSave(
      QuizAttemptSaveRequested e, Emitter emit) async {
    await _saveAttempt(
      quizId: e.quizId,
      subjectId: e.subjectId,
      score: e.score,
      totalQuestions: e.totalQuestions,
    );
  }
}
