import 'dart:io' show Platform;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Lokalna baza SQLite — jedyne źródło prawdy dla:
/// przedmiotów, dokumentów, chunków + embeddingów, konwersacji, fiszek i quizów.
///
/// Embeddingi są przechowywane jako BLOB (`Float32List`), a wyszukiwanie
/// wektorowe (cosine similarity) jest wykonywane w pamięci aplikacji.
/// Dla typowej biblioteki studenta (kilkanaście dokumentów, kilka tysięcy
/// chunków) jest to wystarczająco szybkie i nie wymaga zewnętrznych usług.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _dbName = 'lekturai.db';
  static const int _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    // Na desktopie (Linux/Windows/macOS) sqflite wymaga inicjalizacji FFI.
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Przedmioty (np. "Algebra liniowa", "Sieci komputerowe")
    await db.execute('''
      CREATE TABLE subjects (
        id           TEXT PRIMARY KEY,
        name         TEXT NOT NULL,
        description  TEXT,
        color_value  INTEGER NOT NULL,
        created_at   INTEGER NOT NULL
      )
    ''');

    // Dokumenty należące do przedmiotu
    await db.execute('''
      CREATE TABLE documents (
        id           TEXT PRIMARY KEY,
        subject_id   TEXT NOT NULL,
        filename     TEXT NOT NULL,
        file_type    TEXT NOT NULL,   -- 'pdf' | 'image' | 'text'
        chunk_count  INTEGER NOT NULL DEFAULT 0,
        uploaded_at  INTEGER NOT NULL,
        FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_documents_subject ON documents(subject_id)');

    // Chunki z embeddingami — serce indeksu RAG
    await db.execute('''
      CREATE TABLE chunks (
        id            TEXT PRIMARY KEY,
        document_id   TEXT NOT NULL,
        subject_id    TEXT NOT NULL,
        chunk_index   INTEGER NOT NULL,
        content       TEXT NOT NULL,
        embedding     BLOB NOT NULL,
        FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE,
        FOREIGN KEY (subject_id)  REFERENCES subjects(id)  ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_chunks_subject ON chunks(subject_id)');
    await db.execute('CREATE INDEX idx_chunks_document ON chunks(document_id)');

    // Konwersacje per przedmiot
    await db.execute('''
      CREATE TABLE conversations (
        id           TEXT PRIMARY KEY,
        subject_id   TEXT NOT NULL,
        title        TEXT NOT NULL,
        created_at   INTEGER NOT NULL,
        updated_at   INTEGER NOT NULL,
        FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_conv_subject ON conversations(subject_id)');

    // Wiadomości w konwersacji
    await db.execute('''
      CREATE TABLE messages (
        id               TEXT PRIMARY KEY,
        conversation_id  TEXT NOT NULL,
        role             TEXT NOT NULL,   -- 'user' | 'assistant'
        content          TEXT NOT NULL,
        sources          TEXT,            -- JSON z cytowanymi chunkami
        created_at       INTEGER NOT NULL,
        FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_msg_conv ON messages(conversation_id)');

    // Fiszki + algorytm SM-2 (spaced repetition)
    await db.execute('''
      CREATE TABLE flashcards (
        id              TEXT PRIMARY KEY,
        subject_id      TEXT NOT NULL,
        question        TEXT NOT NULL,
        answer          TEXT NOT NULL,
        created_at      INTEGER NOT NULL,
        ease_factor     REAL NOT NULL DEFAULT 2.5,
        interval_days   INTEGER NOT NULL DEFAULT 0,
        repetitions     INTEGER NOT NULL DEFAULT 0,
        due_date        INTEGER NOT NULL,
        last_reviewed   INTEGER,
        FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_fc_subject ON flashcards(subject_id)');
    await db.execute('CREATE INDEX idx_fc_due ON flashcards(due_date)');

    // Quizy
    await db.execute('''
      CREATE TABLE quizzes (
        id           TEXT PRIMARY KEY,
        subject_id   TEXT NOT NULL,
        title        TEXT NOT NULL,
        created_at   INTEGER NOT NULL,
        FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE quiz_questions (
        id              TEXT PRIMARY KEY,
        quiz_id         TEXT NOT NULL,
        question        TEXT NOT NULL,
        options_json    TEXT NOT NULL,  -- JSON array
        correct_index   INTEGER NOT NULL,
        explanation     TEXT,
        FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
      )
    ''');

    // Wyniki podejść do quizu (do statystyk)
    await db.execute('''
      CREATE TABLE quiz_attempts (
        id              TEXT PRIMARY KEY,
        quiz_id         TEXT NOT NULL,
        subject_id      TEXT NOT NULL,
        score           INTEGER NOT NULL,
        total_questions INTEGER NOT NULL,
        completed_at    INTEGER NOT NULL,
        FOREIGN KEY (quiz_id)    REFERENCES quizzes(id)   ON DELETE CASCADE,
        FOREIGN KEY (subject_id) REFERENCES subjects(id)  ON DELETE CASCADE
      )
    ''');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
