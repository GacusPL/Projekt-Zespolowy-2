import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../shared/widgets/keep_alive_wrapper.dart';
import '../../../../shared/widgets/ollama_status_indicator.dart';
import '../../../chat/presentation/bloc/chat_bloc.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../documents/presentation/pages/documents_page.dart';
import '../../../flashcards/presentation/pages/flashcards_page.dart';
import '../../../quiz/presentation/pages/quiz_list_page.dart';
import '../../../statistics/presentation/pages/statistics_page.dart';
import '../../domain/entities/subject.dart';

/// Strona przedmiotu z 5 zakładkami: dokumenty / czat / fiszki / quizy / statystyki.
///
/// `ChatBloc` jest dostarczany tutaj (ponad `TabBarView`), żeby przeżył
/// przełączanie zakładek i całe okno przedmiotu - dzięki temu trwający stream
/// czatu nie jest anulowany przy zmianie zakładki. Zakładki są dodatkowo owinięte
/// w [KeepAliveWrapper], by zachować swój stan (scroll, wpisany tekst itp.).
class SubjectDetailPage extends StatelessWidget {
  final Subject subject;
  const SubjectDetailPage({super.key, required this.subject});

  Future<void> _confirmExitWhileStreaming(BuildContext context) async {
    final bloc = context.read<ChatBloc>();
    final nav = Navigator.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Przerwać generowanie?'),
        content: const Text(
          'Asystent wciąż generuje odpowiedź. Wyjście przerwie generowanie - '
          'to, co już powstało, zostanie zapisane w rozmowie.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Zostań'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Wyjdź'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      bloc.add(const ChatStreamStopRequested());
      nav.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocProvider<ChatBloc>(
      create: (_) =>
          sl<ChatBloc>()..add(ChatConversationsLoadRequested(subject.id)),
      child: DefaultTabController(
        length: 5,
        child: BlocBuilder<ChatBloc, ChatState>(
          buildWhen: (a, b) => a.streaming != b.streaming,
          builder: (context, chatState) => PopScope(
            canPop: !chatState.streaming,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              _confirmExitWhileStreaming(context);
            },
            child: Scaffold(
              appBar: AppBar(
                title: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: subject.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        subject.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                actions: const [
                  OllamaStatusIndicator(),
                  SizedBox(width: 16),
                ],
                bottom: TabBar(
                  isScrollable: true,
                  labelColor: scheme.primary,
                  unselectedLabelColor: scheme.onSurfaceVariant,
                  indicatorColor: scheme.primary,
                  tabs: const [
                    Tab(icon: Icon(Icons.description_outlined), text: 'Materiały'),
                    Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Czat (RAG)'),
                    Tab(icon: Icon(Icons.style_outlined), text: 'Fiszki'),
                    Tab(icon: Icon(Icons.quiz_outlined), text: 'Quizy'),
                    Tab(icon: Icon(Icons.insights_outlined), text: 'Statystyki'),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  KeepAliveWrapper(child: DocumentsPage(subjectId: subject.id)),
                  KeepAliveWrapper(
                    child: ChatPage(
                      subjectId: subject.id,
                      subjectName: subject.name,
                    ),
                  ),
                  KeepAliveWrapper(child: FlashcardsPage(subjectId: subject.id)),
                  KeepAliveWrapper(
                    child: QuizListPage(
                      subjectId: subject.id,
                      subjectName: subject.name,
                    ),
                  ),
                  KeepAliveWrapper(child: StatisticsPage(subjectId: subject.id)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
