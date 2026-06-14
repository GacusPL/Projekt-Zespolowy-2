import '../../../documents/domain/entities/document_chunk.dart';
import '../../domain/entities/conversation.dart';

/// Centralne miejsce gdzie powstają wszystkie prompty wysyłane do modelu.
/// Wszystkie odpowiedzi muszą być po polsku.
class PromptBuilder {
  PromptBuilder._();

  static const String ragSystemPrompt = '''
Jesteś LekturAI – akademickim asystentem nauki. Twoja rola:
1. Odpowiadaj WYŁĄCZNIE w języku polskim.
2. Bazuj WYŁĄCZNIE na dostarczonym kontekście z materiałów studenta.
3. Gdy w kontekście brakuje danych potrzebnych do odpowiedzi, powiedz wprost:
   „Na podstawie udostępnionych materiałów nie mogę odpowiedzieć na to pytanie."
   Nie wymyślaj informacji.
4. Łącz informacje z różnych fragmentów, jeśli są komplementarne.
5. Tłumacz w sposób klarowny – tak, by student mógł się z odpowiedzi nauczyć.
6. Formatuj odpowiedzi z użyciem Markdown (nagłówki, listy, **pogrubienie**).
''';

  static String buildRagUserPrompt({
    required String userMessage,
    required List<DocumentChunk> chunks,
    required List<Message> history,
  }) {
    final ctxBuf = StringBuffer();
    if (chunks.isEmpty) {
      ctxBuf.writeln('(brak pasujących fragmentów w bazie wiedzy)');
    } else {
      for (int i = 0; i < chunks.length; i++) {
        final c = chunks[i];
        ctxBuf.writeln('### Fragment ${i + 1}'
            '${c.documentFilename != null ? " (źródło: ${c.documentFilename})" : ""}'
            '${c.similarity != null ? " — podobieństwo: ${c.similarity!.toStringAsFixed(2)}" : ""}');
        ctxBuf.writeln(c.content);
        ctxBuf.writeln();
      }
    }

    final histBuf = StringBuffer();
    if (history.isNotEmpty) {
      histBuf.writeln('# Wcześniejsza rozmowa');
      // Bierzemy maksymalnie ostatnie 6 wiadomości, by nie rozwlekać promptu.
      final tail = history.length > 6
          ? history.sublist(history.length - 6)
          : history;
      for (final m in tail) {
        final prefix = m.role == MessageRole.user ? 'Student' : 'LekturAI';
        histBuf.writeln('$prefix: ${m.content}');
      }
      histBuf.writeln();
    }

    return '''
# Kontekst z materiałów studenta
$ctxBuf

$histBuf
# Pytanie studenta
$userMessage

# Odpowiedź LekturAI (po polsku, w formacie Markdown):
''';
  }

  // ----- Generowanie fiszek -----
  static const String flashcardsSystemPrompt = '''
Jesteś LekturAI – generujesz fiszki do nauki dla studenta.
Tworzysz krótkie, konkretne fiszki w formie pytanie-odpowiedź,
pokrywające najważniejsze pojęcia z materiału.
Odpowiedzi MUSZĄ BYĆ w języku polskim.
ZAWSZE zwracaj WYŁĄCZNIE poprawny JSON, bez komentarzy ani wstępu.
''';

  static String buildFlashcardsPrompt({
    required String materialText,
    required int count,
  }) =>
      '''
Na podstawie poniższego materiału przygotuj $count fiszek do nauki.
Każda fiszka to obiekt z polami "question" i "answer".

Wymagania:
- Pytania powinny sprawdzać zrozumienie kluczowych pojęć/faktów.
- Odpowiedzi krótkie i konkretne (1–3 zdania).
- Unikaj duplikatów i banalnych pytań.

Zwróć WYŁĄCZNIE JSON w formacie:
{
  "cards": [
    {"question": "...", "answer": "..."},
    ...
  ]
}

Materiał:
"""
$materialText
"""
''';

  // ----- Generowanie quizu -----
  static const String quizSystemPrompt = '''
Jesteś LekturAI – generujesz quiz wielokrotnego wyboru po polsku.
Każde pytanie ma dokładnie 4 odpowiedzi (A,B,C,D), z czego JEDNA jest poprawna.
Dla każdego pytania dodajesz krótkie wyjaśnienie poprawnej odpowiedzi.
ZAWSZE zwracaj WYŁĄCZNIE poprawny JSON, bez komentarzy ani wstępu.
''';

  static String buildQuizPrompt({
    required String materialText,
    required int count,
  }) =>
      '''
Na podstawie poniższego materiału przygotuj $count pytań quizowych.
Format wyniku:

{
  "questions": [
    {
      "question": "Treść pytania?",
      "options": ["A...", "B...", "C...", "D..."],
      "correct_index": 0,
      "explanation": "Krótkie wyjaśnienie dlaczego ta odpowiedź jest poprawna."
    },
    ...
  ]
}

Wymagania:
- Cztery opcje, indeksy 0..3.
- Tylko jedna poprawna.
- Dystraktory (błędne opcje) muszą być realistyczne, nie absurdalne.
- Pytania pokrywają różne fragmenty materiału.

Materiał:
"""
$materialText
"""
''';

  // ----- Quiz mode (AI pyta studenta) -----
  static const String examinerSystemPrompt = '''
Jesteś LekturAI w trybie egzaminatora. Twoje zadanie:
1. Zadawaj studentowi pojedyncze pytania otwarte z materiału.
2. Po odpowiedzi studenta oceń ją: poprawna / częściowo / błędna, i wyjaśnij.
3. Następnie zadaj kolejne pytanie z innego fragmentu materiału.
4. Bądź wymagający ale konstruktywny — celem jest nauka.
Wszystko po polsku.
''';
}
