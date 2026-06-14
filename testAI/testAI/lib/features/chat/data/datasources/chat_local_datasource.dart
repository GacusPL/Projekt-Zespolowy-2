import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../shared/database/database_helper.dart';
import '../../domain/entities/conversation.dart';
import '../models/chat_models.dart';

abstract class ChatLocalDataSource {
  Future<List<ConversationModel>> getConversations(String subjectId);
  Future<ConversationModel> createConversation({
    required String subjectId,
    required String title,
  });
  Future<void> deleteConversation(String id);
  Future<void> touchConversation(String id);

  Future<List<MessageModel>> getMessages(String conversationId);
  Future<MessageModel> insertMessage(MessageModel message);
}

class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  final DatabaseHelper _db;
  final Uuid _uuid;
  ChatLocalDataSourceImpl({required DatabaseHelper dbHelper, Uuid? uuid})
      : _db = dbHelper,
        _uuid = uuid ?? const Uuid();

  @override
  Future<List<ConversationModel>> getConversations(String subjectId) async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        'conversations',
        where: 'subject_id = ?',
        whereArgs: [subjectId],
        orderBy: 'updated_at DESC',
      );
      return rows.map(ConversationModel.fromMap).toList();
    } catch (e) {
      throw DatabaseException('Błąd odczytu konwersacji: $e');
    }
  }

  @override
  Future<ConversationModel> createConversation({
    required String subjectId,
    required String title,
  }) async {
    try {
      final db = await _db.database;
      final now = DateTime.now();
      final c = ConversationModel(
        id: _uuid.v4(),
        subjectId: subjectId,
        title: title,
        createdAt: now,
        updatedAt: now,
      );
      await db.insert('conversations', c.toMap());
      return c;
    } catch (e) {
      throw DatabaseException('Nie udało się utworzyć konwersacji: $e');
    }
  }

  @override
  Future<void> deleteConversation(String id) async {
    try {
      final db = await _db.database;
      await db.delete('conversations', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw DatabaseException('Nie udało się usunąć konwersacji: $e');
    }
  }

  @override
  Future<void> touchConversation(String id) async {
    try {
      final db = await _db.database;
      await db.update(
        'conversations',
        {'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (_) {
      // niekrytyczne — pomijamy
    }
  }

  @override
  Future<List<MessageModel>> getMessages(String conversationId) async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        'messages',
        where: 'conversation_id = ?',
        whereArgs: [conversationId],
        orderBy: 'created_at ASC',
      );
      return rows.map(MessageModel.fromMap).toList();
    } catch (e) {
      throw DatabaseException('Błąd odczytu wiadomości: $e');
    }
  }

  @override
  Future<MessageModel> insertMessage(MessageModel message) async {
    try {
      final db = await _db.database;
      await db.insert('messages', message.toMap());
      await touchConversation(message.conversationId);
      return message;
    } catch (e) {
      throw DatabaseException('Nie udało się zapisać wiadomości: $e');
    }
  }
}
