import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lekturai/features/chat/data/models/chat_models.dart';
import 'package:lekturai/features/chat/domain/entities/conversation.dart';

void main() {
  group('MessageModel — serializacja źródeł', () {
    test('round-trip zachowuje plik i snippet', () {
      final m = MessageModel(
        id: '1',
        conversationId: 'c',
        role: MessageRole.assistant,
        content: 'odp',
        sources: const [
          MessageSource(filename: 'a.pdf', snippet: 'fragment A'),
          MessageSource(filename: 'a.pdf', snippet: 'fragment B'),
        ],
        createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
      );
      final back = MessageModel.fromMap(m.toMap());
      expect(back.sources.length, 2);
      expect(back.sources.first.filename, 'a.pdf');
      expect(back.sources.first.snippet, 'fragment A');
      expect(back.content, 'odp');
      expect(back.role, MessageRole.assistant);
    });

    test('stary format (lista nazw plików) → MessageSource bez snippetu', () {
      final row = <String, dynamic>{
        'id': '1',
        'conversation_id': 'c',
        'role': 'assistant',
        'content': 'x',
        'sources': jsonEncode(['a.pdf', 'b.pdf']),
        'created_at': 0,
      };
      final m = MessageModel.fromMap(row);
      expect(m.sources.map((s) => s.filename).toList(), ['a.pdf', 'b.pdf']);
      expect(m.sources.every((s) => s.snippet.isEmpty), isTrue);
    });

    test('brak źródeł → pusta lista', () {
      final row = <String, dynamic>{
        'id': '1',
        'conversation_id': 'c',
        'role': 'user',
        'content': 'x',
        'sources': null,
        'created_at': 0,
      };
      expect(MessageModel.fromMap(row).sources, isEmpty);
    });
  });
}
