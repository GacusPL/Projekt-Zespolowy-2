import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../flashcards/domain/entities/flashcard.dart';
import '../../../flashcards/presentation/bloc/flashcards_bloc.dart';
import '../../../quiz/domain/entities/quiz.dart';
import '../../../quiz/domain/usecases/quiz_usecases.dart';

/// Strona statystyk - pokazuje postęp studenta w nauce.
/// Wykorzystuje `fl_chart` do wizualizacji:
///   1. krzywej wyników quizów w czasie,
///   2. statystyk fiszek (zgodnie z SM-2).
class StatisticsPage extends StatelessWidget {
  final String subjectId;
  const StatisticsPage({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<FlashcardsBloc>(
          create: (_) =>
              sl<FlashcardsBloc>()..add(FlashcardsLoadRequested(subjectId)),
        ),
      ],
      child: _StatsView(subjectId: subjectId),
    );
  }
}

class _StatsView extends StatefulWidget {
  final String subjectId;
  const _StatsView({required this.subjectId});

  @override
  State<_StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<_StatsView> {
  late Future<List<QuizAttempt>> _attemptsFuture;

  @override
  void initState() {
    super.initState();
    _attemptsFuture = _loadAttempts();
  }

  Future<List<QuizAttempt>> _loadAttempts() async {
    final uc = sl<GetQuizAttemptsUseCase>();
    final r = await uc(widget.subjectId);
    return r.fold((_) => <QuizAttempt>[], (l) => l);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _attemptsFuture = _loadAttempts();
        });
        context
            .read<FlashcardsBloc>()
            .add(FlashcardsLoadRequested(widget.subjectId));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              icon: Icons.quiz_outlined,
              title: 'Wyniki quizów',
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<QuizAttempt>>(
              future: _attemptsFuture,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final attempts = snap.data ?? [];
                return _QuizScoreCard(attempts: attempts);
              },
            ),
            const SizedBox(height: 24),
            const _SectionTitle(
              icon: Icons.style_outlined,
              title: 'Fiszki - postęp w nauce',
            ),
            const SizedBox(height: 12),
            BlocBuilder<FlashcardsBloc, FlashcardsState>(
              builder: (context, state) {
                if (state.loading) {
                  return const SizedBox(
                    height: 160,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return _FlashcardStatsCard(cards: state.cards);
              },
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: scheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

// ============================================================ QUIZ CARD
class _QuizScoreCard extends StatelessWidget {
  final List<QuizAttempt> attempts;
  const _QuizScoreCard({required this.attempts});

  @override
  Widget build(BuildContext context) {
    if (attempts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: EmptyState(
            icon: Icons.show_chart,
            title: 'Brak rozwiązanych quizów',
            description:
                'Wygeneruj quiz i rozwiąż go, by zobaczyć tu swoje postępy.',
          ),
        ),
      );
    }

    final avg = attempts
            .map((a) => a.percentage)
            .reduce((a, b) => a + b) /
        attempts.length;
    final best = attempts.map((a) => a.percentage).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatBadge(
                  label: 'Podejść',
                  value: attempts.length.toString(),
                  color: Colors.indigo,
                ),
                const SizedBox(width: 10),
                _StatBadge(
                  label: 'Średnia',
                  value: '${avg.toStringAsFixed(0)}%',
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 10),
                _StatBadge(
                  label: 'Najlepszy',
                  value: '${best.toStringAsFixed(0)}%',
                  color: Colors.green.shade600,
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: _buildLineChart(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spots = <FlSpot>[];
    for (int i = 0; i < attempts.length; i++) {
      spots.add(FlSpot(i.toDouble(), attempts[i].percentage));
    }
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (_) => FlLine(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: 25,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}%',
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: (attempts.length / 5).clamp(1, 999).toDouble(),
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= attempts.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('d.MM').format(attempts[i].completedAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: scheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 4,
                color: scheme.primary,
                strokeWidth: 2,
                strokeColor: scheme.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: scheme.primary.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================== FLASHCARDS CARD
class _FlashcardStatsCard extends StatelessWidget {
  final List<Flashcard> cards;
  const _FlashcardStatsCard({required this.cards});

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: EmptyState(
            icon: Icons.style_outlined,
            title: 'Brak fiszek',
            description:
                'Wygeneruj fiszki z materiałów, by zacząć śledzić naukę.',
          ),
        ),
      );
    }

    final due = cards.where((c) => c.isDue).length;
    final reviewed = cards.where((c) => c.lastReviewed != null).length;
    final mature = cards.where((c) => c.intervalDays >= 21).length;
    final avgEf = cards.map((c) => c.easeFactor).reduce((a, b) => a + b) /
        cards.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatBadge(
                  label: 'Wszystkich',
                  value: cards.length.toString(),
                  color: Colors.blue.shade600,
                ),
                const SizedBox(width: 10),
                _StatBadge(
                  label: 'Do powtórki',
                  value: due.toString(),
                  color: Colors.orange.shade700,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _StatBadge(
                  label: 'Powtórzonych',
                  value: reviewed.toString(),
                  color: Colors.teal,
                ),
                const SizedBox(width: 10),
                _StatBadge(
                  label: 'Utrwalonych (≥21 dni)',
                  value: mature.toString(),
                  color: Colors.green.shade600,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Średni współczynnik łatwości (SM-2): ${avgEf.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: cards.isEmpty ? 0 : mature / cards.length,
                minHeight: 8,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.green.shade600),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Postęp utrwalenia: ${cards.isEmpty ? 0 : ((mature / cards.length) * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
