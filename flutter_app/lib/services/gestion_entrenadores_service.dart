import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/deporte.dart';
import '../models/usuario.dart';
import '../utils/choques_horario.dart';
import 'firestore_service.dart';

/// Error al asignar o quitar una disciplina, con un mensaje listo para
/// mostrar.
class GestionEntrenadoresException implements Exception {
  const GestionEntrenadoresException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Datos del panel del administrador para gestionar entrenadores y
/// disciplinas.
///
/// La relación vive en `sports/{id}.entrenadoresIds`: una disciplina puede
/// tener varios entrenadores y un entrenador varias disciplinas, siempre que
/// sus horarios no se crucen.
abstract class GestionEntrenadoresDataSource {
  /// Usuarios con `rol: "entrenador"`. Emite de nuevo cuando cambian.
  Stream<List<Usuario>> entrenadores();

  /// Todas las disciplinas. Emite de nuevo cuando cambia alguna.
  Stream<List<Deporte>> deportes();

  /// Agrega al entrenador a la disciplina (sin quitar a los que ya tenía).
  ///
  /// Lanza [ChoqueHorarioException] si la disciplina se cruza con otra que
  /// el entrenador ya dicta, y [GestionEntrenadoresException] por otros
  /// errores.
  Future<void> asignar({
    required String entrenadorId,
    required String entrenadorNombre,
    required String deporteId,
  });

  /// Quita al entrenador de la disciplina. Falla si ya no la tenía (por
  /// ejemplo, otro administrador se la quitó).
  Future<void> revocar({
    required String entrenadorId,
    required String deporteId,
  });

