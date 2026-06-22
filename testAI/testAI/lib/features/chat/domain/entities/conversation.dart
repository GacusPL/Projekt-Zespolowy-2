import 'package:equatable/equatable.dart';

enum MessageRole { user, assistant }

extension MessageRoleX on MessageRole {
  String get dbValue => name;
  static MessageRole fromDb(String v) =>
      MessageRole.values.firstWhere((r) => r.name == v);
}

/// Źródło (zacytowany fragment) użyte w odpowiedzi: nazwa pliku + treść fragmentu.
/// `snippet` bywa pusty dla starszych wiadomości (przed dodaniem podglądu).
class MessageSource extends Equatable {
  final String filename;
  final String snippet;
  const MessageSource({required this.filename, this.snippet = ''});

  @override
  List<Object?> get props => [filename, snippet];
}

/// Pojedyncza wiadomość w konwersacji.
/// `sources` zawiera fragmenty (plik + treść), z których model korzystał.
class Message extends Equatable {
  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final List<MessageSource> sources;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.sources = const [],
    required this.createdAt,
  });

  Message copyWith({
    String? content,
    List<MessageSource>? sources,
  }) =>
      Message(
        id: id,
        conversationId: conversationId,
        role: role,
        content: content ?? this.content,
        sources: sources ?? this.sources,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props =>
      [id, conversationId, role, content, sources, createdAt];
}

/// Konwersacja należąca do przedmiotu.
class Conversation extends Equatable {
  final String id;
  final String subjectId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  Conversation copyWith({String? title, DateTime? updatedAt}) => Conversation(
        id: id,
        subjectId: subjectId,
        title: title ?? this.title,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [id, subjectId, title, createdAt, updatedAt];
}
