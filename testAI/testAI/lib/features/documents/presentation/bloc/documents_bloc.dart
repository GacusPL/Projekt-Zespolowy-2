import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/document.dart';
import '../../domain/usecases/document_usecases.dart';

// ============================================================== EVENTS
sealed class DocumentsEvent extends Equatable {
  const DocumentsEvent();
  @override
  List<Object?> get props => [];
}

class DocumentsLoadRequested extends DocumentsEvent {
  final String subjectId;
  const DocumentsLoadRequested(this.subjectId);
  @override
  List<Object?> get props => [subjectId];
}

class DocumentsUploadRequested extends DocumentsEvent {
  final String subjectId;
  final String filename;
  final DocumentType type;
  final Uint8List bytes;
  const DocumentsUploadRequested({
    required this.subjectId,
    required this.filename,
    required this.type,
    required this.bytes,
  });
  @override
  List<Object?> get props => [subjectId, filename, type, bytes.length];
}

class DocumentsDeleteRequested extends DocumentsEvent {
  final String documentId;
  const DocumentsDeleteRequested(this.documentId);
  @override
  List<Object?> get props => [documentId];
}

class _DocumentsUploadProgress extends DocumentsEvent {
  final double progress;
  final String stage;
  const _DocumentsUploadProgress(this.progress, this.stage);
  @override
  List<Object?> get props => [progress, stage];
}

// ============================================================== STATE
class DocumentsState extends Equatable {
  final bool loading;
  final List<Document> documents;
  final bool uploading;
  final double uploadProgress;
  final String? uploadStage;
  final String? error;

  const DocumentsState({
    this.loading = false,
    this.documents = const [],
    this.uploading = false,
    this.uploadProgress = 0,
    this.uploadStage,
    this.error,
  });

  DocumentsState copyWith({
    bool? loading,
    List<Document>? documents,
    bool? uploading,
    double? uploadProgress,
    String? uploadStage,
    String? error,
    bool clearError = false,
    bool clearUpload = false,
  }) =>
      DocumentsState(
        loading: loading ?? this.loading,
        documents: documents ?? this.documents,
        uploading: clearUpload ? false : (uploading ?? this.uploading),
        uploadProgress: clearUpload ? 0 : (uploadProgress ?? this.uploadProgress),
        uploadStage: clearUpload ? null : (uploadStage ?? this.uploadStage),
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props =>
      [loading, documents, uploading, uploadProgress, uploadStage, error];
}

// ============================================================== BLOC
class DocumentsBloc extends Bloc<DocumentsEvent, DocumentsState> {
  final GetDocumentsUseCase _getDocs;
  final UploadDocumentUseCase _upload;
  final DeleteDocumentUseCase _delete;

  DocumentsBloc({
    required GetDocumentsUseCase getDocuments,
    required UploadDocumentUseCase uploadDocument,
    required DeleteDocumentUseCase deleteDocument,
  })  : _getDocs = getDocuments,
        _upload = uploadDocument,
        _delete = deleteDocument,
        super(const DocumentsState()) {
    on<DocumentsLoadRequested>(_onLoad);
    on<DocumentsUploadRequested>(_onUpload);
    on<DocumentsDeleteRequested>(_onDelete);
    on<_DocumentsUploadProgress>(_onProgress);
  }

  Future<void> _onLoad(DocumentsLoadRequested e, Emitter emit) async {
    emit(state.copyWith(loading: true, clearError: true));
    final r = await _getDocs(e.subjectId);
    r.fold(
      (f) => emit(state.copyWith(loading: false, error: f.message)),
      (list) => emit(state.copyWith(loading: false, documents: list)),
    );
  }

  Future<void> _onUpload(DocumentsUploadRequested e, Emitter emit) async {
    emit(state.copyWith(
      uploading: true,
      uploadProgress: 0,
      uploadStage: 'Start…',
      clearError: true,
    ));
    final r = await _upload(
      subjectId: e.subjectId,
      filename: e.filename,
      type: e.type,
      bytes: e.bytes,
      onProgress: (p, s) => add(_DocumentsUploadProgress(p, s)),
    );
    r.fold(
      (f) => emit(state.copyWith(
        clearUpload: true,
        error: f.message,
      )),
      (doc) => emit(state.copyWith(
        clearUpload: true,
        documents: [doc, ...state.documents],
      )),
    );
  }

  void _onProgress(_DocumentsUploadProgress e, Emitter emit) {
    // Zdarzenia postępu i zakończenie uploadu są obsługiwane współbieżnie —
    // ostatni callback ('Gotowe!') może dotrzeć już po wyczyszczeniu stanu.
    // Bez tego guardu „ożywiłby" pasek na stałe (100%, nie znika).
    if (!state.uploading) return;
    emit(state.copyWith(
      uploadProgress: e.progress,
      uploadStage: e.stage,
    ));
  }

  Future<void> _onDelete(DocumentsDeleteRequested e, Emitter emit) async {
    final r = await _delete(e.documentId);
    r.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (_) => emit(state.copyWith(
        documents:
            state.documents.where((d) => d.id != e.documentId).toList(),
      )),
    );
  }
}
