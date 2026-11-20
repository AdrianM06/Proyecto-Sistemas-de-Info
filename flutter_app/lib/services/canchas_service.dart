import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cancha.dart';

class CanchasException implements Exception {
  const CanchasException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

abstract class CanchasDataSource {
  Stream<List<Cancha>> canchas();
  Future<void> crearCancha({required String nombre, String ubicacion = ''});
  Future<void> cambiarEstado(String id, bool activa);
  Future<void> eliminarCancha(String id);
}

class CanchasService implements CanchasDataSource {
  CanchasService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference> get _coleccion =>
      _firestore.collection('courts');

  @override
  Stream<List<Cancha>> canchas() {
    return _coleccion.snapshots().map((snap) {
      final lista = snap.docs.map(Cancha.fromFirestore).toList()
        ..sort(
          (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
        );
      return lista;
    });
  }

  @override
  Future<void> crearCancha({
    required String nombre,
    String ubicacion = '',
  }) async {
    final limpio = nombre.trim();
    if (limpio.isEmpty) {
      throw const CanchasException('Ingresa el nombre de la cancha.');
    }

    try {
      final existentes = await _coleccion.get();
      final duplicada = existentes.docs.any(
        (d) =>
            (d.data()['nombre'] ?? '').toString().trim().toLowerCase() ==
            limpio.toLowerCase(),
      );
      if (duplicada) {
        throw const CanchasException('Ya existe una cancha con ese nombre.');
      }

      await _coleccion.add({
        'nombre': limpio,
        'ubicacion': ubicacion.trim(),
        'activa': true,
      });
    } on CanchasException {
      rethrow;
    } on FirebaseException catch (e) {
      throw CanchasException(
        e.code == 'permission-denied'
            ? 'No tienes permiso para agregar canchas.'
            : 'No se pudo guardar la cancha. Intenta de nuevo.',
      );
    }
  }

  @override
  Future<void> cambiarEstado(String id, bool activa) async {
    try {
      await _coleccion.doc(id).update({'activa': activa});
    } on FirebaseException {
      throw const CanchasException('No se pudo actualizar la cancha.');
    }
  }

  @override
  Future<void> eliminarCancha(String id) async {
    try {
      await _coleccion.doc(id).delete();
    } on FirebaseException {
      throw const CanchasException('No se pudo eliminar la cancha.');
    }
  }
}
