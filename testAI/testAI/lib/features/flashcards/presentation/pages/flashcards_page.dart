import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/entities/flashcard.dart';
import '../bloc/flashcards_bloc.dart';
import 'review_session_page.dart';

class FlashcardsPage extends StatelessWidget {
  final String subjectId;
  const FlashcardsPage({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FlashcardsBloc>(
      create: (_) =>
          sl<FlashcardsBloc>()..add(FlashcardsLoadRequested(subjectId)),
      child: _FlashcardsView(subjectId: subjectId),
    );
  }
}

class _FlashcardsView extends StatelessWidget {
  final String subjectId;
  const _FlashcardsView({required this.subjectId});

  Future<void> _generate(BuildContext context) async {
    final count = await showDialog<int>(
      context: context,
      builder: (_) => const _CountPickerDialog(
        title: 'Generuj fiszki',
        description: 'Ile fiszek wygenerować z materiałów?',
        options: [5, 10, 20, 30],
      ),
    );
    if (count == null || !context.mounted) return;
    context.read<FlashcardsBloc>().add(FlashcardsGenerateRequested(
          subjectId: subjectId,
          count: count,
        ));
  }

  void _startReview(BuildContext context, List<Flashcard> cards) {
    if (cards.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<FlashcardsBloc>(),
          child: ReviewSessionPage(cards: cards),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FlashcardsBloc, FlashcardsState>(
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
        if (state.loading && state.cards.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.cards.isEmpty) {
          return EmptyState(
            icon: Icons.style_outlined,
            title: 'Brak fiszek',
            description:
                'Wygeneruj fiszki z materiałów lub dodaj je ręcznie. Aplikacja '
                'wykorzystuje algorytm SM-2 (spaced repetition) — tak samo jak Anki.',
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
                  ? 'Generuję…'
                  : 'Wygeneruj z materiałów'),
            ),
          );
        }

        final due = state.dueCards;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: _SummaryBar(
                total: state.cards.length,
                due: due.length,
                generating: state.generating,
                onGenerate: () => _generate(context),
                onReview:
                    due.isEmpty ? null : () => _startReview(context, due),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: state.cards.length,
                itemBuilder: (_, i) {
                  final c = state.cards[i];
                  return _FlashcardListTile(
                    card: c,
                    onDelete: () => context
                        .read<FlashcardsBloc>()
                        .add(FlashcardsDeleteRequested(c.id)),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final int total;
  final int due;
  final bool generating;
  final VoidCallback onGenerate;
  final VoidCallback? onReview;

  const _SummaryBar({
    required this.total,
    required this.due,
    required this.generating,
    required this.onGenerate,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, Colors.black, 0.2)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _StatChip(
                label: 'Wszystkich',
                value: total.toString(),
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: 'Do powtórki',
                value: due.toString(),
                emphasised: due > 0,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: generating ? null : onGenerate,
                  icon: generating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: Text(generating ? 'Generuję…' : 'Wygeneruj'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: scheme.primary,
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onReview,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: Text(
                    due == 0 ? 'Nic do nauki' : 'Ucz się ($due)',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.25),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasised;
  const _StatChip({
    required this.label,
    required this.value,
    this.emphasised = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: emphasised ? 0.25 : 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlashcardListTile extends StatelessWidget {
  final Flashcard card;
  final VoidCallback onDelete;
  const _FlashcardListTile({required this.card, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          card.question,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              if (card.isDue)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade400.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'DO POWTÓRKI',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade700,
                    ),
                  ),
                )
              else
                Text(
                  'Następna: ${_relativeDays(card.dueDate)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                'EF ${card.easeFactor.toStringAsFixed(2)}  •  pwt. ${card.repetitions}',
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: scheme.surfaceContainerHigh,
            child: Text(card.answer),
          ),
        ],
      ),
    );
  }

  static String _relativeDays(DateTime due) {
    final diff = due.difference(DateTime.now()).inDays;
    if (diff < 1) return 'dziś';
    if (diff == 1) return 'jutro';
    return 'za $diff dni';
  }
}

class _CountPickerDialog extends StatelessWidget {
  final String title;
  final String description;
  final List<int> options;
  const _CountPickerDialog({
    required this.title,
    required this.description,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(description),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options
                .map((o) => FilledButton.tonal(
                      onPressed: () => Navigator.of(context).pop(o),
                      child: Text('$o'),
                    ))
                .toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
      ],
    );
  }
}
