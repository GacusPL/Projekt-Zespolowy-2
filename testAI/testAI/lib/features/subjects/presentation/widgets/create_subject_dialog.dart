import 'package:flutter/material.dart';

class CreateSubjectDialog extends StatefulWidget {
  const CreateSubjectDialog({super.key});

  @override
  State<CreateSubjectDialog> createState() => _CreateSubjectDialogState();
}

class _CreateSubjectDialogState extends State<CreateSubjectDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  // Paleta kolorów do wyboru — wszystkie odcienie 600/500 dla spójności.
  // Trzymamy jako int (ARGB) by uniknąć zależności od wersji API Color.
  static const _paletteValues = <int>[
    0xFF4F46E5, // indigo
    0xFF0EA5E9, // sky
    0xFF10B981, // emerald
    0xFFF59E0B, // amber
    0xFFEF4444, // red
    0xFFEC4899, // pink
    0xFF8B5CF6, // violet
    0xFF14B8A6, // teal
  ];

  int _selectedColorIndex = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(_CreateSubjectResult(
      name: name,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      colorValue: _paletteValues[_selectedColorIndex],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nowy przedmiot'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nazwa',
                hintText: 'np. Algebra liniowa',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Opis (opcjonalnie)',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Kolor karty',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(_paletteValues.length, (i) {
                final selected = i == _selectedColorIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColorIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(_paletteValues[i]),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Utwórz')),
      ],
    );
  }
}

class _CreateSubjectResult {
  final String name;
  final String? description;
  final int colorValue;

  _CreateSubjectResult({
    required this.name,
    this.description,
    required this.colorValue,
  });
}

/// Funkcja-helper wywołująca dialog i zwracająca wynik (lub null).
Future<({String name, String? description, int colorValue})?>
    showCreateSubjectDialog(BuildContext context) async {
  final res = await showDialog<_CreateSubjectResult>(
    context: context,
    builder: (_) => const CreateSubjectDialog(),
  );
  if (res == null) return null;
  return (
    name: res.name,
    description: res.description,
    colorValue: res.colorValue
  );
}
