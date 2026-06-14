import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/entities/quiz.dart';
import '../bloc/quiz_bloc.dart';
import 'quiz_player_page.dart';

class QuizListPage extends StatelessWidget {
  final String subjectId;
  final String subjectName;
  const QuizListPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<QuizBloc>(
      create: (_) => sl<QuizBloc>()..add(QuizListLoadRequested(subjectId)),
      child: _QuizListView(subjectId: subjectId, subjectName: subjectName),
    );
  }
}

class _QuizListView extends StatelessWidget {
  final String subjectId;
  final String subjectName;
  const _QuizListView({required this.subjectId, required this.subjectName});

  Future<void> _generate(BuildContext context) async {
    final result = await showDialog<({String title, int count})>(
      context: context,
      builder: (_) => _GenerateQuizDialog(defaultTitle: 'Quiz: $subjectName'),
    );
    if (result == null || !context.mounted) return;
    context.read<QuizBloc>().add(QuizGenerateRequested(
          subjectId: subjectId,
          title: result.title,
          questionCount: result.count,
        ));
  }

  void _openQuiz(BuildContext context, Quiz quiz) {
    // Pełna wersja (z pytaniami) jest dociągana w QuizPlayerPage przez QuizOpenRequested.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<QuizBloc>(),
          child: QuizPlayerPage(quizId: quiz.id, subjectId: subjectId),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Quiz quiz) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usunąć quiz?'),
        content: Text(
          'Czy usunąć "${quiz.title}" wraz z wszystkimi pytaniami i wynikami?',
        ),
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
      context.read<QuizBloc>().add(QuizDeleteRequested(quiz.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QuizBloc, QuizState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.loading && state.quizzes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.quizzes.isEmpty) {
          return EmptyState(
            icon: Icons.quiz_outlined,
            title: 'Brak quizów',
            description:
                'Wygeneruj quiz z materiałów — pytania jednokrotnego wyboru '
                'z wyjaśnieniem poprawnych odpowiedzi.',
            action: FilledButton.icon(
              onPressed:
                  state.generating ? null : () => _generate(context),
              icon: state.generating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(state.generating
                  ? 'Generuję pytania…'
                  : 'Wygeneruj quiz'),
            ),
          );
        }

        return Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: state.quizzes.length,
              itemBuilder: (_, i) {
                final q = state.quizzes[i];
                return _QuizTile(
                  quiz: q,
                  onTap: () => _openQuiz(context, q),
                  onDelete: () => _confirmDelete(context, q),
                );
              },
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.extended(
                onPressed:
                    state.generating ? null : () => _generate(context),
                icon: state.generating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(state.generating ? 'Generuję…' : 'Nowy quiz'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuizTile extends StatelessWidget {
  final Quiz quiz;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _QuizTile({
    required this.quiz,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('d MMM yyyy, HH:mm', 'pl_PL');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.quiz_outlined, color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Utworzono ${dateFmt.format(quiz.createdAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenerateQuizDialog extends StatefulWidget {
  final String defaultTitle;
  const _GenerateQuizDialog({required this.defaultTitle});

  @override
  State<_GenerateQuizDialog> createState() => _GenerateQuizDialogState();
}

class _GenerateQuizDialogState extends State<_GenerateQuizDialog> {
  late final TextEditingController _titleCtrl;
  int _count = 10;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.defaultTitle);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Wygeneruj quiz'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Tytuł quizu'),
            ),
            const SizedBox(height: 16),
            const Text('Liczba pytań',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [5, 10, 15, 20].map((n) {
                final selected = n == _count;
                return ChoiceChip(
                  label: Text('$n'),
                  selected: selected,
                  onSelected: (_) => setState(() => _count = n),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop((
            title: _titleCtrl.text.trim(),
            count: _count,
          )),
          child: const Text('Generuj'),
        ),
      ],
    );
  }
}
