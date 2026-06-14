import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../shared/database/database_helper.dart';
import '../models/subject_model.dart';

abstract class SubjectsLocalDataSource {
  Future<List<SubjectModel>> getAll();
  Future<SubjectModel> create({
    required String name,
    String? description,
    required int colorValue,
  });
  Future<void> delete(String id);
  Future<SubjectModel> getById(String id);
}

class SubjectsLocalDataSourceImpl implements SubjectsLocalDataSource {
  final DatabaseHelper _dbHelper;
  final Uuid _uuid;

  SubjectsLocalDataSourceImpl({
    required DatabaseHelper dbHelper,
    Uuid? uuid,
  })  : _dbHelper = dbHelper,
        _uuid = uuid ?? const Uuid();

  @override
  Future<List<SubjectModel>> getAll() async {
    try {
      final db = await _dbHelper.database;
      final rows =
          await db.query('subjects', orderBy: 'created_at DESC');
      return rows.map(SubjectModel.fromMap).toList();
    } catch (e) {
      throw DatabaseException('Nie udało się odczytać przedmiotów: $e');
    }
  }

  @override
  Future<SubjectModel> create({
    required String name,
    String? description,
    required int colorValue,
  }) async {
    try {
      final db = await _dbHelper.database;
      final model = SubjectModel(
        id: _uuid.v4(),
        name: name,
        description: description,
        color: Color(colorValue),
        createdAt: DateTime.now(),
      );
      await db.insert('subjects', model.toMap());
      return model;
    } catch (e) {
      throw DatabaseException('Nie udało się utworzyć przedmiotu: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      final db = await _dbHelper.database;
      await db.delete('subjects', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw DatabaseException('Nie udało się usunąć przedmiotu: $e');
    }
  }

  @override
  Future<SubjectModel> getById(String id) async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.query(
        'subjects',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw DatabaseException('Przedmiot $id nie istnieje.');
      }
      return SubjectModel.fromMap(rows.first);
    } catch (e) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException('Nie udało się odczytać przedmiotu: $e');
    }
  }
}
