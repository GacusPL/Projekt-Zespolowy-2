import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/quiz.dart';
import '../bloc/quiz_bloc.dart';
import 'quiz_results_page.dart';

class QuizPlayerPage extends StatefulWidget {
  final String quizId;
  final String subjectId;
  const QuizPlayerPage({
    super.key,
    required this.quizId,
    required this.subjectId,
  });

  @override
  State<QuizPlayerPage> createState() => _QuizPlayerPageState();
}

class _QuizPlayerPageState extends State<QuizPlayerPage> {
  int _idx = 0;
  int? _selectedAnswer;
  bool _showFeedback = false;
  final List<bool> _results = [];

  @override
  void initState() {
    super.initState();
    context.read<QuizBloc>().add(QuizOpenRequested(widget.quizId));
  }

  void _selectAnswer(int index, QuizQuestion question) {
    if (_showFeedback) return;
    setState(() {
      _selectedAnswer = index;
      _showFeedback = true;
      _results.add(index == question.correctIndex);
    });
  }

  void _next(int totalQuestions) {
    if (_idx + 1 >= totalQuestions) {
      _finish(totalQuestions);
      return;
    }
    setState(() {
      _idx++;
      _selectedAnswer = null;
      _showFeedback = false;
    });
  }

  void _finish(int totalQuestions) {
    final score = _results.where((r) => r).length;
    context.read<QuizBloc>().add(QuizAttemptSaveRequested(
          quizId: widget.quizId,
          subjectId: widget.subjectId,
          score: score,
          totalQuestions: totalQuestions,
        ));
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => QuizResultsPage(
          score: score,
          total: totalQuestions,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuizBloc, QuizState>(
      builder: (context, state) {
        final quiz = state.activeQuiz;
        if (state.loading || quiz == null || quiz.id != widget.quizId) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final questions = quiz.questions;
        if (questions.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(quiz.title)),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Ten quiz nie zawiera pytań.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final q = questions[_idx];
        final progress = (_idx + 1) / questions.length;
        return Scaffold(
          appBar: AppBar(
            title: Text('Pytanie ${_idx + 1} z ${questions.length}'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4),
              child: LinearProgressIndicator(value: progress),
            ),
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              q.question,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ...List.generate(q.options.length, (i) {
                              return _OptionTile(
                                index: i,
                                text: q.options[i],
                                selected: _selectedAnswer == i,
                                isCorrect: q.correctIndex == i,
                                showFeedback: _showFeedback,
                                onTap: () => _selectAnswer(i, q),
                              );
                            }),
                            if (_showFeedback && q.explanation != null) ...[
                              const SizedBox(height: 16),
                              _ExplanationBox(text: q.explanation!),
                            ],
                            const Spacer(),
                            if (_showFeedback)
                              FilledButton(
                                onPressed: () => _next(questions.length),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                ),
                                child: Text(
                                  _idx + 1 >= questions.length
                                      ? 'Zobacz wynik'
                                      : 'Następne pytanie',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _OptionTile extends StatelessWidget {
  final int index;
  final String text;
  final bool selected;
  final bool isCorrect;
  final bool showFeedback;
  final VoidCallback onTap;

  const _OptionTile({
    required this.index,
    required this.text,
    required this.selected,
    required this.isCorrect,
    required this.showFeedback,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color borderColor = scheme.outlineVariant;
    Color bg = scheme.surface;
    Color labelBg = scheme.surfaceContainerHigh;
    Color labelFg = scheme.onSurface;
    IconData? trailingIcon;
    Color? trailingColor;

    if (showFeedback) {
      if (isCorrect) {
        borderColor = Colors.green.shade500;
        bg = Colors.green.shade50;
        labelBg = Colors.green.shade500;
        labelFg = Colors.white;
        trailingIcon = Icons.check_circle;
        trailingColor = Colors.green.shade600;
      } else if (selected) {
        borderColor = Colors.red.shade400;
        bg = Colors.red.shade50;
        labelBg = Colors.red.shade400;
        labelFg = Colors.white;
        trailingIcon = Icons.cancel;
        trailingColor = Colors.red.shade500;
      }
    } else if (selected) {
      borderColor = scheme.primary;
      bg = scheme.primary.withOpacity(0.08);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: showFeedback ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: labelBg,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    String.fromCharCode(65 + index), // A, B, C, D
                    style: TextStyle(
                      color: labelFg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      color: showFeedback && bg != scheme.surface
                          ? Colors.black87
                          : scheme.onSurface,
                    ),
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  Icon(trailingIcon, color: trailingColor),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExplanationBox extends StatelessWidget {
  final String text;
  const _ExplanationBox({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.tertiary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 16, color: scheme.tertiary),
              const SizedBox(width: 6),
              Text(
                'WYJAŚNIENIE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: scheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}
