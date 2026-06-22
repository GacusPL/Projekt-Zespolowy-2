import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../documents/domain/entities/document_chunk.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/chat_usecases.dart';

// =============================================================== EVENTS
sealed class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class ChatConversationsLoadRequested extends ChatEvent {
  final String subjectId;
  const ChatConversationsLoadRequested(this.subjectId);
  @override
  List<Object?> get props => [subjectId];
}

class ChatConversationOpened extends ChatEvent {
  final Conversation conversation;
  const ChatConversationOpened(this.conversation);
  @override
  List<Object?> get props => [conversation];
}

class ChatConversationCreated extends ChatEvent {
  final String subjectId;
  final String title;
  const ChatConversationCreated({required this.subjectId, required this.title});
  @override
  List<Object?> get props => [subjectId, title];
}

class ChatConversationDeleted extends ChatEvent {
  final String id;
  const ChatConversationDeleted(this.id);
  @override
  List<Object?> get props => [id];
}

class ChatMessageSent extends ChatEvent {
  final String text;
  const ChatMessageSent(this.text);
  @override
  List<Object?> get props => [text];
}

/// Żądanie zatrzymania trwającego streamu (przycisk stop w UI).
class ChatStreamStopRequested extends ChatEvent {
  const ChatStreamStopRequested();
}

class _ChatTokenReceived extends ChatEvent {
  final String token;
  const _ChatTokenReceived(this.token);
  @override
  List<Object?> get props => [token];
}

class _ChatSourcesReceived extends ChatEvent {
  final List<DocumentChunk> sources;
  const _ChatSourcesReceived(this.sources);
  @override
  List<Object?> get props => [sources];
}

class _ChatStreamCompleted extends ChatEvent {
  const _ChatStreamCompleted();
}

class _ChatStreamFailed extends ChatEvent {
  final String error;
  const _ChatStreamFailed(this.error);
  @override
  List<Object?> get props => [error];
}

// =============================================================== STATE
class ChatState extends Equatable {
  final bool loadingConversations;
  final List<Conversation> conversations;
  final Conversation? activeConversation;
  final List<Message> messages;
  final bool streaming;
  final List<DocumentChunk> lastSources;
  final String? error;

  const ChatState({
    this.loadingConversations = false,
    this.conversations = const [],
    this.activeConversation,
    this.messages = const [],
    this.streaming = false,
    this.lastSources = const [],
    this.error,
  });

  ChatState copyWith({
    bool? loadingConversations,
    List<Conversation>? conversations,
    Conversation? activeConversation,
    bool clearActive = false,
    List<Message>? messages,
    bool? streaming,
    List<DocumentChunk>? lastSources,
    String? error,
    bool clearError = false,
  }) =>
      ChatState(
        loadingConversations:
            loadingConversations ?? this.loadingConversations,
        conversations: conversations ?? this.conversations,
        activeConversation:
            clearActive ? null : (activeConversation ?? this.activeConversation),
        messages: messages ?? this.messages,
        streaming: streaming ?? this.streaming,
        lastSources: lastSources ?? this.lastSources,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [
        loadingConversations,
        conversations,
        activeConversation,
        messages,
        streaming,
        lastSources,
        error,
      ];
}

// =============================================================== BLOC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetConversationsUseCase _getConvs;
  final CreateConversationUseCase _createConv;
  final DeleteConversationUseCase _deleteConv;
  final GetMessagesUseCase _getMessages;
  final SaveMessageUseCase _saveMessage;
  final StreamRagAnswerUseCase _streamRag;
  final Uuid _uuid;

  StreamSubscription<StreamedAnswer>? _sub;

  ChatBloc({
    required GetConversationsUseCase getConversations,
    required CreateConversationUseCase createConversation,
    required DeleteConversationUseCase deleteConversation,
    required GetMessagesUseCase getMessages,
    required SaveMessageUseCase saveMessage,
    required StreamRagAnswerUseCase streamRagAnswer,
    Uuid? uuid,
  })  : _getConvs = getConversations,
        _createConv = createConversation,
        _deleteConv = deleteConversation,
        _getMessages = getMessages,
        _saveMessage = saveMessage,
        _streamRag = streamRagAnswer,
        _uuid = uuid ?? const Uuid(),
        super(const ChatState()) {
    on<ChatConversationsLoadRequested>(_onLoadConvs);
    on<ChatConversationOpened>(_onOpenConv);
    on<ChatConversationCreated>(_onCreateConv);
    on<ChatConversationDeleted>(_onDeleteConv);
    on<ChatMessageSent>(_onSendMessage);
    on<ChatStreamStopRequested>(_onStopStream);
    on<_ChatTokenReceived>(_onToken);
    on<_ChatSourcesReceived>(_onSources);
    on<_ChatStreamCompleted>(_onStreamDone);
    on<_ChatStreamFailed>(_onStreamFailed);
  }

  Future<void> _onLoadConvs(
      ChatConversationsLoadRequested e, Emitter emit) async {
    emit(state.copyWith(loadingConversations: true, clearError: true));
    final r = await _getConvs(e.subjectId);
    r.fold(
      (f) => emit(state.copyWith(
        loadingConversations: false,
        error: f.message,
      )),
      (list) => emit(state.copyWith(
        loadingConversations: false,
        conversations: list,
      )),
    );
  }

