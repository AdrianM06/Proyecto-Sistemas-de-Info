import 'package:cloud_firestore/cloud_firestore.dart';

import 'conversores.dart';

/// Reseña de un estudiante sobre una disciplina.
///
/// Se guarda en `sports/{deporteId}/reviews/{estudianteId}`: el id del
/// documento es el uid del autor, así cada estudiante tiene como máximo una
/// reseña por disciplina (si vuelve a publicar, la actualiza).
class Resena {
  const Resena({
    required this.estudianteId,
    required this.deporteId,
    required this.autor,
    required this.rating,
    required this.comment,
    this.createdAt,
    this.updatedAt,
  });

  static const int ratingMinimo = 1;
  static const int ratingMaximo = 5;

  /// Largo máximo del comentario (igual que en `firestore.rules`).
  static const int largoMaximo = 500;

  final String estudianteId;
  final String deporteId;

  /// Nombre del autor al momento de publicar. Se guarda en la reseña porque
  /// las reglas no dejan a un estudiante leer el perfil de otro.
  final String autor;

  /// Valoración de 1 a 5 estrellas.
  final int rating;
  final String comment;

  /// `null` mientras Firestore no confirma la hora del servidor.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Patrón Factory Method: crea una [Resena] a partir del mapa guardado en
  /// Firestore, tolerando campos faltantes.
  factory Resena.fromJson(
    Map<String, dynamic> json, {
    required String id,
    String deporteId = '',
  }) {
    final rating = enteroDe(json['rating'], porDefecto: ratingMinimo);
    return Resena(
      estudianteId: textoDe(json['estudianteId'], porDefecto: id),
      deporteId: textoDe(json['deporteId'], porDefecto: deporteId),
      autor: textoDe(json['autor'], porDefecto: 'Estudiante'),
      rating: rating.clamp(ratingMinimo, ratingMaximo),
      comment: textoDe(json['comment']),
      createdAt: fechaDe(json['createdAt']),
      updatedAt: fechaDe(json['updatedAt']),
    );
  }

  /// Crea una [Resena] desde un documento de `sports/{id}/reviews`.
  factory Resena.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Resena.fromJson(
      doc.data() ?? const {},
      id: doc.id,
      deporteId: doc.reference.parent.parent?.id ?? '',
    );
  }
}
