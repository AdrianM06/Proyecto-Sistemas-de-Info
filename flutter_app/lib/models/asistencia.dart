import 'package:cloud_firestore/cloud_firestore.dart';

import 'conversores.dart';

/// Modelo de un documento de la colección `attendances` de Cloud Firestore.
///
/// Según el documento del Hito 2, cada registro corresponde a una sesión
/// de entrenamiento: deporteId, fecha, entrenadorId y la lista de
/// `presentes` (ids de los estudiantes que asistieron). Los ausentes son
/// los estudiantes de la nómina que no están en esa lista.
///
/// El id del documento se forma con el deporte y la fecha
/// (`<deporteId>_<aaaa-mm-dd>`), así hay un solo registro por sesión y
/// volver a guardar ese día lo actualiza en lugar de duplicarlo.
class Asistencia {
  Asistencia({
    required this.deporteId,
    required DateTime fecha,
    required this.entrenadorId,
    required List<String> presentes,
    String? id,
  })  : fecha = soloFecha(fecha),
        presentes = List.unmodifiable(presentes),
        id = id ?? idPara(deporteId, fecha);

  final String id;
  final String deporteId;
  final DateTime fecha;
  final String entrenadorId;
  final List<String> presentes;

  /// Id del documento para un deporte en una fecha.
  static String idPara(String deporteId, DateTime fecha) =>
      '${deporteId}_${claveDeFecha(fecha)}';

  bool estaPresente(String estudianteId) => presentes.contains(estudianteId);

  /// Patrón Factory Method: crea una [Asistencia] a partir del mapa
  /// guardado en Firestore.
  factory Asistencia.fromJson(Map<String, dynamic> json, {required String id}) {
    return Asistencia(
      id: id,
      deporteId: textoDe(json['deporteId']),
      fecha: fechaDe(json['fecha']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      entrenadorId: textoDe(json['entrenadorId']),
      presentes: listaDeTextosDe(json['presentes']),
    );
  }

  /// Crea una [Asistencia] directamente desde un documento de Firestore.
  factory Asistencia.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Asistencia.fromJson(doc.data() ?? const {}, id: doc.id);
  }

  Map<String, dynamic> toJson() => {
        'deporteId': deporteId,
        'fecha': Timestamp.fromDate(fecha),
        'entrenadorId': entrenadorId,
        'presentes': presentes,
      };
}
