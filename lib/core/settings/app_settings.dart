import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Tryb połączenia z serwerem Ollama.
enum OllamaConnectionMode {
  /// Lokalna instancja na tym komputerze (`http://localhost:11434`).
  local,

  /// Zewnętrzny adres — np. tunel ngrok wystawiający Ollamę z Google Colab.
  external,
}

/// Ustawienia aplikacji trzymane w pamięci i utrwalane w [SharedPreferences].
///
/// Pozwala zmienić w trakcie działania aplikacji:
/// - adres serwera Ollama (lokalny `localhost` albo zewnętrzny tunel, np. ngrok
///   z Google Colab),
/// - nazwy modeli (chat / embedding / vision),
///
/// bez rekompilacji aplikacji. [OllamaClient] czyta z tego obiektu przy każdym
/// zapytaniu, więc zmiany zaczynają obowiązywać natychmiast po zapisie.
///
/// Jest [ChangeNotifier] — widżety (np. wskaźnik statusu) mogą nasłuchiwać i
/// odświeżać się po zmianie konfiguracji.
class AppSettings extends ChangeNotifier {
  static const String _kBaseUrl = 'ollama_base_url';
  static const String _kChatModel = 'ollama_chat_model';
  static const String _kEmbeddingModel = 'ollama_embedding_model';
  static const String _kVisionModel = 'ollama_vision_model';
  static const String _kThemeMode = 'theme_mode';

  final SharedPreferences _prefs;

  AppSettings(this._prefs);

  String _baseUrl = AppConstants.defaultOllamaBaseUrl;
  String _chatModel = AppConstants.chatModel;
  String _embeddingModel = AppConstants.embeddingModel;
  String _visionModel = AppConstants.visionModel;
  ThemeMode _themeMode = ThemeMode.system;

  /// Adres bazowy Ollama bez końcowego ukośnika (np. `http://localhost:11434`).
  String get ollamaBaseUrl => _baseUrl;
  String get chatModel => _chatModel;
  String get embeddingModel => _embeddingModel;
  String get visionModel => _visionModel;

  /// Wybrany tryb motywu (jasny / ciemny / zgodny z systemem).
  ThemeMode get themeMode => _themeMode;

  /// Czy aktualny adres wskazuje na lokalną instancję (domyślny localhost).
  OllamaConnectionMode get connectionMode =>
      _baseUrl == AppConstants.defaultOllamaBaseUrl
          ? OllamaConnectionMode.local
          : OllamaConnectionMode.external;

  /// Wczytuje zapisane wartości (lub domyślne z [AppConstants], gdy brak).
  /// Wywoływane raz przy starcie, w `initDependencies()`.
  void load() {
    _baseUrl = _prefs.getString(_kBaseUrl) ?? AppConstants.defaultOllamaBaseUrl;
    _chatModel = _prefs.getString(_kChatModel) ?? AppConstants.chatModel;
    _embeddingModel =
        _prefs.getString(_kEmbeddingModel) ?? AppConstants.embeddingModel;
    _visionModel = _prefs.getString(_kVisionModel) ?? AppConstants.visionModel;
    _themeMode = _themeModeFromString(_prefs.getString(_kThemeMode));
  }

  /// Zapisuje podane wartości (te przekazane jako `null` pozostają bez zmian),
  /// utrwala je w [SharedPreferences] i powiadamia słuchaczy.
  Future<void> update({
    String? baseUrl,
    String? chatModel,
    String? embeddingModel,
    String? visionModel,
    ThemeMode? themeMode,
  }) async {
    if (baseUrl != null) {
      _baseUrl = normalizeUrl(baseUrl);
      await _prefs.setString(_kBaseUrl, _baseUrl);
    }
    if (themeMode != null) {
      _themeMode = themeMode;
      await _prefs.setString(_kThemeMode, _themeModeToString(themeMode));
    }
    if (chatModel != null) {
      _chatModel = chatModel.trim();
      await _prefs.setString(_kChatModel, _chatModel);
    }
    if (embeddingModel != null) {
      _embeddingModel = embeddingModel.trim();
      await _prefs.setString(_kEmbeddingModel, _embeddingModel);
    }
    if (visionModel != null) {
      _visionModel = visionModel.trim();
      await _prefs.setString(_kVisionModel, _visionModel);
    }
    notifyListeners();
  }

  /// Przywraca ustawienia fabryczne (domyślne wartości z [AppConstants]).
  Future<void> resetToDefaults() => update(
        baseUrl: AppConstants.defaultOllamaBaseUrl,
        chatModel: AppConstants.chatModel,
        embeddingModel: AppConstants.embeddingModel,
        visionModel: AppConstants.visionModel,
        themeMode: ThemeMode.system,
      );

  static ThemeMode _themeModeFromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Przycina białe znaki i usuwa końcowe ukośniki, by uniknąć podwójnych `//`
  /// przy sklejaniu ścieżek API (`$baseUrl/api/...`).
  static String normalizeUrl(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }
}
