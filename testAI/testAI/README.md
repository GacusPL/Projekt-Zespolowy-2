# 📚 LekturAI

> **Inteligentny asystent nauki oparty o lokalny LLM (Ollama).**
> Wgrywasz materiały (PDF/zdjęcia notatek), a aplikacja pozwala Ci czatować z ich
> treścią, generuje fiszki z algorytmem powtórek SM-2 i tworzy quizy do
> sprawdzenia wiedzy — wszystko działa **lokalnie**, bez wysyłania danych do
> zewnętrznych usług.

---

## ✨ Funkcjonalności

| Moduł | Co robi |
|---|---|
| 🗂️ **Przedmioty** | Organizacja materiałów według przedmiotów akademickich z kolorowymi kartami. |
| 📄 **Materiały** | Wgrywanie plików PDF (parser **Syncfusion**), zdjęć notatek (multimodalny model **llava** jako "OCR z AI" — radzi sobie też z pismem odręcznym) i tekstu. |
| 💬 **Czat RAG** | Asystent odpowiadający na podstawie Twoich materiałów. Pełen **streaming** w stylu SSE, cytowanie źródeł, historia rozmów per przedmiot. |
| 🎴 **Fiszki SM-2** | Generowane przez LLM lub dodawane ręcznie. Algorytm **SuperMemo-2** (ten sam co w Anki) pilnuje terminów powtórek. |
| 🧪 **Quizy** | Pytania jednokrotnego wyboru (A/B/C/D) z wyjaśnieniem poprawnej odpowiedzi. Wynik zapisywany w statystykach. |
| 📊 **Statystyki** | Krzywa wyników quizów w czasie, postęp utrwalenia fiszek (`fl_chart`). |

---

## 🧠 Jak to działa — architektura RAG

```
PDF/zdjęcie/tekst
       │
       ▼
┌────────────────────┐
│  Ekstrakcja tekstu │  (Syncfusion PDF / llava vision / UTF-8)
└─────────┬──────────┘
          ▼
┌────────────────────┐
│      Chunking      │  (500 słów + 50 słów nakładania)
└─────────┬──────────┘
          ▼
┌────────────────────┐
│ nomic-embed-text   │  (768D embedding każdego chunka)
└─────────┬──────────┘
          ▼
┌────────────────────┐
│ SQLite (BLOB)      │  ← indeks wektorowy w pamięci
└─────────┬──────────┘
          │   pytanie studenta → embedding → cosine similarity
          ▼
┌────────────────────┐
│  Top-K chunków     │  (próg 0.25, retrieval = 5 fragmentów)
└─────────┬──────────┘
          ▼
┌────────────────────┐
│  Prompt + llama3.1 │  → odpowiedź streamowana (NDJSON)
└────────────────────┘
```

**Dlaczego SQLite a nie Postgres + pgvector?** Aplikacja jest 100% offline,
a dla typowej biblioteki studenta (kilkanaście dokumentów, kilka tysięcy
chunków) cosine similarity liczony w pamięci w Dart jest wystarczająco szybki
i nie wymaga uruchamiania bazy danych obok aplikacji.

---

## 🛠️ Stos technologiczny

| Warstwa | Technologia |
|---|---|
| Framework | **Flutter 3.22+** (Material 3) |
| Język | Dart |
| State management | **flutter_bloc** + `equatable` |
| DI | `get_it` |
| Error handling | `dartz` (`Either<Failure, T>`) |
| LLM | **Ollama** (lokalny serwer: llama3.1, nomic-embed-text, llava) |
| Baza danych | **SQLite** (`sqflite` + `sqflite_common_ffi` na desktopie) |
| PDF | **`syncfusion_flutter_pdf`** (wymóg projektowy) |
| Wykresy | `fl_chart` |
| Markdown | `flutter_markdown` |
| File picker | `file_picker` |

---

## 📦 Architektura — Clean Architecture (per feature)

```
lib/
├── core/                     # Wspólne — stałe, błędy, sieć, motyw, DI
│   ├── constants/
│   ├── di/                   # GetIt setup
│   ├── errors/               # Failure (domain) + Exception (data)
│   ├── network/              # OllamaClient
│   ├── theme/
│   └── utils/                # vector_math, text_chunker, json_extractor
│
├── shared/
│   ├── database/             # DatabaseHelper (singleton)
│   └── widgets/              # OllamaStatusIndicator, EmptyState, ErrorView
│
└── features/
    ├── subjects/             # Przedmioty
    ├── documents/            # PDF/obrazy/tekst → chunki + embeddingi
    ├── chat/                 # RAG ze streamingiem
    ├── flashcards/           # SM-2 spaced repetition
    ├── quiz/                 # Quizy ABCD
    └── statistics/           # Wykresy postępów
        ├── domain/           # entities, repositories (interfejsy), usecases
        ├── data/             # models, datasources, repositories (impl)
        └── presentation/     # pages, widgets, BLoC
```

Każda funkcjonalność trzyma się dyscypliny **domain → data → presentation**.
BLoC zależy tylko od UseCase'ów, nie zna repozytoriów. Repozytoria zwracają
`Either<Failure, T>`, więc obsługa błędów jest jawna i wymuszana przez typ.

---

## 🚀 Instalacja i uruchomienie

### 1. Wymagania wstępne

