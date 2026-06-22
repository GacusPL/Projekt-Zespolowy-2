import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/ollama_client.dart';
import '../../../../core/utils/json_extractor.dart';
import '../../../../shared/database/database_helper.dart';
import '../../../chat/data/datasources/prompt_builder.dart';
import '../../../documents/domain/repositories/documents_repository.dart';
import '../../domain/entities/flashcard.dart';
import '../models/flashcard_model.dart';

abstract class FlashcardsDataSource {
  Future<List<FlashcardModel>> getBySubject(String subjectId);
  Future<List<FlashcardModel>> getDueForReview(String subjectId);
  Future<FlashcardModel> create({
    required String subjectId,
    required String question,
    required String answer,
  });
  Future<FlashcardModel> update(Flashcard card);
  Future<void> delete(String id);
  Future<List<FlashcardModel>> generateFromMaterials({
    required String subjectId,
    required int count,
  });
}

class FlashcardsDataSourceImpl implements FlashcardsDataSource {
  final DatabaseHelper _db;
  final OllamaClient _ollama;
  final DocumentsRepository _docs;
  final Uuid _uuid;

  FlashcardsDataSourceImpl({
    required DatabaseHelper dbHelper,
    required OllamaClient ollamaClient,
    required DocumentsRepository documentsRepository,
    Uuid? uuid,
  })  : _db = dbHelper,
        _ollama = ollamaClient,
        _docs = documentsRepository,
        _uuid = uuid ?? const Uuid();

  // ------------------------------------------------------------- reads

  @override
  Future<List<FlashcardModel>> getBySubject(String subjectId) async {
    final db = await _db.database;
    final rows = await db.query(
      'flashcards',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'created_at DESC',
    );
    return rows.map(FlashcardModel.fromMap).toList();
  }

  @override
  Future<List<FlashcardModel>> getDueForReview(String subjectId) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = await db.query(
      'flashcards',
      where: 'subject_id = ? AND due_date <= ?',
      whereArgs: [subjectId, now],
      orderBy: 'due_date ASC',
    );
    return rows.map(FlashcardModel.fromMap).toList();
  }

  // ----------------------------------------------------------- writes

  @override
  Future<FlashcardModel> create({
    required String subjectId,
    required String question,
    required String answer,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();
    final card = FlashcardModel(
      id: _uuid.v4(),
      subjectId: subjectId,
      question: question,
      answer: answer,
      createdAt: now,
      dueDate: now, // nowa fiszka - od razu do nauki
    );
    await db.insert('flashcards', card.toMap());
    return card;
  }

  @override
  Future<FlashcardModel> update(Flashcard card) async {
    final db = await _db.database;
    final m = FlashcardModel.fromEntity(card);
    await db.update(
      'flashcards',
      m.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
    return m;
  }

  @override
  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('flashcards', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------------------------------------------- LLM generation

  @override
  Future<List<FlashcardModel>> generateFromMaterials({
    required String subjectId,
    required int count,
  }) async {
    // 1. Wczytaj wszystkie chunki przedmiotu i połącz w jeden korpus
    final chunksRes = await _docs.getAllChunksForSubject(subjectId);
    final chunks = chunksRes.fold((f) => null, (l) => l);
    if (chunks == null || chunks.isEmpty) {
      throw FileProcessingException(
        'Brak materiałów. Najpierw wgraj jakiś dokument do tego przedmiotu.',
      );
    }

    // Ograniczamy długość kontekstu - by zmieścić się w oknie modelu.
    // ~ 12 tysięcy znaków = ok. 2-3k tokenów wystarczy dla małych modeli.
    final buf = StringBuffer();
    for (final c in chunks) {
      if (buf.length + c.content.length > 12000) break;
      buf.writeln(c.content);
      buf.writeln();
    }

    // 2. Wywołaj LLM
    final raw = await _ollama.generateOnce(
      prompt: PromptBuilder.buildFlashcardsPrompt(
        materialText: buf.toString(),
        count: count,
      ),
      system: PromptBuilder.flashcardsSystemPrompt,
      temperature: 0.4,
    );

    // 3. Sparsuj JSON
    final json = JsonExtractor.tryExtractObject(raw);
    if (json == null || json['cards'] is! List) {
      throw OllamaException(
        'Model zwrócił niepoprawny JSON dla fiszek.\n--- Surowy output ---\n$raw',
      );
    }

    // 4. Utwórz fiszki w bazie
    final db = await _db.database;
    final batch = db.batch();
    final now = DateTime.now();
    final out = <FlashcardModel>[];

    for (final item in (json['cards'] as List)) {
      if (item is! Map) continue;
      final q = (item['question'] as String?)?.trim() ?? '';
      final a = (item['answer'] as String?)?.trim() ?? '';
      if (q.isEmpty || a.isEmpty) continue;
      final card = FlashcardModel(
        id: _uuid.v4(),
        subjectId: subjectId,
        question: q,
        answer: a,
        createdAt: now,
        dueDate: now,
      );
      batch.insert('flashcards', card.toMap());
      out.add(card);
    }
    await batch.commit(noResult: true);
    return out;
  }
}
