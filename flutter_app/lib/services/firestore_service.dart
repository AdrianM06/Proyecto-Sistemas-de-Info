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

  /// Índice de carnets: `carnets/{carnet}` -> `{uid, email}`. Garantiza que
  /// un carnet no se registre dos veces y permite iniciar sesión con él.
  CollectionReference<Map<String, dynamic>> get carnets =>
      db.collection('carnets');

  /// Índice de cédulas: `cedulas/{V-12345678}` -> `{uid}`.
  CollectionReference<Map<String, dynamic>> get cedulas =>
      db.collection('cedulas');

  /// Reseñas de una disciplina: `sports/{deporteId}/reviews/{estudianteId}`.
  CollectionReference<Map<String, dynamic>> reviewsOf(String deporteId) =>
      sports.doc(deporteId).collection('reviews');

  /// Documentos de `sports` que dicta el entrenador.
  ///
  /// Consulta `entrenadoresIds` con `arrayContains`. Mientras queden
  /// disciplinas con el campo viejo `entrenadorId` (un solo entrenador),
  /// también las busca con `isEqualTo` y une los resultados; cada vez que el
  /// administrador cambia los entrenadores de una disciplina, el campo viejo
  /// se borra y la disciplina queda migrada.
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> disciplinasDe(
    String entrenadorId,
  ) async {
    final resultados = await Future.wait([
      sports.where('entrenadoresIds', arrayContains: entrenadorId).get(),
      sports.where('entrenadorId', isEqualTo: entrenadorId).get(),
    ]);
    final porId = <String, DocumentSnapshot<Map<String, dynamic>>>{};
    for (final resultado in resultados) {
      for (final doc in resultado.docs) {
        porId[doc.id] = doc;
      }
    }
    return porId.values.toList();
  }
}
