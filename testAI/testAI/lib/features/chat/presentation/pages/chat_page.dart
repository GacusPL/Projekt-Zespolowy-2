import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/entities/conversation.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/chat_input.dart';
import '../widgets/conversation_list.dart';
import '../widgets/message_bubble.dart';

class ChatPage extends StatelessWidget {
  final String subjectId;
  final String subjectName;
  const ChatPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatBloc>(
      create: (_) =>
          sl<ChatBloc>()..add(ChatConversationsLoadRequested(subjectId)),
      child: _ChatView(subjectId: subjectId, subjectName: subjectName),
    );
  }
}

class _ChatView extends StatelessWidget {
  final String subjectId;
  final String subjectName;
  const _ChatView({required this.subjectId, required this.subjectName});

  void _newConversation(BuildContext context) {
    final now = DateTime.now();
    final title =
        'Rozmowa ${now.day}.${now.month} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    context
        .read<ChatBloc>()
        .add(ChatConversationCreated(subjectId: subjectId, title: title));
  }

  Future<void> _confirmDelete(BuildContext context, Conversation c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usunąć rozmowę?'),
        content: Text('Czy usunąć "${c.title}"? Tej operacji nie można cofnąć.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<ChatBloc>().add(ChatConversationDeleted(c.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      builder: (context, state) {
        final isWide = MediaQuery.of(context).size.width > 700;
        if (isWide) {
          return Row(
            children: [
              SizedBox(
                width: 280,
                child: ConversationList(
                  conversations: state.conversations,
                  active: state.activeConversation,
                  loading: state.loadingConversations,
                  onOpen: (c) =>
                      context.read<ChatBloc>().add(ChatConversationOpened(c)),
                  onDelete: (c) => _confirmDelete(context, c),
                  onNew: () => _newConversation(context),
                ),
              ),
              Expanded(child: _MessagesArea(state: state)),
            ],
          );
        }

        // Wąski ekran — sidebar w Drawerze
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 44,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.history),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                    tooltip: 'Historia rozmów',
                  ),
                ),
                Expanded(
                  child: Text(
                    state.activeConversation?.title ?? 'Nowa rozmowa',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          drawer: Drawer(
            child: ConversationList(
              conversations: state.conversations,
              active: state.activeConversation,
              loading: state.loadingConversations,
              onOpen: (c) {
                context.read<ChatBloc>().add(ChatConversationOpened(c));
                Navigator.of(context).pop();
              },
              onDelete: (c) => _confirmDelete(context, c),
              onNew: () {
                _newConversation(context);
                Navigator.of(context).pop();
              },
            ),
          ),
          body: _MessagesArea(state: state),
        );
      },
    );
  }
}

class _MessagesArea extends StatefulWidget {
  final ChatState state;
  const _MessagesArea({required this.state});

  @override
  State<_MessagesArea> createState() => _MessagesAreaState();
}

class _MessagesAreaState extends State<_MessagesArea> {
  final _scrollCtrl = ScrollController();

  @override
  void didUpdateWidget(covariant _MessagesArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Autoscroll w trakcie streamu i przy nowych wiadomościach
    if (widget.state.messages.length != oldWidget.state.messages.length ||
        (widget.state.messages.isNotEmpty &&
            oldWidget.state.messages.isNotEmpty &&
            widget.state.messages.last.content !=
                oldWidget.state.messages.last.content)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    if (state.activeConversation == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: EmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'Brak otwartej rozmowy',
            description:
                'Wybierz rozmowę z listy lub utwórz nową. Pamiętaj, by '
                'wcześniej wgrać materiały do tego przedmiotu.',
            action: FilledButton.icon(
              onPressed: () {
                final now = DateTime.now();
                final title =
                    'Rozmowa ${now.day}.${now.month} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                context.read<ChatBloc>().add(ChatConversationCreated(
                      subjectId: context
                          .findAncestorWidgetOfExactType<_ChatView>()!
                          .subjectId,
                      title: title,
                    ));
              },
              icon: const Icon(Icons.add),
              label: const Text('Nowa rozmowa'),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: state.messages.isEmpty
              ? const EmptyState(
                  icon: Icons.auto_awesome,
                  title: 'Zadaj pytanie',
                  description:
                      'Asystent przeszuka Twoje materiały i odpowie na podstawie '
                      'fragmentów najbardziej powiązanych z pytaniem. '
                      'Odpowiedzi są w języku polskim.',
                )
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: state.messages.length,
                  itemBuilder: (_, i) {
                    final m = state.messages[i];
                    final isLast = i == state.messages.length - 1;
                    return MessageBubble(
                      message: m,
                      isStreaming: isLast &&
                          state.streaming &&
                          m.role == MessageRole.assistant,
                    );
                  },
                ),
        ),
        ChatInput(
          enabled: state.activeConversation != null,
          streaming: state.streaming,
          onSend: (text) =>
              context.read<ChatBloc>().add(ChatMessageSent(text)),
        ),
      ],
    );
  }
}
