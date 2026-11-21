import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/evento.dart';

class EventosException implements Exception {
  const EventosException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

abstract class EventosDataSource {
  Stream<List<EventoDeportivo>> eventos();
  Future<void> crearEvento(EventoDeportivo evento);
  Future<void> eliminarEvento(String id);
}

class EventosService implements EventosDataSource {
  EventosService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  late final _coleccion = _firestore.collection('events');

  @override
  Stream<List<EventoDeportivo>> eventos() {
    return _coleccion.snapshots().map((snap) {
      final lista = snap.docs.map(EventoDeportivo.fromFirestore).toList()
        ..sort((a, b) {
          final cmp = a.fecha.compareTo(b.fecha);
          return cmp != 0 ? cmp : a.horaInicio.compareTo(b.horaInicio);
        });
      return lista;
    });
  }

  @override
  Future<void> crearEvento(EventoDeportivo evento) async {
    try {
      final snap = await _coleccion.get();
      final existentes = snap.docs.map(EventoDeportivo.fromFirestore);
      for (final otro in existentes) {
        if (evento.chocaEnCanchaCon(otro)) {
          throw EventosException(
            'La cancha "${evento.canchaNombre}" ya está ocupada por '
            '"${otro.titulo}" (${otro.horarioTexto}).',
          );
        }
      }
      await _coleccion.add(evento.toJson());
    } on EventosException {
      rethrow;
    } on FirebaseException catch (e) {
      throw EventosException(
        e.code == 'permission-denied'
            ? 'Solo el administrador puede crear eventos.'
            : 'No se pudo guardar el evento. Intenta de nuevo.',
      );
    }
  }

  @override
  Future<void> eliminarEvento(String id) async {
    try {
      await _coleccion.doc(id).delete();
    } on FirebaseException {
      throw const EventosException('No se pudo eliminar el evento.');
    }
  }
}
