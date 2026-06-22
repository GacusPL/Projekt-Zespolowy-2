import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Przedmiot akademicki — najwyższy poziom organizacji materiałów.
/// Wszystko inne (dokumenty, konwersacje, fiszki, quizy) jest "podpięte"
/// pod konkretny przedmiot.
class Subject extends Equatable {
  final String id;
  final String name;
  final String? description;
  final Color color;
  final DateTime createdAt;

  const Subject({
    required this.id,
    required this.name,
    this.description,
    required this.color,
    required this.createdAt,
  });

  Subject copyWith({
    String? name,
    String? description,
    Color? color,
  }) =>
      Subject(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        color: color ?? this.color,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, name, description, color, createdAt];
}
