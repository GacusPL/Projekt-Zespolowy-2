import '../../domain/entities/document_chunk.dart';

class DocumentChunkModel extends DocumentChunk {
  const DocumentChunkModel({
    required super.id,
    required super.documentId,
    required super.subjectId,
    required super.chunkIndex,
    required super.content,
    super.similarity,
    super.documentFilename,
  });

  factory DocumentChunkModel.fromMap(
    Map<String, dynamic> m, {
    double? similarity,
  }) =>
      DocumentChunkModel(
        id: m['id'] as String,
        documentId: m['document_id'] as String,
        subjectId: m['subject_id'] as String,
        chunkIndex: m['chunk_index'] as int,
        content: m['content'] as String,
        similarity: similarity,
        documentFilename: m['doc_filename'] as String?,
      );
}
