import 'package:cloud_firestore/cloud_firestore.dart';

import 'conversores.dart';

/// Estados de una inscripción según el documento del Hito 2.
enum EstadoInscripcion { activa, retirada }

/// Modelo de un documento de la colección `enrollments` de Cloud Firestore.
///
/// Campos: estudianteId, deporteId, fechaInscripcion y estado
/// (`activa` o `retirada`).
class Inscripcion {
  const Inscripcion({
    required this.id,
    required this.estudianteId,
    required this.deporteId,
    required this.estado,
    this.fechaInscripcion,
  });

  final String id;
  final String estudianteId;
  final String deporteId;
  final EstadoInscripcion estado;
  final DateTime? fechaInscripcion;

  bool get estaActiva => estado == EstadoInscripcion.activa;

  /// Patrón Factory Method: crea una [Inscripcion] a partir del mapa
  /// guardado en Firestore. Cualquier estado distinto de `retirada` se toma
  /// como `activa`.
  factory Inscripcion.fromJson(Map<String, dynamic> json, {required String id}) {
    final estado = textoDe(json['estado']).trim().toLowerCase();
    return Inscripcion(
      id: id,
      estudianteId: textoDe(json['estudianteId']),
      deporteId: textoDe(json['deporteId']),
      estado: estado == 'retirada'
          ? EstadoInscripcion.retirada
          : EstadoInscripcion.activa,
      fechaInscripcion: fechaDe(json['fechaInscripcion']),
    );
  }

  /// Crea una [Inscripcion] directamente desde un documento de Firestore.
  factory Inscripcion.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Inscripcion.fromJson(doc.data() ?? const {}, id: doc.id);
  }

  Map<String, dynamic> toJson() => {
        'estudianteId': estudianteId,
        'deporteId': deporteId,
        'estado': estado.name,
        'fechaInscripcion': fechaInscripcion == null
            ? null
            : Timestamp.fromDate(fechaInscripcion!),
      };
}
