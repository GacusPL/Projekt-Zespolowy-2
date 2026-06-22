import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/conversation.dart';
import '../repositories/chat_repository.dart';

class GetConversationsUseCase {
  final ChatRepository repo;
  GetConversationsUseCase(this.repo);
  Future<Either<Failure, List<Conversation>>> call(String subjectId) =>
      repo.getConversations(subjectId);
}

class CreateConversationUseCase {
  final ChatRepository repo;
  CreateConversationUseCase(this.repo);
  Future<Either<Failure, Conversation>> call({
    required String subjectId,
    required String title,
  }) =>
      repo.createConversation(subjectId: subjectId, title: title);
}

class DeleteConversationUseCase {
  final ChatRepository repo;
  DeleteConversationUseCase(this.repo);
  Future<Either<Failure, Unit>> call(String id) => repo.deleteConversation(id);
}

class GetMessagesUseCase {
  final ChatRepository repo;
  GetMessagesUseCase(this.repo);
  Future<Either<Failure, List<Message>>> call(String conversationId) =>
      repo.getMessages(conversationId);
}

class SaveMessageUseCase {
  final ChatRepository repo;
  SaveMessageUseCase(this.repo);
  Future<Either<Failure, Message>> call(Message m) => repo.saveMessage(m);
}

class StreamRagAnswerUseCase {
  final ChatRepository repo;
  StreamRagAnswerUseCase(this.repo);
  Stream<StreamedAnswer> call({
    required String subjectId,
    required String userMessage,
    required List<Message> history,
  }) =>
      repo.streamRagAnswer(
        subjectId: subjectId,
        userMessage: userMessage,
        history: history,
      );
}
