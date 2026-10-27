import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/asistencia.dart';
import '../models/deporte.dart';
import '../models/inscripcion.dart';
import '../models/usuario.dart';
import 'firestore_service.dart';

/// Operaciones de datos que necesita la vista del entrenador.
///
/// El controlador depende de esta interfaz y no de Firestore directamente.
/// Así se puede usar la implementación real ([EntrenadorService]) o una de
/// prueba ([EntrenadorDemoService]) sin cambiar el controlador ni las vistas.
abstract class EntrenadorDataSource {
  /// Deportes cuyo `entrenadorId` es el del entrenador.
  Future<List<Deporte>> deportesDelEntrenador(String entrenadorId);

  /// Estudiantes con inscripción `activa` en el deporte.
  Future<List<Usuario>> nominaDelDeporte(String deporteId);

  /// Asistencia guardada para el deporte en esa fecha, o `null` si no hay.
  Future<Asistencia?> asistenciaDelDia(String deporteId, DateTime fecha);

  /// Todas las asistencias guardadas del deporte, de la más reciente a la
  /// más antigua.
  Future<List<Asistencia>> historialDeAsistencia(String deporteId);

  /// Crea o actualiza la asistencia de una sesión.
  Future<void> guardarAsistencia(Asistencia asistencia);
}

/// Implementación real con Cloud Firestore.
///
/// Usa el Singleton [FirestoreService] y las colecciones `sports`,
/// `enrollments`, `users` y `attendances`. Todas las consultas filtran por
/// un solo campo, así que no necesitan índices compuestos.
class EntrenadorService implements EntrenadorDataSource {
  EntrenadorService({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService.instance;

  final FirestoreService _firestore;

  /// Firestore permite como máximo 30 valores en una consulta `whereIn`.
  static const int _maximoPorConsulta = 30;

  @override
  Future<List<Deporte>> deportesDelEntrenador(String entrenadorId) async {
    final resultado = await _firestore.sports
        .where('entrenadorId', isEqualTo: entrenadorId)
        .get();
    final deportes = resultado.docs.map(Deporte.fromFirestore).toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
    return deportes;
  }

  @override
  Future<List<Usuario>> nominaDelDeporte(String deporteId) async {
    final inscripciones = await _firestore.enrollments
        .where('deporteId', isEqualTo: deporteId)
        .get();
    final idsEstudiantes = inscripciones.docs
        .map(Inscripcion.fromFirestore)
        .where((inscripcion) => inscripcion.estaActiva)
        .map((inscripcion) => inscripcion.estudianteId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final estudiantes = <Usuario>[];
    for (var i = 0; i < idsEstudiantes.length; i += _maximoPorConsulta) {
      final fin = (i + _maximoPorConsulta < idsEstudiantes.length)
          ? i + _maximoPorConsulta
          : idsEstudiantes.length;
      final grupo = idsEstudiantes.sublist(i, fin);
      final usuarios = await _firestore.users
          .where(FieldPath.documentId, whereIn: grupo)
          .get();
      estudiantes.addAll(usuarios.docs.map(Usuario.fromFirestore));
    }
    estudiantes.sort(_compararPorApellido);
    return estudiantes;
  }

  @override
  Future<Asistencia?> asistenciaDelDia(String deporteId, DateTime fecha) async {
    final doc = await _firestore.attendances
        .doc(Asistencia.idPara(deporteId, fecha))
        .get();
    if (!doc.exists) return null;
    return Asistencia.fromFirestore(doc);
  }

  @override
  Future<List<Asistencia>> historialDeAsistencia(String deporteId) async {
    final resultado = await _firestore.attendances
        .where('deporteId', isEqualTo: deporteId)
        .get();
    final historial = resultado.docs.map(Asistencia.fromFirestore).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    return historial;
  }

  @override
  Future<void> guardarAsistencia(Asistencia asistencia) {
    return _firestore.attendances
        .doc(asistencia.id)
        .set(asistencia.toJson(), SetOptions(merge: true));
  }
}

int _compararPorApellido(Usuario a, Usuario b) {
  final porApellido = a.apellido.toLowerCase().compareTo(b.apellido.toLowerCase());
  if (porApellido != 0) return porApellido;
  return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
}
