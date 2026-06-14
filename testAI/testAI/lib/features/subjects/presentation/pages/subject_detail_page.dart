import 'package:flutter/material.dart';

import '../../../../shared/widgets/ollama_status_indicator.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../documents/presentation/pages/documents_page.dart';
import '../../../flashcards/presentation/pages/flashcards_page.dart';
import '../../../quiz/presentation/pages/quiz_list_page.dart';
import '../../../statistics/presentation/pages/statistics_page.dart';
import '../../domain/entities/subject.dart';

/// Strona przedmiotu z 5 zakładkami: dokumenty / czat / fiszki / quizy / statystyki.
class SubjectDetailPage extends StatelessWidget {
  final Subject subject;
  const SubjectDetailPage({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 5,
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
            DocumentsPage(subjectId: subject.id),
            ChatPage(subjectId: subject.id, subjectName: subject.name),
            FlashcardsPage(subjectId: subject.id),
            QuizListPage(subjectId: subject.id, subjectName: subject.name),
            StatisticsPage(subjectId: subject.id),
          ],
        ),
      ),
    );
  }
}
