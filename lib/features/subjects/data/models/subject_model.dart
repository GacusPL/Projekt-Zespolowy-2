import 'package:flutter/material.dart';

import '../../domain/entities/subject.dart';

/// Model = encja domeny + (de)serializacja do/z mapy SQLite.
class SubjectModel extends Subject {
  const SubjectModel({
    required super.id,
    required super.name,
    super.description,
    required super.color,
    required super.createdAt,
  });

  factory SubjectModel.fromMap(Map<String, dynamic> m) => SubjectModel(
        id: m['id'] as String,
        name: m['name'] as String,
        description: m['description'] as String?,
        color: Color(m['color_value'] as int),
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'color_value': color.toARGB32(),
        'created_at': createdAt.millisecondsSinceEpoch,
      };
}
