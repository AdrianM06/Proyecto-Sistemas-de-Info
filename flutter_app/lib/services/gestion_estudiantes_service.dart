import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/usuario.dart';
import 'firestore_service.dart';

/// Error al cambiar el estado de un estudiante, con un mensaje listo para
/// mostrar.
class GestionEstudiantesException implements Exception {
  const GestionEstudiantesException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Datos del panel del administrador para gestionar estudiantes.
abstract class GestionEstudiantesDataSource {
  /// Usuarios con `rol: "estudiante"`. Emite de nuevo cuando cambian.
  Stream<List<Usuario>> estudiantes();

  /// Habilita ([activo] = `true`) o deshabilita al estudiante
  /// (`users/{uid}.estadoActivo`).
  Future<void> cambiarEstado({required String uid, required bool activo});
}

/// Implementación real con Cloud Firestore. Las reglas solo dejan al
/// administrador cambiar `estadoActivo` de otro usuario.
class GestionEstudiantesService implements GestionEstudiantesDataSource {
  GestionEstudiantesService({FirestoreService? firestore})
    : _firestore = firestore ?? FirestoreService.instance;

  final FirestoreService _firestore;

  @override
  Stream<List<Usuario>> estudiantes() {
    return _firestore.users
        .where('rol', isEqualTo: 'estudiante')
        .snapshots()
        .map((resultado) => resultado.docs.map(Usuario.fromFirestore).toList());
  }

  @override
  Future<void> cambiarEstado({
    required String uid,
    required bool activo,
  }) async {
    try {
      await _firestore.users.doc(uid).update({'estadoActivo': activo});
    } on FirebaseException catch (e) {
      throw GestionEstudiantesException(
        e.code == 'permission-denied'
            ? 'No tienes permiso para cambiar el estado de los estudiantes.'
            : e.code == 'not-found'
            ? 'Ese estudiante ya no existe.'
            : 'No se pudo guardar el cambio. Revisa tu conexión e intenta de nuevo.',
      );
    }
  }
}
