import 'package:cloud_firestore/cloud_firestore.dart';

import 'conversores.dart';

/// Modelo de un documento de la colección `courts` de Cloud Firestore.
class Cancha {
  const Cancha({
    required this.id,
    required this.nombre,
    this.ubicacion = '',
    this.activa = true,
  });

  final String id;
  final String nombre;
  final String ubicacion;
  final bool activa;

  String get nombreConUbicacion =>
      ubicacion.trim().isEmpty ? nombre : '$nombre ($ubicacion)';

  factory Cancha.fromJson(Map<String, dynamic> json, {required String id}) {
    return Cancha(
      id: id,
      nombre: textoDe(json['nombre'], porDefecto: 'Sin nombre'),
      ubicacion: textoDe(json['ubicacion']),
      activa: booleanoDe(json['activa'], porDefecto: true),
    );
  }

  factory Cancha.fromFirestore(DocumentSnapshot doc) {
    final dynamic data = doc.data();
    return Cancha.fromJson(data ?? const {}, id: doc.id);
  }

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'ubicacion': ubicacion,
        'activa': activa,
      };
}
