import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/inscripcion.dart';
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
  ///
  /// Al deshabilitarlo, además lo retira de **todas** las disciplinas en las
  /// que tenía una inscripción activa. Devuelve cuántas inscripciones
  /// retiró (siempre 0 al habilitar: no se le vuelve a inscribir).
  Future<int> cambiarEstado({required String uid, required bool activo});
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

  /// El cambio de estado y el retiro de las inscripciones van en un mismo
  /// lote (`WriteBatch`): se guardan todos juntos o no se guarda ninguno, así
  /// un estudiante nunca queda deshabilitado pero todavía inscrito.
  @override
  Future<int> cambiarEstado({required String uid, required bool activo}) async {
    try {
      final usuario = _firestore.users.doc(uid);
      if (activo) {
        await usuario.update({'estadoActivo': true});
        return 0;
      }

      final inscripciones = await _firestore.enrollments
          .where('estudianteId', isEqualTo: uid)
          .get();
      final activas = inscripciones.docs
          .where((doc) => Inscripcion.fromFirestore(doc).estaActiva)
          .toList();

      final lote = _firestore.db.batch();
      lote.update(usuario, {'estadoActivo': false});
      for (final doc in activas) {
        lote.update(doc.reference, {
          'estado': EstadoInscripcion.retirada.name,
          'fechaRetiro': FieldValue.serverTimestamp(),
          'motivoRetiro': 'cuenta-deshabilitada',
        });
      }
      await lote.commit();
      return activas.length;
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