- **Flutter SDK** ≥ 3.22 ([instalacja](https://docs.flutter.dev/get-started/install))
- **Ollama** ([ollama.com/download](https://ollama.com/download))
- Min. **8 GB RAM** (modele zajmują pamięć)
- Wolnego miejsca na dysku: ~10 GB (modele Ollama)

### 2. Pobierz wymagane modele Ollama

```bash
ollama pull llama3.1            # Główny model czatu (~4.7 GB)
ollama pull nomic-embed-text    # Embeddingi 768D (~270 MB)
ollama pull llava               # Model wizyjny do zdjęć notatek (~4.7 GB)
```

### 3. Upewnij się, że Ollama działa

```bash
ollama serve
# Sprawdź:
curl http://localhost:11434/api/tags
```

W aplikacji w prawym górnym rogu jest plakietka pokazująca status połączenia
(zielona "Ollama online" = wszystko gra).

### 4. Wygeneruj pliki platformowe i uruchom

W katalogu projektu:

```bash
# Wygeneruj foldery android/ios/linux/windows/macos itd.
flutter create . --platforms=windows,linux,macos,android

# Pobierz zależności
flutter pub get

# Uruchom (wybierz docelową platformę)
flutter run -d windows     # Windows
flutter run -d linux       # Linux
flutter run -d macos       # macOS
flutter run -d <device-id> # Android (zobacz `flutter devices`)
```

> 💡 **Uwaga dla Android/iOS:** Ollama domyślnie nasłuchuje na `localhost`. Aby
> aplikacja na telefonie połączyła się z Ollama działającą na komputerze w tej
> samej sieci, uruchom:
> ```bash
> OLLAMA_HOST=0.0.0.0 ollama serve
> ```
> a w `lib/core/constants/app_constants.dart` zmień `defaultOllamaBaseUrl` na
> IP komputera w sieci LAN (np. `http://192.168.1.42:11434`).

---

## 🎮 Jak korzystać

1. **Utwórz przedmiot** (np. „Algebra liniowa") — wybierz kolor karty.
2. **Wgraj materiały** w zakładce *Materiały* — PDF, zdjęcia notatek (PNG/JPG/WebP)
   lub pliki tekstowe. Aplikacja pokazuje progres: ekstrakcja → chunking →
   embedding każdego fragmentu.
3. **Zacznij rozmowę** w zakładce *Czat (RAG)* — kliknij „Nowa rozmowa" i zadaj
   pytanie. Asystent przeszuka materiały, pokaże źródła i streamuje odpowiedź
   w czasie rzeczywistym (markdown).
4. **Wygeneruj fiszki** w zakładce *Fiszki* — wybierz 5/10/20/30 sztuk.
   LLM przeczyta materiały i utworzy fiszki Q&A. Sesja powtórek prowadzi Cię
   przez fiszki należne na dzisiaj, a algorytm **SM-2** decyduje kiedy każda
   fiszka pojawi się ponownie (na podstawie Twojej oceny: *Powtórz / Trudne /
   OK / Łatwe*).
5. **Wygeneruj quiz** w zakładce *Quizy* — 5/10/15/20 pytań A/B/C/D z wyjaśnieniami.
6. **Zobacz statystyki** w zakładce *Statystyki* — wykres wyników quizów w czasie
   i postęp utrwalenia fiszek.

---

## 🧪 Algorytm SM-2 — implementacja

Klasyczny algorytm SuperMemo-2 (Piotr Woźniak, 1985). W skrócie:

```
q = 0..5 (ocena studenta: 0 = nie pamiętam, 5 = łatwo)

Jeśli q < 3:
    interval = 1 dzień, repetitions = 0
Wpp:
    repetitions += 1
    if repetitions == 1: interval = 1
    elif repetitions == 2: interval = 6
    else:                  interval = round(interval * EF)

    EF = max(1.3, EF + (0.1 - (5-q)*(0.08 + (5-q)*0.02)))

dueDate = now + interval dni
```

Implementacja w `lib/features/flashcards/domain/usecases/sm2_algorithm.dart`.

---

## 🔒 Prywatność

**Wszystko działa lokalnie.** Materiały, embeddingi, rozmowy, fiszki, quizy —
nic nie opuszcza Twojego urządzenia. Ollama działa lokalnie, SQLite jest lokalny,
nie ma żadnego serwera w chmurze.

---

## 🐛 Częste problemy

**"Ollama offline"**
- Sprawdź czy `ollama serve` działa: `curl http://localhost:11434/api/tags`
- Sprawdź czy zostały pobrane wymagane modele: `ollama list`

**"Nieoczekiwany wymiar embeddingu"**
- Aplikacja oczekuje 768D embeddingów z `nomic-embed-text`. Jeśli pobrałeś inny
  model do embeddingów, edytuj `AppConstants.embeddingModel` i
  `AppConstants.embeddingDimension`.

**"Model zwrócił niepoprawny JSON dla fiszek/quizu"**
- Czasem mały model halucynuje formatowanie. Spróbuj jeszcze raz lub użyj
  większego modelu (np. `llama3.1:70b` zamiast `llama3.1`).

**Powolny upload PDF**
- Czas zależy od liczby chunków × czas embeddingu (~50–200 ms/chunk na CPU).
  Dla 100-stronicowego PDF spodziewaj się 1–3 minut.

---

## 👥 Autorzy

Projekt zespołowy zaimplementowany w ramach przedmiotu projektowego.

- Kamil Przychodzeń (21297)
- Kacper Szponar (21306)
- Kaja Thiel (21310)

---

## 📄 Licencja

Projekt edukacyjny — wykorzystanie na potrzeby akademickie.
