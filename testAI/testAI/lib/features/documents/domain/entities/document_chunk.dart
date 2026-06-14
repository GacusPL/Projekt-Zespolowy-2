import 'package:equatable/equatable.dart';

/// Fragment dokumentu używany w RAG-u.
/// `similarity` jest wypełnione tylko podczas wyszukiwania.
class DocumentChunk extends Equatable {
  final String id;
  final String documentId;
  final String subjectId;
  final int chunkIndex;
  final String content;
  final double? similarity;
  final String? documentFilename;

  const DocumentChunk({
    required this.id,
    required this.documentId,
    required this.subjectId,
    required this.chunkIndex,
    required this.content,
    this.similarity,
    this.documentFilename,
  });

  @override
  List<Object?> get props =>
      [id, documentId, subjectId, chunkIndex, content, similarity];
}
