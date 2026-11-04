import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/deporte.dart';
import '../models/inscripcion.dart';
import 'firestore_service.dart';

/// Datos en tiempo real del inicio del estudiante.
///
/// El controlador depende de esta interfaz; así funciona con Firestore
/// ([InicioEstudianteService]) o con flujos en memoria en las pruebas.
abstract class InicioEstudianteDataSource {
  /// Ids de los deportes donde el estudiante tiene una inscripción activa.
  /// Emite de nuevo cada vez que cambian sus inscripciones.
  Stream<Set<String>> deportesInscritos(String estudianteId);

  /// Todos los deportes. Emite de nuevo cuando cambia alguno (por ejemplo,
  /// si el administrador cambia un horario).
  Stream<List<Deporte>> deportes();
}

/// Implementación real: escucha `enrollments` y `sports` con `snapshots()`.
class InicioEstudianteService implements InicioEstudianteDataSource {
  InicioEstudianteService({FirestoreService? firestore})
    : _firestore = firestore ?? FirestoreService.instance;

  final FirestoreService _firestore;

  @override
  Stream<Set<String>> deportesInscritos(String estudianteId) {
    return _firestore.enrollments
        .where('estudianteId', isEqualTo: estudianteId)
        .snapshots()
        .map((resultado) {
          final inscripciones = resultado.docs.map(Inscripcion.fromFirestore);
          return {
            for (final inscripcion in inscripciones)
              if (inscripcion.estaActiva && inscripcion.deporteId.isNotEmpty)
                inscripcion.deporteId,
          };
        });
  }

  @override
  Stream<List<Deporte>> deportes() {
    return _firestore.sports.snapshots().map(
      (resultado) => resultado.docs.map(Deporte.fromFirestore).toList(),
    );
  }
}
