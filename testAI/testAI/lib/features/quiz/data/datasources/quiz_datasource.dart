import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/ollama_client.dart';
import '../../../../core/utils/json_extractor.dart';
import '../../../../shared/database/database_helper.dart';
import '../../../chat/data/datasources/prompt_builder.dart';
import '../../../documents/domain/repositories/documents_repository.dart';
import '../models/quiz_models.dart';

abstract class QuizDataSource {
  Future<List<QuizModel>> getQuizzesBySubject(String subjectId);
  Future<QuizModel> getQuizById(String id);
  Future<QuizModel> generateQuiz({
    required String subjectId,
    required String title,
    required int questionCount,
  });
  Future<void> deleteQuiz(String id);
  Future<QuizAttemptModel> saveAttempt({
    required String quizId,
    required String subjectId,
    required int score,
    required int totalQuestions,
  });
  Future<List<QuizAttemptModel>> getAttemptsBySubject(String subjectId);
}

class QuizDataSourceImpl implements QuizDataSource {
  final DatabaseHelper _db;
  final OllamaClient _ollama;
  final DocumentsRepository _docs;
  final Uuid _uuid;

  QuizDataSourceImpl({
    required DatabaseHelper dbHelper,
    required OllamaClient ollamaClient,
    required DocumentsRepository documentsRepository,
    Uuid? uuid,
  })  : _db = dbHelper,
        _ollama = ollamaClient,
        _docs = documentsRepository,
        _uuid = uuid ?? const Uuid();

  // ---------------------------------------------------------------- reads

  @override
  Future<List<QuizModel>> getQuizzesBySubject(String subjectId) async {
    final db = await _db.database;
    final rows = await db.query(
      'quizzes',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'created_at DESC',
    );
    // Dla widoku listy nie wczytujemy pytań — zrobimy to lazy w getQuizById.
    return rows.map((m) => QuizModel.fromMap(m)).toList();
  }

  @override
  Future<QuizModel> getQuizById(String id) async {
    final db = await _db.database;
    final qRows = await db.query('quizzes', where: 'id = ?', whereArgs: [id]);
    if (qRows.isEmpty) {
      throw DatabaseException('Quiz nie istnieje.');
    }
    final questRows = await db.query(
      'quiz_questions',
      where: 'quiz_id = ?',
      whereArgs: [id],
    );
    final questions = questRows.map(QuizQuestionModel.fromMap).toList();
    return QuizModel.fromMap(qRows.first, questions: questions);
  }

  // ---------------------------------------------------------------- delete

  @override
  Future<void> deleteQuiz(String id) async {
    final db = await _db.database;
    await db.delete('quizzes', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------------------------------------------------------- attempts

  @override
  Future<QuizAttemptModel> saveAttempt({
    required String quizId,
    required String subjectId,
    required int score,
    required int totalQuestions,
  }) async {
    final db = await _db.database;
    final attempt = QuizAttemptModel(
      id: _uuid.v4(),
      quizId: quizId,
      subjectId: subjectId,
      score: score,
      totalQuestions: totalQuestions,
      completedAt: DateTime.now(),
    );
    await db.insert('quiz_attempts', attempt.toMap());
    return attempt;
  }

  @override
  Future<List<QuizAttemptModel>> getAttemptsBySubject(String subjectId) async {
    final db = await _db.database;
    final rows = await db.query(
      'quiz_attempts',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'completed_at ASC',
    );
    return rows.map(QuizAttemptModel.fromMap).toList();
  }

  // --------------------------------------------------------------- generate

  @override
  Future<QuizModel> generateQuiz({
    required String subjectId,
    required String title,
    required int questionCount,
  }) async {
    // 1. Zbierz materiał
    final chunksRes = await _docs.getAllChunksForSubject(subjectId);
    final chunks = chunksRes.fold((f) => null, (l) => l);
    if (chunks == null || chunks.isEmpty) {
      throw FileProcessingException(
        'Brak materiałów. Najpierw wgraj jakiś dokument do tego przedmiotu.',
      );
    }

    final buf = StringBuffer();
    for (final c in chunks) {
      if (buf.length + c.content.length > 12000) break;
      buf.writeln(c.content);
      buf.writeln();
    }

    // 2. LLM
    final raw = await _ollama.generateOnce(
      prompt: PromptBuilder.buildQuizPrompt(
        materialText: buf.toString(),
        count: questionCount,
      ),
      system: PromptBuilder.quizSystemPrompt,
      temperature: 0.4,
    );

    // 3. Parsowanie
    final json = JsonExtractor.tryExtractObject(raw);
    if (json == null || json['questions'] is! List) {
      throw OllamaException(
        'Model zwrócił niepoprawny JSON dla quizu.\n--- Surowy output ---\n$raw',
      );
    }

    // 4. Zapis
    final db = await _db.database;
    final now = DateTime.now();
    final quizId = _uuid.v4();
    final quizModel = QuizModel(
      id: quizId,
      subjectId: subjectId,
      title: title.trim().isEmpty ? 'Quiz ${now.toIso8601String()}' : title,
      createdAt: now,
    );

    final batch = db.batch();
    batch.insert('quizzes', quizModel.toMap());

    final questionModels = <QuizQuestionModel>[];
    for (final item in (json['questions'] as List)) {
      if (item is! Map) continue;
      final q = (item['question'] as String?)?.trim() ?? '';
      final opts = item['options'];
      final correctIdx = item['correct_index'] ?? item['correctIndex'];
      final expl = (item['explanation'] as String?)?.trim();

      if (q.isEmpty ||
          opts is! List ||
          opts.length != 4 ||
          correctIdx is! int ||
          correctIdx < 0 ||
          correctIdx > 3) {
        continue;
      }

      final question = QuizQuestionModel(
        id: _uuid.v4(),
        quizId: quizId,
        question: q,
        options: opts.map((o) => o.toString()).toList(),
        correctIndex: correctIdx,
        explanation: expl,
      );
      batch.insert('quiz_questions', question.toMap());
      questionModels.add(question);
    }

    if (questionModels.isEmpty) {
      throw OllamaException(
        'Model nie zwrócił żadnego poprawnego pytania.',
      );
    }

    await batch.commit(noResult: true);

    return QuizModel(
      id: quizId,
      subjectId: subjectId,
      title: quizModel.title,
      createdAt: now,
      questions: questionModels,
    );
  }
}
