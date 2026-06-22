import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/flashcard.dart';
import '../bloc/flashcards_bloc.dart';
import '../widgets/flashcard_widget.dart';

/// Ekran sesji powtórek — przewijanie listy fiszek do nauki + 4 oceny SM-2.
class ReviewSessionPage extends StatefulWidget {
  final List<Flashcard> cards;
  const ReviewSessionPage({super.key, required this.cards});

  @override
  State<ReviewSessionPage> createState() => _ReviewSessionPageState();
}

class _ReviewSessionPageState extends State<ReviewSessionPage> {
  late List<Flashcard> _queue;
  int _idx = 0;
  bool _showAnswer = false;
  int _correctCount = 0;

  @override
  void initState() {
    super.initState();
    _queue = List<Flashcard>.from(widget.cards)..shuffle();
  }

  Flashcard? get _current => _idx < _queue.length ? _queue[_idx] : null;
  double get _progress =>
      _queue.isEmpty ? 1 : (_idx / _queue.length).clamp(0, 1);

  void _grade(ReviewGrade grade) {
    final card = _current;
    if (card == null) return;
    context.read<FlashcardsBloc>().add(FlashcardReviewed(
          card: card,
          grade: grade,
        ));
    if (grade.q >= 3) _correctCount++;
    setState(() {
      _idx++;
      _showAnswer = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sesja powtórek'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: _progress),
        ),
      ),
      body: SafeArea(
        child: _current == null
            ? _SessionSummary(
                total: _queue.length,
                correct: _correctCount,
                onDone: () => Navigator.of(context).pop(),
              )
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Fiszka ${_idx + 1} / ${_queue.length}',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'EF: ${_current!.easeFactor.toStringAsFixed(2)}  •  '
                          'powtórzeń: ${_current!.repetitions}',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 520,
                            maxHeight: 360,
                          ),
                          child: SizedBox.expand(
                            child: FlashcardWidget(
                              card: _current!,
                              showAnswer: _showAnswer,
                              onFlip: () =>
                                  setState(() => _showAnswer = !_showAnswer),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!_showAnswer)
                      FilledButton.tonal(
                        onPressed: () => setState(() => _showAnswer = true),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text('Pokaż odpowiedź'),
                      )
                    else
                      _GradeButtons(onGrade: _grade),
                  ],
                ),
              ),
      ),
    );
  }
}

class _GradeButtons extends StatelessWidget {
  final void Function(ReviewGrade) onGrade;
  const _GradeButtons({required this.onGrade});

  @override
  Widget build(BuildContext context) {
    final colors = {
      ReviewGrade.again: Colors.red.shade400,
      ReviewGrade.hard: Colors.orange.shade400,
      ReviewGrade.good: Colors.blue.shade500,
      ReviewGrade.easy: Colors.green.shade500,
    };
    final subtitles = {
      ReviewGrade.again: '< 1 min',
      ReviewGrade.hard: 'krótko',
      ReviewGrade.good: 'normalnie',
      ReviewGrade.easy: 'długo',
    };

    return Row(
      children: ReviewGrade.values.map((g) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Material(
              color: colors[g],
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onGrade(g),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Column(
                    children: [
                      // FittedBox — na wąskim ekranie etykieta skaluje się
                      // zamiast zawijać/wychodzić poza przycisk.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          g.label,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitles[g]!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SessionSummary extends StatelessWidget {
  final int total;
  final int correct;
  final VoidCallback onDone;
  const _SessionSummary({
    required this.total,
    required this.correct,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = total == 0 ? 0 : (correct / total * 100).round();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events,
                size: 56,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sesja zakończona!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Poprawnie: $correct / $total ($pct%)',
              style: TextStyle(
                fontSize: 16,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onDone,
              icon: const Icon(Icons.check),
              label: const Text('Wróć do fiszek'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(220, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
