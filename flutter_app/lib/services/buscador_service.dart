import '../models/deporte.dart';
import '../models/inscripcion.dart';
import 'firestore_service.dart';

/// Operaciones de datos que necesita el buscador de deportes.
///
/// El controlador depende de esta interfaz y no de Firestore directamente,
/// así funciona igual con [BuscadorService] (real) o con
/// `BuscadorDemoService` (datos de ejemplo).
abstract class BuscadorDataSource {
  /// Todos los documentos de la colección `sports`.
  Future<List<Deporte>> todosLosDeportes();

  /// Inscripciones activas por deporte: {deporteId: cantidad}.
  Future<Map<String, int>> inscritosPorDeporte();
}

/// Implementación real con Cloud Firestore. Usa el Singleton
/// [FirestoreService] y las colecciones `sports` y `enrollments`.
///
/// Los datos se piden una sola vez; buscar y filtrar se hace en memoria, así
/// que no hacen falta índices compuestos.
class BuscadorService implements BuscadorDataSource {
  BuscadorService({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService.instance;

  final FirestoreService _firestore;

  @override
  Future<List<Deporte>> todosLosDeportes() async {
    final resultado = await _firestore.sports.get();
    return resultado.docs.map(Deporte.fromFirestore).toList();
  }

  @override
  Future<Map<String, int>> inscritosPorDeporte() async {
    final resultado = await _firestore.enrollments.get();
    final conteo = <String, int>{};
    for (final doc in resultado.docs) {
      final inscripcion = Inscripcion.fromFirestore(doc);
      if (!inscripcion.estaActiva || inscripcion.deporteId.isEmpty) continue;
      conteo.update(inscripcion.deporteId, (n) => n + 1, ifAbsent: () => 1);
    }
    return conteo;
  }
}
