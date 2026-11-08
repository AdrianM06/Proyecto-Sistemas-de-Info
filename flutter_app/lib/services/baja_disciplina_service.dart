import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/inscripcion.dart';
import 'firestore_service.dart';

/// Error al eliminar una disciplina, con un mensaje listo para mostrar.
class BajaDisciplinaException implements Exception {
  const BajaDisciplinaException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Eliminar disciplinas desde el panel del administrador.
abstract class BajaDisciplinaDataSource {
  /// Estudiantes con inscripción activa en la disciplina. El panel lo usa
  /// para advertir antes de eliminar.
  Future<int> inscripcionesActivas(String deporteId);

  /// Elimina la disciplina. Sus inscripciones activas pasan a `retirada`
  /// (los estudiantes dejan de verla) y se borran sus reseñas. Las
  /// asistencias ya tomadas se conservan como historial.
  Future<void> eliminar(String deporteId);
}

/// Implementación real con Cloud Firestore. Las reglas solo dejan eliminar
/// disciplinas y reseñas, y cambiar inscripciones ajenas, al administrador.
class BajaDisciplinaService implements BajaDisciplinaDataSource {
  BajaDisciplinaService({FirestoreService? firestore})
    : _firestore = firestore ?? FirestoreService.instance;

  final FirestoreService _firestore;

  /// Firestore admite hasta 500 escrituras por lote; se deja margen.
  static const int _maximoPorLote = 400;

  Query<Map<String, dynamic>> _activas(String deporteId) => _firestore
      .enrollments
      .where('deporteId', isEqualTo: deporteId)
      .where('estado', isEqualTo: EstadoInscripcion.activa.name);

  @override
  Future<int> inscripcionesActivas(String deporteId) async {
    final resultado = await _activas(deporteId).count().get();
    return resultado.count ?? 0;
  }

  @override
  Future<void> eliminar(String deporteId) async {
    final disciplina = _firestore.sports.doc(deporteId);
    try {
      if (!(await disciplina.get()).exists) {
        throw const BajaDisciplinaException('La disciplina ya no existe.');
      }

      final inscripciones = (await _activas(deporteId).get()).docs;
      final resenas = (await _firestore.reviewsOf(deporteId).get()).docs;

      final cambios = <void Function(WriteBatch lote)>[
        for (final doc in inscripciones)
          (lote) => lote.update(doc.reference, {
            'estado': EstadoInscripcion.retirada.name,
            'fechaRetiro': FieldValue.serverTimestamp(),
          }),
        for (final doc in resenas) (lote) => lote.delete(doc.reference),
      ];

      for (var i = 0; i < cambios.length; i += _maximoPorLote) {
        final lote = _firestore.db.batch();
        final fin = i + _maximoPorLote < cambios.length
            ? i + _maximoPorLote
            : cambios.length;
        for (final cambio in cambios.sublist(i, fin)) {
          cambio(lote);
        }
        await lote.commit();
      }

      // La disciplina se borra al final: si algo falla antes, sigue
      // existiendo y el administrador puede intentarlo de nuevo.
      await disciplina.delete();
    } on BajaDisciplinaException {
      rethrow;
    } on FirebaseException catch (e) {
      throw BajaDisciplinaException(
        e.code == 'permission-denied'
            ? 'Solo un administrador puede eliminar disciplinas.'
            : 'No se pudo eliminar la disciplina. Intenta de nuevo.',
      );
    }
  }
}
