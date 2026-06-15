import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/ollama_client.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/settings/ollama_models.dart';

/// Ekran ustawień — pozwala zmienić adres serwera Ollama oraz wybrać modele
/// z listy, bez rekompilacji aplikacji.
///
/// Typowy scenariusz: Ollama uruchomiona w Google Colab i wystawiona tunelem
/// ngrok. Użytkownik wybiera tryb „Zewnętrznie", wkleja URL z Colaba i zapisuje.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late final AppSettings _settings;
  late final OllamaClient _ollama;

  late OllamaConnectionMode _mode;
  late final TextEditingController _urlCtrl;

  // Wybrane modele (źródło prawdy dla dropdownów).
  late String _chatModel;
  late String _embeddingModel;
  late String _visionModel;

  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _settings = sl<AppSettings>();
    _ollama = sl<OllamaClient>();

    _mode = _settings.connectionMode;
    _urlCtrl = TextEditingController(
      text: _mode == OllamaConnectionMode.external
          ? _settings.ollamaBaseUrl
          : '',
    );
    _chatModel = _settings.chatModel;
    _embeddingModel = _settings.embeddingModel;
    _visionModel = _settings.visionModel;
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  /// Adres wynikający z aktualnie wybranego trybu i zawartości pola.
  String get _effectiveUrl => _mode == OllamaConnectionMode.local
      ? AppConstants.defaultOllamaBaseUrl
      : _urlCtrl.text;

  Future<void> _testConnection() async {
    setState(() => _testing = true);
    final ok = await _ollama.isReachable(baseUrlOverride: _effectiveUrl);
    if (!mounted) return;
    setState(() => _testing = false);
    if (ok) {
      _showSnack('Połączono z Ollama ✓');
    } else {
      final err = _ollama.lastError ?? 'Nieznany błąd';
      _showSnack('Brak połączenia z Ollama: $err', isError: true);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    await _settings.update(
      baseUrl: _effectiveUrl,
      chatModel: _chatModel,
      embeddingModel: _embeddingModel,
      visionModel: _visionModel,
    );
    if (!mounted) return;
    _showSnack('Zapisano ustawienia');
    Navigator.of(context).pop();
  }

  Future<void> _resetDefaults() async {
    await _settings.resetToDefaults();
    if (!mounted) return;
    setState(() {
      _mode = _settings.connectionMode;
      _urlCtrl.text = '';
      _chatModel = _settings.chatModel;
      _embeddingModel = _settings.embeddingModel;
      _visionModel = _settings.visionModel;
    });
    _showSnack('Przywrócono ustawienia domyślne');
  }

  void _showSnack(String message, {bool isError = false}) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? scheme.error : null,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ustawienia')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ConnectionCard(
              mode: _mode,
              urlController: _urlCtrl,
              testing: _testing,
              onModeChanged: (m) => setState(() => _mode = m),
              onTest: _testConnection,
            ),
            const SizedBox(height: 16),
            _ModelsCard(
              chatModel: _chatModel,
              embeddingModel: _embeddingModel,
              visionModel: _visionModel,
              onChatChanged: (v) => setState(() => _chatModel = v),
              onEmbeddingChanged: (v) => setState(() => _embeddingModel = v),
              onVisionChanged: (v) => setState(() => _visionModel = v),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Zapisz'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _resetDefaults,
              icon: const Icon(Icons.restore),
              label: const Text('Przywróć domyślne'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Karta z wyborem trybu połączenia i adresem serwera.
class _ConnectionCard extends StatelessWidget {
  final OllamaConnectionMode mode;
  final TextEditingController urlController;
  final bool testing;
  final ValueChanged<OllamaConnectionMode> onModeChanged;
  final VoidCallback onTest;

  const _ConnectionCard({
    required this.mode,
    required this.urlController,
    required this.testing,
    required this.onModeChanged,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    final isExternal = mode == OllamaConnectionMode.external;
    return _SettingsCard(
      icon: Icons.lan_outlined,
      title: 'Połączenie z Ollama',
      children: [
        SegmentedButton<OllamaConnectionMode>(
          segments: const [
            ButtonSegment(
              value: OllamaConnectionMode.local,
              label: Text('Lokalnie'),
              icon: Icon(Icons.computer),
            ),
            ButtonSegment(
              value: OllamaConnectionMode.external,
              label: Text('Zewnętrznie'),
              icon: Icon(Icons.cloud_outlined),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (s) => onModeChanged(s.first),
        ),
        const SizedBox(height: 12),
        if (!isExternal)
          Text(
            'Łączy się z lokalną instancją: '
            '${AppConstants.defaultOllamaBaseUrl}\n'
            'Uruchom `ollama serve` na tym komputerze.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          TextFormField(
            controller: urlController,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Adres serwera (URL)',
              hintText: 'https://abc123.ngrok-free.app',
              helperText: 'Np. tunel ngrok wystawiający Ollamę z Google Colab.',
              prefixIcon: Icon(Icons.link),
            ),
            validator: (v) {
              if (mode != OllamaConnectionMode.external) return null;
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'Podaj adres serwera';
              final uri = Uri.tryParse(value);
              if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
                return 'Niepoprawny URL (zacznij od http:// lub https://)';
              }
              return null;
            },
          ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: testing ? null : onTest,
            icon: testing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_tethering),
            label: const Text('Testuj połączenie'),
          ),
        ),
      ],
    );
  }
}

/// Karta z wyborem modeli Ollama (dropdowny z listą + rozmiarem w GB).
class _ModelsCard extends StatelessWidget {
  final String chatModel;
  final String embeddingModel;
  final String visionModel;
  final ValueChanged<String> onChatChanged;
  final ValueChanged<String> onEmbeddingChanged;
  final ValueChanged<String> onVisionChanged;

  const _ModelsCard({
    required this.chatModel,
    required this.embeddingModel,
    required this.visionModel,
    required this.onChatChanged,
    required this.onEmbeddingChanged,
    required this.onVisionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      icon: Icons.psychology_outlined,
      title: 'Modele',
      children: [
        Text(
          'Wybierz z listy — pokazany rozmiar to przybliżona zajętość VRAM. '
          'Budżet karty: ${OllamaModels.maxVramGb.toStringAsFixed(1)} GB. '
          'Pamiętaj, by wcześniej pobrać model: `ollama pull <nazwa>`.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const SizedBox(height: 16),
        _ModelDropdown(
          label: 'Model czatu (RAG)',
          icon: Icons.chat_outlined,
          value: chatModel,
          options: OllamaModels.chat,
          onChanged: onChatChanged,
        ),
        const SizedBox(height: 16),
        _ModelDropdown(
          label: 'Model embeddingów',
          icon: Icons.scatter_plot_outlined,
          value: embeddingModel,
          options: OllamaModels.embedding,
          onChanged: onEmbeddingChanged,
        ),
        const SizedBox(height: 4),
        Text(
          'Uwaga: zmiana modelu embeddingów na taki o innej wymiarowości '
          'sprawia, że wcześniej zapisane fragmenty trzeba wgrać ponownie.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const SizedBox(height: 16),
        _ModelDropdown(
          label: 'Model wizyjny (OCR zdjęć)',
          icon: Icons.image_outlined,
          value: visionModel,
          options: OllamaModels.vision,
          onChanged: onVisionChanged,
        ),
      ],
    );
  }
}

/// Dropdown wyboru modelu z listy [options]. Jeśli aktualnie zapisany model
/// nie znajduje się w katalogu (np. ustawiony wcześniej ręcznie), dodaje go
/// jako dodatkową pozycję, żeby nie zniknął po wejściu w ustawienia.
class _ModelDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final List<OllamaModelOption> options;
  final ValueChanged<String> onChanged;

  const _ModelDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final names = options.map((o) => o.name).toList();
    final items = <DropdownMenuItem<String>>[
      for (final o in options)
        DropdownMenuItem(value: o.name, child: Text(o.label)),
      if (!names.contains(value))
        DropdownMenuItem(value: value, child: Text('$value (własny)')),
    ];

    return DropdownButtonFormField<String>(
      // Klucz zależny od wartości — gdy zmieni się ona z zewnątrz (np. „Przywróć
      // domyślne"), pole zainicjuje się ponownie z nowym wyborem.
      key: ValueKey('$label::$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      items: items,
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

/// Wspólny kontener karty ustawień (ikona + tytuł + zawartość).
class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: scheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
