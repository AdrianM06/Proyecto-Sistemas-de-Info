import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/resena.dart';
import 'firestore_service.dart';

/// Interfaz para abstraer la fuente de datos de las reseñas.
abstract class ResenasDataSource {
  /// Obtiene un flujo en tiempo real de las resenas de un deporte.
  Stream<List<Resena>> resenasDe(String deporteId);
  
  /// Guarda una nueva resena en la base de datos.
  Future<void> agregarResena(String deporteId, Resena resena);
}

/// Implementación real que se conecta a Firestore.
class ResenasService implements ResenasDataSource {
  ResenasService({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService.instance;

  final FirestoreService _firestore;

  @override
  Stream<List<Resena>> resenasDe(String deporteId) {
    // Usamos el método reviewsOf que creamos en la Fase 2
    return _firestore
        .reviewsOf(deporteId)
        .orderBy('fecha', descending: true) // Las más recientes primero
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Resena.fromFirestore).toList());
  }

  @override
  Future<void> agregarResena(String deporteId, Resena resena) async {
    await _firestore.reviewsOf(deporteId).add(resena.toJson());
  }
}
