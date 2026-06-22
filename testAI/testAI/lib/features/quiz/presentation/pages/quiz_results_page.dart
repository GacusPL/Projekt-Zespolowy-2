import 'package:flutter/material.dart';

class QuizResultsPage extends StatelessWidget {
  final int score;
  final int total;
  const QuizResultsPage({super.key, required this.score, required this.total});

  String _verdict(double pct) {
    if (pct >= 90) return 'Świetnie! Materiał opanowany.';
    if (pct >= 75) return 'Dobry wynik — jeszcze trochę i będzie idealnie.';
    if (pct >= 50) return 'Średnio. Warto powtórzyć materiał.';
    return 'Wróć do materiałów i spróbuj ponownie.';
  }

  IconData _icon(double pct) {
    if (pct >= 90) return Icons.emoji_events;
    if (pct >= 75) return Icons.star_rounded;
    if (pct >= 50) return Icons.thumb_up_outlined;
    return Icons.refresh;
  }

  Color _color(double pct) {
    if (pct >= 75) return Colors.green.shade500;
    if (pct >= 50) return Colors.amber.shade600;
    return Colors.red.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : (score / total * 100);
    final color = _color(pct);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wynik quizu'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color,
                      Color.lerp(color, Colors.black, 0.25)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Icon(_icon(pct), color: Colors.white, size: 70),
              ),
              const SizedBox(height: 28),
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$score z $total poprawnych odpowiedzi',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _verdict(pct),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 40),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.list_alt),
                label: const Text('Wróć do listy quizów'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(260, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
