import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/deporte.dart';
import '../models/resumen_admin.dart';
import 'firestore_service.dart';

/// Datos del resumen del panel del administrador.
///
/// El panel depende de esta interfaz y no de Firestore directamente, así las
/// pruebas usan datos de ejemplo.
abstract class ResumenAdminDataSource {
  /// Cuenta estudiantes, entrenadores, disciplinas, inscripciones y cupos.
  Future<ResumenAdmin> cargar();
}

/// Implementación real con Cloud Firestore.
///
/// Usa consultas de agregación (`count()`): Firestore devuelve solo el número,
/// sin descargar los documentos, así el resumen es rápido y barato aunque haya
/// muchos usuarios. Las reglas solo dejan listar `users` al personal (admin
/// o entrenador).
class ResumenAdminService implements ResumenAdminDataSource {
  ResumenAdminService({FirestoreService? firestore})
    : _firestore = firestore ?? FirestoreService.instance;

  final FirestoreService _firestore;

  static Future<int> _contar(Query<Map<String, dynamic>> consulta) async {
    final resultado = await consulta.count().get();
    return resultado.count ?? 0;
  }

  @override
  Future<ResumenAdmin> cargar() async {
    final estudiantes = _firestore.users.where('rol', isEqualTo: 'estudiante');
    final conteos = await Future.wait([
      _contar(estudiantes),
      _contar(estudiantes.where('estadoActivo', isEqualTo: false)),
      _contar(_firestore.users.where('rol', isEqualTo: 'entrenador')),
      _contar(_firestore.enrollments.where('estado', isEqualTo: 'activa')),
    ]);

    // Las disciplinas son pocas: se leen completas para sumar los cupos y
    // contar las que no tienen entrenador.
    final deportes = (await _firestore.sports.get()).docs
        .map(Deporte.fromFirestore)
        .where((d) => d.nombre.trim().isNotEmpty && d.nombre != 'Sin nombre')
        .toList();

    return ResumenAdmin(
      estudiantes: conteos[0],
      estudiantesDeshabilitados: conteos[1],
      entrenadores: conteos[2],
      inscripcionesActivas: conteos[3],
      disciplinas: deportes.length,
      disciplinasSinEntrenador: deportes.where((d) => d.sinEntrenadores).length,
      cuposTotales: deportes.fold(
        0,
        (suma, d) => suma + (d.cupos > 0 ? d.cupos : 0),
      ),
    );
  }
}
