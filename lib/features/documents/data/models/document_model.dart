import '../../domain/entities/document.dart';

class DocumentModel extends Document {
  const DocumentModel({
    required super.id,
    required super.subjectId,
    required super.filename,
    required super.fileType,
    required super.chunkCount,
    required super.uploadedAt,
  });

  factory DocumentModel.fromMap(Map<String, dynamic> m) => DocumentModel(
        id: m['id'] as String,
        subjectId: m['subject_id'] as String,
        filename: m['filename'] as String,
        fileType: DocumentTypeX.fromDb(m['file_type'] as String),
        chunkCount: m['chunk_count'] as int? ?? 0,
        uploadedAt: DateTime.fromMillisecondsSinceEpoch(
          m['uploaded_at'] as int,
        ),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'subject_id': subjectId,
        'filename': filename,
        'file_type': fileType.dbValue,
        'chunk_count': chunkCount,
        'uploaded_at': uploadedAt.millisecondsSinceEpoch,
      };
}
