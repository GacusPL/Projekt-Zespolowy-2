import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/ollama_status_indicator.dart';
import '../../domain/entities/subject.dart';
import '../bloc/subjects_bloc.dart';
import '../widgets/create_subject_dialog.dart';
import 'subject_detail_page.dart';

/// Główny ekran aplikacji — siatka kart przedmiotów.
class SubjectsPage extends StatelessWidget {
  const SubjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SubjectsBloc>(
      create: (_) => sl<SubjectsBloc>()..add(const SubjectsLoadRequested()),
      child: const _SubjectsView(),
    );
  }
}

class _SubjectsView extends StatelessWidget {
  const _SubjectsView();

  Future<void> _createSubject(BuildContext context) async {
    final res = await showCreateSubjectDialog(context);
    if (res == null || !context.mounted) return;
    context.read<SubjectsBloc>().add(SubjectsCreateRequested(
          name: res.name,
          description: res.description,
          colorValue: res.colorValue,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_stories,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text('LekturAI'),
          ],
        ),
        actions: const [
          OllamaStatusIndicator(),
          SizedBox(width: 16),
        ],
      ),
      body: BlocBuilder<SubjectsBloc, SubjectsState>(
        builder: (context, state) {
          if (state.loading && state.subjects.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null && state.subjects.isEmpty) {
            return ErrorView(
              message: state.error!,
              onRetry: () => context
                  .read<SubjectsBloc>()
                  .add(const SubjectsLoadRequested()),
            );
          }
          if (state.subjects.isEmpty) {
            return EmptyState(
              icon: Icons.school_outlined,
              title: 'Brak przedmiotów',
              description:
                  'Zacznij od dodania przedmiotu, do którego wgrasz materiały.',
              action: FilledButton.icon(
                onPressed: () => _createSubject(context),
                icon: const Icon(Icons.add),
                label: const Text('Dodaj przedmiot'),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final cols = width > 1100
                    ? 4
                    : width > 800
                        ? 3
                        : width > 500
                            ? 2
                            : 1;
                return GridView.builder(
                  itemCount: state.subjects.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.5,
                  ),
                  itemBuilder: (_, i) => _SubjectCard(
                    subject: state.subjects[i],
                    onDelete: () => _confirmDelete(context, state.subjects[i]),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createSubject(context),
        icon: const Icon(Icons.add),
        label: const Text('Przedmiot'),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Subject s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usunąć przedmiot?'),
        content: Text(
          'Usunięcie "${s.name}" skasuje także wszystkie powiązane dokumenty, '
          'rozmowy, fiszki i quizy. Tej operacji nie można cofnąć.',
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
      context.read<SubjectsBloc>().add(SubjectsDeleteRequested(s.id));
    }
  }
}

class _SubjectCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback onDelete;
  const _SubjectCard({required this.subject, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy', 'pl_PL');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SubjectDetailPage(subject: subject),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                subject.color,
                Color.lerp(subject.color, Colors.black, 0.25)!,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: subject.color.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.menu_book_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    subject.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subject.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      subject.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Utworzono ${dateFmt.format(subject.createdAt)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Positioned(
                top: -8,
                right: -8,
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Colors.white),
                  onSelected: (v) {
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18),
                          SizedBox(width: 8),
                          Text('Usuń przedmiot'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