  Future<void> _onOpenConv(ChatConversationOpened e, Emitter emit) async {
    emit(state.copyWith(
      activeConversation: e.conversation,
      messages: const [],
      lastSources: const [],
      clearError: true,
    ));
    final r = await _getMessages(e.conversation.id);
    r.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (list) => emit(state.copyWith(messages: list)),
    );
  }

  Future<void> _onCreateConv(
      ChatConversationCreated e, Emitter emit) async {
    final r = await _createConv(subjectId: e.subjectId, title: e.title);
    r.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (c) {
        emit(state.copyWith(
          conversations: [c, ...state.conversations],
          activeConversation: c,
          messages: const [],
          lastSources: const [],
        ));
      },
    );
  }

  Future<void> _onDeleteConv(
      ChatConversationDeleted e, Emitter emit) async {
    final r = await _deleteConv(e.id);
    r.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (_) {
        final updated =
            state.conversations.where((c) => c.id != e.id).toList();
        emit(state.copyWith(
          conversations: updated,
          clearActive: state.activeConversation?.id == e.id,
          messages: state.activeConversation?.id == e.id
              ? const []
              : state.messages,
        ));
      },
    );
  }

  Future<void> _onSendMessage(ChatMessageSent e, Emitter emit) async {
    final conv = state.activeConversation;
    if (conv == null || e.text.trim().isEmpty || state.streaming) return;

    // 1. Zapis wiadomości użytkownika
    final userMsg = Message(
      id: _uuid.v4(),
      conversationId: conv.id,
      role: MessageRole.user,
      content: e.text.trim(),
      createdAt: DateTime.now(),
    );
    await _saveMessage(userMsg);

    // 2. Twórczy placeholder dla wiadomości asystenta (pusty content)
    final assistantId = _uuid.v4();
    final assistantPlaceholder = Message(
      id: assistantId,
      conversationId: conv.id,
      role: MessageRole.assistant,
      content: '',
      createdAt: DateTime.now(),
    );

    emit(state.copyWith(
      messages: [...state.messages, userMsg, assistantPlaceholder],
      streaming: true,
      lastSources: const [],
      clearError: true,
    ));

    // 3. Start streamu
    await _sub?.cancel();
    final stream = _streamRag(
      subjectId: conv.subjectId,
      userMessage: e.text.trim(),
      history: state.messages,
    );
    _sub = stream.listen(
      (event) {
        if (event.sources != null) {
          add(_ChatSourcesReceived(event.sources!));
        }
        if (event.deltaText != null) {
          add(_ChatTokenReceived(event.deltaText!));
        }
        if (event.done) {
          add(const _ChatStreamCompleted());
        }
      },
      onError: (err) => add(_ChatStreamFailed(err.toString())),
      onDone: () => add(const _ChatStreamCompleted()),
    );
  }

  void _onToken(_ChatTokenReceived e, Emitter emit) {
    if (state.messages.isEmpty) return;
    final last = state.messages.last;
    if (last.role != MessageRole.assistant) return;
    final updated = last.copyWith(content: last.content + e.token);
    final newList = [...state.messages]..[state.messages.length - 1] = updated;
    emit(state.copyWith(messages: newList));
  }

  void _onSources(_ChatSourcesReceived e, Emitter emit) {
    emit(state.copyWith(lastSources: e.sources));
    // dopisujemy źródła do ostatniej wiadomości asystenta
    if (state.messages.isNotEmpty &&
        state.messages.last.role == MessageRole.assistant) {
      final last = state.messages.last;
      final sources = e.sources
          .map((c) => c.documentFilename ?? '')
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();
      final updated = last.copyWith(sources: sources);
      final newList = [...state.messages]
        ..[state.messages.length - 1] = updated;
      emit(state.copyWith(messages: newList));
    }
  }

  Future<void> _onStreamDone(_ChatStreamCompleted e, Emitter emit) async {
    await _persistPartialAssistant();
    emit(state.copyWith(streaming: false));
  }

  /// Zatrzymuje trwający stream na żądanie użytkownika (przycisk stop) i zapisuje
  /// to, co model zdążył wygenerować, żeby częściowa odpowiedź nie przepadła.
  Future<void> _onStopStream(ChatStreamStopRequested e, Emitter emit) async {
    if (!state.streaming) return;
    await _sub?.cancel();
    _sub = null;
    await _persistPartialAssistant();
    emit(state.copyWith(streaming: false));
  }

  void _onStreamFailed(_ChatStreamFailed e, Emitter emit) {
    emit(state.copyWith(streaming: false, error: e.error));
  }

  /// Zapisuje ostatnią wiadomość asystenta, jeśli ma już jakąkolwiek treść.
  /// Idempotentne (insert z ConflictAlgorithm.replace) — bezpieczne przy
  /// zakończeniu, zatrzymaniu i zamknięciu blocu.
  Future<void> _persistPartialAssistant() async {
    if (state.messages.isNotEmpty &&
        state.messages.last.role == MessageRole.assistant &&
        state.messages.last.content.isNotEmpty) {
      await _saveMessage(state.messages.last);
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    // Wyjście z ekranu/przedmiotu w trakcie streamu — nie trać częściowej
    // odpowiedzi (UI zostało zamknięte, ale to, co już spłynęło, zapisujemy).
    if (state.streaming) {
      await _persistPartialAssistant();
    }
    return super.close();
  }
}
