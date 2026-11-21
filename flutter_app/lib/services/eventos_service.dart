import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

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
  EventosService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<EventoDeportivo>> eventos() {
    if (_firestore == null && Firebase.apps.isEmpty) {
      return const Stream.empty();
    }
    return _db.collection('events').snapshots().map((snap) {
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
      final coleccion = _db.collection('events');
      final snap = await coleccion.get();
      final existentes = snap.docs.map(EventoDeportivo.fromFirestore);
      for (final otro in existentes) {
        if (evento.chocaEnCanchaCon(otro)) {
          throw EventosException(
            'La cancha "${evento.canchaNombre}" ya está ocupada por '
            '"${otro.titulo}" (${otro.horarioTexto}).',
          );
        }
      }
      await coleccion.add(evento.toJson());
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
      await _db.collection('events').doc(id).delete();
    } on FirebaseException {
      throw const EventosException('No se pudo eliminar el evento.');
    }
  }
}
