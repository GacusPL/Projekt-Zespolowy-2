import 'package:equatable/equatable.dart';

enum DocumentType { pdf, image, text }

extension DocumentTypeX on DocumentType {
  String get label => switch (this) {
        DocumentType.pdf => 'PDF',
        DocumentType.image => 'Zdjęcie',
        DocumentType.text => 'Tekst',
      };
  String get dbValue => name; // 'pdf' | 'image' | 'text'
  static DocumentType fromDb(String v) =>
      DocumentType.values.firstWhere((t) => t.name == v);
}

class Document extends Equatable {
  final String id;
  final String subjectId;
  final String filename;
  final DocumentType fileType;
  final int chunkCount;
  final DateTime uploadedAt;

  const Document({
    required this.id,
    required this.subjectId,
    required this.filename,
    required this.fileType,
    required this.chunkCount,
    required this.uploadedAt,
  });

  @override
  List<Object?> get props =>
      [id, subjectId, filename, fileType, chunkCount, uploadedAt];
}
