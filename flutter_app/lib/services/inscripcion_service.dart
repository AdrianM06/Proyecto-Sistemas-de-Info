import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/deporte.dart';
import '../models/inscripcion.dart';
import 'firestore_service.dart';

/// Error al inscribirse, con un mensaje listo para mostrar.
class InscripcionException implements Exception {
  const InscripcionException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Operaciones de datos de la inscripción del estudiante en una disciplina.
///
/// El controlador del buscador depende de esta interfaz; así funciona con
/// Firestore ([InscripcionService]) o con datos en memoria en las pruebas.
abstract class InscripcionesDataSource {
  /// Ids de los deportes donde el estudiante tiene una inscripción activa.
  Future<Set<String>> deportesInscritos(String estudianteId);

  /// Inscribe al estudiante. Lanza [InscripcionException] si no se pudo.
  Future<void> inscribir({
    required String estudianteId,
    required Deporte deporte,
  });
}

/// Implementación real con Cloud Firestore (colección `enrollments`).
///
/// Cada inscripción es un documento con `estudianteId`, `deporteId`,
/// `estado: "activa"` y `fechaInscripcion`. Retirarse la marca como
/// `retirada` (ver `PerfilEstudianteService.retirarDisciplina`), así que
/// volver a inscribirse crea un documento nuevo.
///
/// Los cupos se revisan en la app antes de escribir. Si dos estudiantes se
/// inscriben en el mismo instante en el último cupo, los dos pueden entrar:
/// las reglas de Firestore no pueden contar documentos.
class InscripcionService implements InscripcionesDataSource {
  InscripcionService({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService.instance;

  final FirestoreService _firestore;

  @override
  Future<Set<String>> deportesInscritos(String estudianteId) async {
    final resultado = await _firestore.enrollments
        .where('estudianteId', isEqualTo: estudianteId)
        .get();
    return {
      for (final doc in resultado.docs)
        if (Inscripcion.fromFirestore(doc).estaActiva)
          Inscripcion.fromFirestore(doc).deporteId,
    };
  }

  @override
  Future<void> inscribir({
    required String estudianteId,
    required Deporte deporte,
  }) async {
    try {
      final deLaDisciplina = await _firestore.enrollments
          .where('deporteId', isEqualTo: deporte.id)
          .get();
      final activas = deLaDisciplina.docs
          .map(Inscripcion.fromFirestore)
          .where((inscripcion) => inscripcion.estaActiva)
          .toList();

      if (activas.any((inscripcion) => inscripcion.estudianteId == estudianteId)) {
        throw InscripcionException('Ya estás inscrito en ${deporte.nombre}.');
      }
      if (activas.length >= deporte.cupos) {
        throw InscripcionException(
          '${deporte.nombre} ya no tiene cupos disponibles.',
        );
      }

      await _firestore.enrollments.add({
        'estudianteId': estudianteId,
        'deporteId': deporte.id,
        'estado': EstadoInscripcion.activa.name,
        'fechaInscripcion': FieldValue.serverTimestamp(),
      });
    } on InscripcionException {
      rethrow;
    } on FirebaseException catch (e) {
      throw InscripcionException(
        e.code == 'permission-denied'
            ? 'No tienes permiso para inscribirte. Vuelve a iniciar sesión.'
            : 'No se pudo completar la inscripción. Revisa tu conexión e intenta de nuevo.',
      );
    }
  }
}
