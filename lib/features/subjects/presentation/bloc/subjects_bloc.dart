import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/subject.dart';
import '../../domain/usecases/subject_usecases.dart';

// ============================================================== EVENTS
sealed class SubjectsEvent extends Equatable {
  const SubjectsEvent();
  @override
  List<Object?> get props => [];
}

class SubjectsLoadRequested extends SubjectsEvent {
  const SubjectsLoadRequested();
}

class SubjectsCreateRequested extends SubjectsEvent {
  final String name;
  final String? description;
  final int colorValue;
  const SubjectsCreateRequested({
    required this.name,
    this.description,
    required this.colorValue,
  });
  @override
  List<Object?> get props => [name, description, colorValue];
}

class SubjectsDeleteRequested extends SubjectsEvent {
  final String id;
  const SubjectsDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

// ============================================================== STATE
class SubjectsState extends Equatable {
  final bool loading;
  final List<Subject> subjects;
  final String? error;

  const SubjectsState({
    this.loading = false,
    this.subjects = const [],
    this.error,
  });

  SubjectsState copyWith({
    bool? loading,
    List<Subject>? subjects,
    String? error,
    bool clearError = false,
  }) =>
      SubjectsState(
        loading: loading ?? this.loading,
        subjects: subjects ?? this.subjects,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [loading, subjects, error];
}

// ============================================================== BLOC
class SubjectsBloc extends Bloc<SubjectsEvent, SubjectsState> {
  final GetSubjectsUseCase _get;
  final CreateSubjectUseCase _create;
  final DeleteSubjectUseCase _delete;

  SubjectsBloc({
    required GetSubjectsUseCase getSubjects,
    required CreateSubjectUseCase createSubject,
    required DeleteSubjectUseCase deleteSubject,
  })  : _get = getSubjects,
        _create = createSubject,
        _delete = deleteSubject,
        super(const SubjectsState()) {
    on<SubjectsLoadRequested>(_onLoad);
    on<SubjectsCreateRequested>(_onCreate);
    on<SubjectsDeleteRequested>(_onDelete);
  }

  Future<void> _onLoad(SubjectsLoadRequested e, Emitter emit) async {
    emit(state.copyWith(loading: true, clearError: true));
    final r = await _get();
    r.fold(
      (f) => emit(state.copyWith(loading: false, error: f.message)),
      (list) => emit(state.copyWith(loading: false, subjects: list)),
    );
  }

  Future<void> _onCreate(SubjectsCreateRequested e, Emitter emit) async {
    final r = await _create(
      name: e.name,
      description: e.description,
      colorValue: e.colorValue,
    );
    r.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (subj) => emit(
        state.copyWith(
          subjects: [subj, ...state.subjects],
          clearError: true,
        ),
      ),
    );
  }

  Future<void> _onDelete(SubjectsDeleteRequested e, Emitter emit) async {
    final r = await _delete(e.id);
    r.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (_) => emit(
        state.copyWith(
          subjects: state.subjects.where((s) => s.id != e.id).toList(),
          clearError: true,
        ),
      ),
    );
  }
}
