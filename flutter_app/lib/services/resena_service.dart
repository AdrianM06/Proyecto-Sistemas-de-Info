import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/resena.dart';
import 'firestore_service.dart';

/// Error al publicar una reseña, con un mensaje listo para mostrar.
class ResenaException implements Exception {
  const ResenaException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Operaciones de datos de las reseñas de una disciplina.
///
/// El controlador depende de esta interfaz; así funciona con Firestore
/// ([ResenasService]) o con datos en memoria en las pruebas.
abstract class ResenasDataSource {
  /// Reseñas de la disciplina, de la más reciente a la más antigua. Emite de
  /// nuevo cada vez que alguien publica o edita una reseña.
  Stream<List<Resena>> resenasDe(String deporteId);

  /// `true` si el estudiante tiene o tuvo una inscripción en la disciplina.
  Future<bool> participoEn({
    required String estudianteId,
    required String deporteId,
  });

  /// Crea la reseña del estudiante ([esNueva]) o actualiza la que ya tenía.
  /// Lanza [ResenaException] si no se pudo guardar.
  Future<void> guardar({
    required String estudianteId,
    required String deporteId,
    required int rating,
    required String comment,
    required bool esNueva,
  });
}

/// Implementación real con Cloud Firestore.
class ResenasService implements ResenasDataSource {
  ResenasService({FirestoreService? firestore})
    : _firestore = firestore ?? FirestoreService.instance;

  final FirestoreService _firestore;

  @override
  Stream<List<Resena>> resenasDe(String deporteId) {
    return _firestore
        .reviewsOf(deporteId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((resultado) => resultado.docs.map(Resena.fromFirestore).toList());
  }

  @override
  Future<bool> participoEn({
    required String estudianteId,
    required String deporteId,
  }) async {
    final resultado = await _firestore.enrollments
        .where('estudianteId', isEqualTo: estudianteId)
        .where('deporteId', isEqualTo: deporteId)
        .limit(1)
        .get();
    return resultado.docs.isNotEmpty;
  }

  @override
  Future<void> guardar({
    required String estudianteId,
    required String deporteId,
    required int rating,
    required String comment,
    required bool esNueva,
  }) async {
    final referencia = _firestore.reviewsOf(deporteId).doc(estudianteId);
    try {
      final autor = await _nombreDe(estudianteId);
      if (esNueva) {
        await referencia.set({
          'estudianteId': estudianteId,
          'deporteId': deporteId,
          'autor': autor,
          'rating': rating,
          'comment': comment,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await referencia.update({
          'autor': autor,
          'rating': rating,
          'comment': comment,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseException catch (e) {
      throw ResenaException(
        e.code == 'permission-denied'
            ? 'No tienes permiso para publicar esta reseña.'
            : 'No se pudo guardar la reseña. Revisa tu conexión e intenta de nuevo.',
      );
    }
  }

  /// Nombre y apellido del perfil `users/{uid}` (el propio estudiante sí
  /// puede leerlo).
  Future<String> _nombreDe(String uid) async {
    final datos = (await _firestore.users.doc(uid).get()).data() ?? const {};
    final nombre = [datos['nombre'], datos['apellido']]
        .map((parte) => (parte ?? '').toString().trim())
        .where((parte) => parte.isNotEmpty)
        .join(' ');
    return nombre.isEmpty ? 'Estudiante' : nombre;
  }
}
