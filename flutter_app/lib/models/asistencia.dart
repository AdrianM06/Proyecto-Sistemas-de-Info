import 'package:cloud_firestore/cloud_firestore.dart';

import 'conversores.dart';

/// Modelo de un documento de la colección `attendances` de Cloud Firestore.
///
/// Según el documento del Hito 2, cada registro corresponde a una sesión
/// de entrenamiento: deporteId, fecha, entrenadorId y la lista de
/// `presentes` (ids de los estudiantes que asistieron). Los ausentes son
/// los estudiantes de la nómina que no están en esa lista.
///
/// Además de la fecha de la sesión, guarda **marcas de tiempo completas**
/// (fecha y hora):
/// - `registradaEn`: cuándo se guardó la asistencia por última vez.
/// - `horasPresentes`: para cada estudiante presente, el momento exacto en
///   que el entrenador lo marcó (`{uid: Timestamp}`).
///
/// Los registros viejos no tienen esos campos; entonces [horaDe] devuelve
/// `null` y la interfaz muestra "Hora no registrada".
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
    this.registradaEn,
    Map<String, DateTime> horasPresentes = const {},
  }) : fecha = soloFecha(fecha),
       presentes = List.unmodifiable(presentes),
       horasPresentes = Map.unmodifiable(horasPresentes),
       id = id ?? idPara(deporteId, fecha);

  final String id;
  final String deporteId;

  /// Día de la sesión (sin hora).
  final DateTime fecha;
  final String entrenadorId;
  final List<String> presentes;

  /// Fecha y hora en que se guardó la asistencia, o `null` en registros
  /// viejos.
  final DateTime? registradaEn;

  /// Fecha y hora en que se marcó presente a cada estudiante.
  final Map<String, DateTime> horasPresentes;

  /// Id del documento para un deporte en una fecha.
  static String idPara(String deporteId, DateTime fecha) =>
      '${deporteId}_${claveDeFecha(fecha)}';

  bool estaPresente(String estudianteId) => presentes.contains(estudianteId);

  /// Fecha y hora exacta del registro de asistencia del estudiante, o `null`
  /// si no asistió o si el registro es viejo y no guardó la hora.
  DateTime? horaDe(String estudianteId) {
    if (!estaPresente(estudianteId)) return null;
    return horasPresentes[estudianteId];
  }

  /// Patrón Factory Method: crea una [Asistencia] a partir del mapa
  /// guardado en Firestore.
  factory Asistencia.fromJson(Map<String, dynamic> json, {required String id}) {
    final horas = <String, DateTime>{};
    final crudas = json['horasPresentes'];
    if (crudas is Map) {
      for (final entrada in crudas.entries) {
        final hora = fechaDe(entrada.value);
        if (hora != null) horas[entrada.key.toString()] = hora;
      }
    }
    return Asistencia(
      id: id,
      deporteId: textoDe(json['deporteId']),
      fecha: fechaDe(json['fecha']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      entrenadorId: textoDe(json['entrenadorId']),
      presentes: listaDeTextosDe(json['presentes']),
      registradaEn: fechaDe(json['registradaEn']),
      horasPresentes: horas,
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
    if (registradaEn != null) 'registradaEn': Timestamp.fromDate(registradaEn!),
    'horasPresentes': {
      for (final entrada in horasPresentes.entries)
        if (presentes.contains(entrada.key))
          entrada.key: Timestamp.fromDate(entrada.value),
    },
  };
}
