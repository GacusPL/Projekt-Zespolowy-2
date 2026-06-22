import 'dart:convert';

import '../../domain/entities/conversation.dart';

class ConversationModel extends Conversation {
  const ConversationModel({
    required super.id,
    required super.subjectId,
    required super.title,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ConversationModel.fromMap(Map<String, dynamic> m) =>
      ConversationModel(
        id: m['id'] as String,
        subjectId: m['subject_id'] as String,
        title: m['title'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'subject_id': subjectId,
        'title': title,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };
}

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.conversationId,
    required super.role,
    required super.content,
    super.sources,
    required super.createdAt,
  });

  factory MessageModel.fromMap(Map<String, dynamic> m) {
    return MessageModel(
      id: m['id'] as String,
      conversationId: m['conversation_id'] as String,
      role: MessageRoleX.fromDb(m['role'] as String),
      content: m['content'] as String,
      sources: _decodeSources(m['sources'] as String?),
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
    );
  }

  /// Parsowanie źródeł z JSON. Wstecznie kompatybilne: stary format to lista
  /// nazw plików (`["a.pdf"]`), nowy to lista obiektów (`[{file, snippet}]`).
  static List<MessageSource> _decodeSources(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List;
    return decoded.map<MessageSource>((e) {
      if (e is String) return MessageSource(filename: e);
      final map = e as Map<String, dynamic>;
      return MessageSource(
        filename: (map['file'] ?? '') as String,
        snippet: (map['snippet'] ?? '') as String,
      );
    }).toList();
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'conversation_id': conversationId,
        'role': role.dbValue,
        'content': content,
        'sources': jsonEncode(
          sources
              .map((s) => {'file': s.filename, 'snippet': s.snippet})
              .toList(),
        ),
        'created_at': createdAt.millisecondsSinceEpoch,
      };
}
