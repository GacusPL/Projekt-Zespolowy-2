import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../documents/domain/entities/document_chunk.dart';
import '../entities/conversation.dart';

/// Wynik streamowania odpowiedzi: pojedynczy token + (na końcu) lista źródeł.
class StreamedAnswer {
  /// Inkrementalny tekst odpowiedzi (każde emit dokleja kolejny fragment).
  final String? deltaText;

  /// Lista chunków, które zostały użyte jako kontekst (emitowana raz, na początku).
  final List<DocumentChunk>? sources;

  /// Flaga "zakończono" — informuje BLoC, że stream się skończył.
  final bool done;

  StreamedAnswer({this.deltaText, this.sources, this.done = false});
}

abstract class ChatRepository {
  // konwersacje
  Future<Either<Failure, List<Conversation>>> getConversations(String subjectId);
  Future<Either<Failure, Conversation>> createConversation({
    required String subjectId,
    required String title,
  });
  Future<Either<Failure, Unit>> deleteConversation(String id);

  // wiadomości
  Future<Either<Failure, List<Message>>> getMessages(String conversationId);
  Future<Either<Failure, Message>> saveMessage(Message message);

  /// Streamuje odpowiedź RAG token-po-tokenie.
  ///
  /// Emituje [StreamedAnswer.sources] jako pierwszy event (z chunkami użytymi
  /// jako kontekst), potem szereg deltaText, na końcu done=true.
  Stream<StreamedAnswer> streamRagAnswer({
    required String subjectId,
    required String userMessage,
    required List<Message> history,
  });
}
