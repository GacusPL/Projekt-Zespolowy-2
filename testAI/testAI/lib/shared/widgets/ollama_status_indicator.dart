import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/network/ollama_client.dart';

/// Mała plakietka w app-barze pokazująca status połączenia z lokalną Ollama.
/// Polling co 10 sekund — wystarczająco często, by szybko zauważyć, że
/// student zapomniał uruchomić `ollama serve`.
class OllamaStatusIndicator extends StatefulWidget {
  const OllamaStatusIndicator({super.key});

  @override
  State<OllamaStatusIndicator> createState() => _OllamaStatusIndicatorState();
}

class _OllamaStatusIndicatorState extends State<OllamaStatusIndicator> {
  bool? _reachable;
  Timer? _timer;
  late final OllamaClient _client;

  @override
  void initState() {
    super.initState();
    _client = sl<OllamaClient>();
    _check();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _check());
  }

  Future<void> _check() async {
    final ok = await _client.isReachable();
    if (mounted) setState(() => _reachable = ok);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ok = _reachable;
    final Color color;
    final String label;
    final IconData icon;

    if (ok == null) {
      color = scheme.outline;
      label = 'Sprawdzam Ollama…';
      icon = Icons.sync;
    } else if (ok) {
      color = Colors.green.shade600;
      label = 'Ollama online';
      icon = Icons.bolt;
    } else {
      color = scheme.error;
      label = 'Ollama offline';
      icon = Icons.bolt_outlined;
    }

    return Tooltip(
      message: ok == false
          ? 'Uruchom `ollama serve` w terminalu i sprawdź czy modele są pobrane.'
          : label,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _check,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
