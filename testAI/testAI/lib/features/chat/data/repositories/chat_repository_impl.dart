import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/ollama_client.dart';
import '../../../documents/domain/repositories/documents_repository.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_local_datasource.dart';
import '../datasources/prompt_builder.dart';
import '../models/chat_models.dart';

/// Implementacja repozytorium czatu. Orkiestruje:
/// 1. wyszukiwanie kontekstu (DocumentsRepository.searchRelevant),
/// 2. budowanie promptu (PromptBuilder),
/// 3. streaming odpowiedzi z Ollama (OllamaClient.generateStream).
class ChatRepositoryImpl implements ChatRepository {
  final ChatLocalDataSource _local;
  final DocumentsRepository _docs;
  final OllamaClient _ollama;

  ChatRepositoryImpl({
    required ChatLocalDataSource local,
    required DocumentsRepository documentsRepository,
    required OllamaClient ollamaClient,
  })  : _local = local,
        _docs = documentsRepository,
        _ollama = ollamaClient;

  // ---- konwersacje ------------------------------------------------------

  @override
  Future<Either<Failure, List<Conversation>>> getConversations(
    String subjectId,
  ) async {
    try {
      final list = await _local.getConversations(subjectId);
      return Right(list);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Conversation>> createConversation({
    required String subjectId,
    required String title,
  }) async {
    try {
      final c = await _local.createConversation(
        subjectId: subjectId,
        title: title,
      );
      return Right(c);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteConversation(String id) async {
    try {
      await _local.deleteConversation(id);
      return const Right(unit);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  // ---- wiadomości -------------------------------------------------------

  @override
  Future<Either<Failure, List<Message>>> getMessages(String convId) async {
    try {
      final list = await _local.getMessages(convId);
      return Right(list);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Message>> saveMessage(Message m) async {
    try {
      final mm = MessageModel(
        id: m.id,
        conversationId: m.conversationId,
        role: m.role,
        content: m.content,
        sources: m.sources,
        createdAt: m.createdAt,
      );
      final saved = await _local.insertMessage(mm);
      return Right(saved);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  // ---- streamowany RAG --------------------------------------------------

  @override
  Stream<StreamedAnswer> streamRagAnswer({
    required String subjectId,
    required String userMessage,
    required List<Message> history,
  }) async* {
    // 1. Retrieval: znajdź pasujące chunki
    final retrieval = await _docs.searchRelevant(
      subjectId: subjectId,
      query: userMessage,
    );

    final chunks = retrieval.fold(
      (failure) => null,
      (list) => list,
    );

    // Jeśli sam retrieval padł (np. Ollama down), pcham to do upstream:
    if (chunks == null) {
      throw OllamaException(
        retrieval.swap().getOrElse(() => const OllamaFailure('Błąd RAG'))
            .message,
      );
    }

    // Emit pierwszy event ze źródłami (UI może je już pokazać podczas streamu)
    yield StreamedAnswer(sources: chunks);

    // 2. Budowa promptu
    final prompt = PromptBuilder.buildRagUserPrompt(
      userMessage: userMessage,
      chunks: chunks,
      history: history,
    );

    // 3. Streaming generacji
    final stream = _ollama.generateStream(
      prompt: prompt,
      system: PromptBuilder.ragSystemPrompt,
      temperature: 0.3,
    );

    await for (final piece in stream) {
      yield StreamedAnswer(deltaText: piece);
    }

    yield StreamedAnswer(done: true);
  }
}