  /// Crea la disciplina (si `deporte.id` está vacío) o la actualiza, con sus
  /// entrenadores. Antes de guardar comprueba que los horarios no se crucen
  /// con las demás disciplinas de cada entrenador; si se cruzan lanza
  /// [ChoqueHorarioException].
  Future<void> guardarDisciplina(Deporte deporte);
}

/// Implementación real con Cloud Firestore. Las reglas solo dejan escribir en
/// `sports` al administrador.
///
/// **Condiciones de carrera.** Cada cambio corre en una transacción que lee
/// la disciplina y el perfil de cada entrenador involucrado y escribe en
/// ambos (`users/{uid}.horarioActualizado`). Si dos administradores asignan
/// al mismo entrenador a la vez, Firestore detecta que el perfil cambió y
/// repite una de las transacciones, que vuelve a consultar las disciplinas
/// del entrenador y ve la asignación nueva antes de validar los choques.
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
    required String entrenadorNombre,
    required String deporteId,
  }) {
    final referencia = _firestore.sports.doc(deporteId);
    return _enTransaccion((transaccion) async {
      final doc = await transaccion.get(referencia);
      if (!doc.exists) {
        throw const GestionEntrenadoresException('La disciplina ya no existe.');
      }
      final deporte = Deporte.fromFirestore(doc);
      if (deporte.tieneEntrenador(entrenadorId)) {
        throw const GestionEntrenadoresException(
          'El entrenador ya tiene asignada esa disciplina.',
        );
      }
      await _bloquearEntrenadores(transaccion, [entrenadorId]);
      await _validarChoques(
        deporte: deporte,
        entrenadorId: entrenadorId,
        entrenadorNombre: entrenadorNombre,
      );

      transaccion.update(referencia, {
        'entrenadoresIds': [...deporte.entrenadoresIds, entrenadorId],
        'entrenadoresNombres.$entrenadorId': entrenadorNombre,
        'entrenadorId': FieldValue.delete(),
        ...Deporte.camposDeHorario(deporte.bloques),
      });
      _marcarEntrenadores(transaccion, [entrenadorId]);
    });
  }

  @override
  Future<void> revocar({
    required String entrenadorId,
    required String deporteId,
  }) {
    final referencia = _firestore.sports.doc(deporteId);
    return _enTransaccion((transaccion) async {
      final doc = await transaccion.get(referencia);
      if (!doc.exists) {
        throw const GestionEntrenadoresException('La disciplina ya no existe.');
      }
      final ids = Deporte.leerEntrenadoresIds(doc.data() ?? const {});
      if (!ids.contains(entrenadorId)) {
        throw const GestionEntrenadoresException(
          'Esa disciplina ya no está asignada a este entrenador.',
        );
      }
      await _bloquearEntrenadores(transaccion, [entrenadorId]);
      transaccion.update(referencia, {
        'entrenadoresIds': ids.where((id) => id != entrenadorId).toList(),
        'entrenadoresNombres.$entrenadorId': FieldValue.delete(),
        'entrenadorId': FieldValue.delete(),
      });
      _marcarEntrenadores(transaccion, [entrenadorId]);
    });
  }

  @override
  Future<void> guardarDisciplina(Deporte deporte) {
    final nueva = deporte.id.isEmpty;
    final referencia = nueva
        ? _firestore.sports.doc()
        : _firestore.sports.doc(deporte.id);
    final guardada = Deporte(
      id: referencia.id,
      nombre: deporte.nombre,
      disciplina: deporte.disciplina,
      cupos: deporte.cupos,
      entrenadoresIds: deporte.entrenadoresIds,
      entrenadoresNombres: deporte.entrenadoresNombres,
      horarios: deporte.horarios,
      bloques: deporte.bloques,
      lugar: deporte.lugar,
      etiquetas: deporte.etiquetas,
    );

    return _enTransaccion((transaccion) async {
      if (!nueva) {
        final doc = await transaccion.get(referencia);
        if (!doc.exists) {
          throw const GestionEntrenadoresException(
            'La disciplina ya no existe.',
          );
        }
      }
      await _bloquearEntrenadores(transaccion, guardada.entrenadoresIds);
      for (final uid in guardada.entrenadoresIds) {
        await _validarChoques(
          deporte: guardada,
          entrenadorId: uid,
          entrenadorNombre:
              guardada.entrenadoresNombres[uid] ?? 'el entrenador',
        );
      }

      final datos = guardada.toJson();
      if (nueva) {
        transaccion.set(referencia, datos);
      } else {
        // `update` reemplaza los campos enviados y conserva los demás.
        transaccion.update(referencia, {
          ...datos,
          'entrenadorId': FieldValue.delete(),
        });
      }
      _marcarEntrenadores(transaccion, guardada.entrenadoresIds);
    });
  }

  /// Lee el perfil de cada entrenador dentro de la transacción. Así, si otra
  /// transacción cambia al mismo entrenador al mismo tiempo, una de las dos
  /// se repite (ver la documentación de la clase).
  Future<void> _bloquearEntrenadores(
    Transaction transaccion,
    List<String> uids,
  ) async {
    for (final uid in uids) {
      await transaccion.get(_firestore.users.doc(uid));
    }
  }

  void _marcarEntrenadores(Transaction transaccion, List<String> uids) {
    for (final uid in uids) {
      transaccion.update(_firestore.users.doc(uid), {
        'horarioActualizado': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Consulta las disciplinas actuales del entrenador y lanza
  /// [ChoqueHorarioException] si alguna se cruza con [deporte]. Corre dentro
  /// de la transacción: si esta se repite, la consulta también.
  Future<void> _validarChoques({
    required Deporte deporte,
    required String entrenadorId,
    required String entrenadorNombre,
  }) async {
    final docs = await _firestore.disciplinasDe(entrenadorId);
    final choques = buscarChoques(
      bloques: deporte.bloques,
      asignadas: docs.map(Deporte.fromFirestore),
      disciplinaId: deporte.id,
    );
    final mensaje = mensajeDeChoques(
      entrenador: entrenadorNombre,
      disciplina: deporte.nombre,
      choques: choques,
    );
    if (mensaje != null) throw ChoqueHorarioException(mensaje, choques);
  }

  Future<void> _enTransaccion(
    Future<void> Function(Transaction transaccion) cambios,
  ) async {
    try {
      await _firestore.db.runTransaction(cambios);
    } on FirebaseException catch (e) {
      throw GestionEntrenadoresException(
        e.code == 'permission-denied'
            ? 'No tienes permiso para cambiar las disciplinas.'
            : 'No se pudo guardar el cambio. Revisa tu conexión e intenta de nuevo.',
      );
    }
  }
}
