# Projekt-Zespolowy-2

## 🤖 Prywatny Chatbot RAG (Retrieval-Augmented Generation)

Nowoczesna aplikacja webowa typu **workspace**, umożliwiająca wgrywanie dokumentów (PDF, MD, TXT), które stanowią bazę wiedzy dla lokalnego modelu AI. System przetwarza dokumenty na embeddingi wektorowe, a następnie wykorzystuje je do udzielania precyzyjnych odpowiedzi w oparciu o przesłane materiały — bez wysyłania danych do zewnętrznych serwisów.

---

## 🚀 Technologie

Projekt wykorzystuje nowoczesny stos technologiczny zapewniający wydajność, prywatność i skalowalność:

| Warstwa            | Technologia                                 |
| ------------------ | ------------------------------------------- |
| **Framework**      | Next.js 15 (App Router)                     |
| **Język**          | TypeScript                                  |
| **Stylizacja**     | Tailwind CSS + shadcn/ui                    |
| **Baza danych**    | Supabase (PostgreSQL + pgvector)            |
| **Embeddingi**     | Ollama — `nomic-embed-text`                 |
| **Model LLM**      | Ollama — `llama3` (lokalne uruchomienie)    |
| **Parsowanie PDF** | pdf2json                                    |

---

## ✨ Funkcje systemu

### 📂 Panel Bazy Wiedzy (lewy panel)

- **Upload dokumentów:** Wgrywanie plików PDF, MD i TXT przez kliknięcie lub drag-and-drop.
- **Przetwarzanie tekstu:** Automatyczna ekstrakcja treści z dokumentów.
- **Chunking semantyczny:** Podział tekstu na fragmenty (~500 słów z 50-słownym nakładaniem się).
- **Generowanie embeddingów:** Każdy fragment jest wektoryzowany za pomocą modelu `nomic-embed-text` (Ollama).
- **Zapis do bazy wektorowej:** Metadane dokumentu + chunki z embeddingami trafiają do Supabase (pgvector).
- **Lista dokumentów:** Podgląd wszystkich przesłanych plików wraz z ich rozmiarem.

### 💬 Panel Czatu (prawy panel)

- **Wyszukiwanie wektorowe:** Pytanie użytkownika jest zamieniane na embedding i porównywane z bazą chunków (cosine similarity).
- **Kontekst RAG:** System pobiera 5 najbardziej pasujących fragmentów i zasila nimi prompt do modelu LLM.
- **Streaming odpowiedzi:** Odpowiedź AI wyświetla się progresywnie (token po tokenie) w czasie rzeczywistym.
- **Odpowiedzi po polsku:** Model odpowiada w języku polskim na podstawie dostarczonych dokumentów.
- **Obsługa błędów:** Informowanie o problemach z Ollama lub Supabase.

### 🌙 Interfejs

- **Ciemny motyw:** Przełączanie między jasnym a ciemnym motywem (domyślnie wykrywa preferencje systemowe).
- **Minimalistyczny design:** Czytelny, dwupanelowy układ workspace.

---

## 🛠️ Struktura Projektu

```
/src
├── /app                        — Główna logika routingu Next.js
│   ├── /api/upload/route.ts    — Endpoint POST do wgrywania i przetwarzania dokumentów
│   ├── /api/chat/route.ts      — Endpoint POST do czatu RAG ze streamingiem
│   ├── page.tsx                — Główny dashboard (UI)
│   ├── layout.tsx              — Layout aplikacji
│   └── globals.css             — Globalne style Tailwind
├── /components/ui              — Komponenty shadcn/ui (Button, Card, Input, ScrollArea)
├── /lib
│   ├── supabase.ts             — Konfiguracja klienta Supabase
│   ├── document-processing.ts  — Ekstrakcja tekstu, chunking, embeddingi (Ollama)
│   └── utils.ts                — Utility functions (cn)
/supabase-setup.sql             — Skrypt SQL do inicjalizacji bazy danych
/.env.local                     — Zmienne środowiskowe (Supabase URL + klucz)
```

---

## ⚙️ Instalacja i uruchomienie

### Wymagania wstępne

- **Node.js** >= 18
- **Ollama** zainstalowana lokalnie z modelami:
  - `ollama pull nomic-embed-text`
  - `ollama pull llama3`
- **Supabase** — konto z projektem (darmowy plan wystarczy)

### 1. Klonowanie repozytorium

```bash
git clone https://github.com/<twoj-username>/Projekt-Zespolowy-2.git
cd Projekt-Zespolowy-2
```

### 2. Instalacja zależności

```bash
npm install
```

### 3. Konfiguracja zmiennych środowiskowych

Uzupełnij plik `.env.local` danymi z panelu Supabase (Settings → API):

```env
NEXT_PUBLIC_SUPABASE_URL="https://twoj-projekt.supabase.co"
NEXT_PUBLIC_SUPABASE_ANON_KEY="twoj-anon-key-z-supabase"
```

### 4. Inicjalizacja bazy danych

Skopiuj zawartość pliku `supabase-setup.sql` i wykonaj go w **SQL Editor** w panelu Supabase. Skrypt utworzy:

- Rozszerzenie `pgvector`
- Tabelę `documents`
- Tabelę `document_chunks` (z kolumną wektorową `vector(768)`)
- Indeks HNSW do szybkiego wyszukiwania
- Funkcję RPC `match_document_chunks`
- Polityki RLS (open access dla MVP)

### 5. Uruchomienie Ollama

```bash
ollama serve
```

### 6. Uruchomienie aplikacji

```bash
npm run dev
```

Aplikacja będzie dostępna pod adresem: [http://localhost:3000](http://localhost:3000)

---

## 📐 Architektura RAG

```
┌─────────────┐     PDF/MD/TXT      ┌──────────────────┐
│   Użytkownik │ ──────────────────► │  /api/upload      │
└─────────────┘                      │  ┌──────────────┐ │
                                     │  │ Ekstrakcja   │ │
                                     │  │ tekstu       │ │
                                     │  ├──────────────┤ │
                                     │  │ Chunking     │ │
                                     │  │ (500 słów)   │ │
                                     │  ├──────────────┤ │
                                     │  │ Ollama       │ │
                                     │  │ (embedding)  │ │
                                     │  └──────┬───────┘ │
                                     └─────────┼─────────┘
                                               ▼
                                     ┌──────────────────┐
                                     │   Supabase       │
                                     │   (pgvector)     │
                                     └────────┬─────────┘
                                              ▲
┌─────────────┐     Pytanie          ┌────────┴─────────┐
│   Użytkownik │ ──────────────────► │  /api/chat        │
└─────────────┘                      │  ┌──────────────┐ │
       ▲                             │  │ Embedding    │ │
       │                             │  │ pytania      │ │
       │    Streaming                │  ├──────────────┤ │
       │    odpowiedzi               │  │ Wyszukiwanie │ │
       │                             │  │ wektorowe    │ │
       │                             │  ├──────────────┤ │
       └─────────────────────────────│  │ LLM (llama3) │ │
                                     │  │ + kontekst   │ │
                                     │  └──────────────┘ │
                                     └──────────────────┘
```

---

## 👥 Autorzy

- Kamil Przychodzeń 21297
- Kacper Szponar 21306
- Kaja Thiel 21310
