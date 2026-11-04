import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/deporte.dart';
import '../models/usuario.dart';
import 'firestore_service.dart';

/// Error al asignar o quitar una disciplina, con un mensaje listo para
/// mostrar.
class GestionEntrenadoresException implements Exception {
  const GestionEntrenadoresException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Datos del panel del administrador para gestionar entrenadores.
///
/// La relación entre entrenadores y disciplinas vive en
/// `sports/{id}.entrenadorId`: una disciplina tiene un solo entrenador y un
/// entrenador puede tener varias disciplinas.
abstract class GestionEntrenadoresDataSource {
  /// Usuarios con `rol: "entrenador"`. Emite de nuevo cuando cambian.
  Stream<List<Usuario>> entrenadores();

  /// Todas las disciplinas. Emite de nuevo cuando cambia alguna.
  Stream<List<Deporte>> deportes();

  /// Asigna la disciplina al entrenador. Si tenía otro entrenador, pasa a
  /// este.
  Future<void> asignar({
    required String entrenadorId,
    required String deporteId,
  });

  /// Quita al entrenador de la disciplina. Falla si la disciplina ya no es
  /// suya (por ejemplo, otro administrador la reasignó).
  Future<void> revocar({
    required String entrenadorId,
    required String deporteId,
  });
}

/// Implementación real con Cloud Firestore. Las reglas solo dejan escribir en
/// `sports` al administrador.
class GestionEntrenadoresService implements GestionEntrenadoresDataSource {
  GestionEntrenadoresService({FirestoreService? firestore})
    : _firestore = firestore ?? FirestoreService.instance;

  final FirestoreService _firestore;

  @override
  Stream<List<Usuario>> entrenadores() {
    return _firestore.users
        .where('rol', isEqualTo: 'entrenador')
        .snapshots()
        .map((resultado) => resultado.docs.map(Usuario.fromFirestore).toList());
  }

  @override
  Stream<List<Deporte>> deportes() {
    return _firestore.sports.snapshots().map(
      (resultado) => resultado.docs.map(Deporte.fromFirestore).toList(),
    );
  }

  @override
  Future<void> asignar({
    required String entrenadorId,
    required String deporteId,
  }) {
    return _cambiar(deporteId, (datos) {
      return entrenadorId;
    });
  }

  @override
  Future<void> revocar({
    required String entrenadorId,
    required String deporteId,
  }) {
    return _cambiar(deporteId, (datos) {
      if (datos['entrenadorId'] != entrenadorId) {
        throw const GestionEntrenadoresException(
          'Esa disciplina ya no está asignada a este entrenador.',
        );
      }
      return '';
    });
  }

  /// Lee la disciplina y escribe el nuevo `entrenadorId` en una transacción,
  /// para no pisar un cambio hecho al mismo tiempo.
  Future<void> _cambiar(
    String deporteId,
    String Function(Map<String, dynamic> datos) nuevoEntrenador,
  ) async {
    final referencia = _firestore.sports.doc(deporteId);
    try {
      await _firestore.db.runTransaction((transaccion) async {
        final doc = await transaccion.get(referencia);
        if (!doc.exists) {
          throw const GestionEntrenadoresException(
            'La disciplina ya no existe.',
          );
        }
        transaccion.update(referencia, {
          'entrenadorId': nuevoEntrenador(doc.data() ?? const {}),
        });
      });
    } on FirebaseException catch (e) {
      throw GestionEntrenadoresException(
        e.code == 'permission-denied'
            ? 'No tienes permiso para cambiar las disciplinas.'
            : 'No se pudo guardar el cambio. Revisa tu conexión e intenta de nuevo.',
      );
    }
  }
}
