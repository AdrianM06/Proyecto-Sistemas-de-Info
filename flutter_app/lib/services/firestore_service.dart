import 'package:cloud_firestore/cloud_firestore.dart';

/// Patrón Singleton: única puerta de acceso a Cloud Firestore en toda la app.
///
/// Todas las pantallas y controladores usan la misma instancia, en lugar de
/// abrir una conexión nueva cada vez. Así se evita el consumo extra de
/// memoria y red descrito en la sección 2.3 del documento del Hito 2.
///
/// Uso:
/// ```dart
/// final deportes = FirestoreService.instance.sports;
/// ```
class FirestoreService {
  FirestoreService._interno();

  static final FirestoreService _instancia = FirestoreService._interno();

  /// La única instancia del servicio.
  static FirestoreService get instance => _instancia;

  /// `FirestoreService()` siempre devuelve la misma instancia.
  factory FirestoreService() => _instancia;

  /// Cliente de Firestore. Se pide de forma diferida para que la app solo
  /// lo use cuando Firebase ya fue inicializado.
  FirebaseFirestore get db => FirebaseFirestore.instance;

  /// Colecciones definidas en la sección 3.1 del documento del Hito 2.
  CollectionReference<Map<String, dynamic>> get users => db.collection('users');
  CollectionReference<Map<String, dynamic>> get sports =>
      db.collection('sports');
  CollectionReference<Map<String, dynamic>> get enrollments =>
      db.collection('enrollments');
  CollectionReference<Map<String, dynamic>> get attendances =>
      db.collection('attendances');
}
