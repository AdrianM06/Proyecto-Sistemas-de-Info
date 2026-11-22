import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/deporte.dart';
import '../models/inscripcion.dart';
import 'firestore_service.dart';

/// Combina una [Inscripcion] pagada con los datos del [Deporte] asociado.
class ComprobantePago {
  const ComprobantePago({
    required this.inscripcion,
    required this.nombreDeporte,
    required this.disciplina,
  });

  final Inscripcion inscripcion;
  final String nombreDeporte;
  final String disciplina;

  String get orderId => inscripcion.paypalOrderId ?? 'Sin ID';
  double get monto => inscripcion.montoPagado ?? 0.0;
  DateTime? get fecha => inscripcion.fechaInscripcion;
  String? get correoPagador => inscripcion.paypalPayerEmail;
  bool get inscripcionActiva => inscripcion.estaActiva;
}

abstract class PagosDataSource {
  Future<List<ComprobantePago>> pagosDeEstudiante(String estudianteId);
}

class PagosService implements PagosDataSource {
  PagosService({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService.instance;

  final FirestoreService _firestore;

  @override
  Future<List<ComprobantePago>> pagosDeEstudiante(String estudianteId) async {
    final resultados = await Future.wait([
      _firestore.enrollments
          .where('estudianteId', isEqualTo: estudianteId)
          .get(),
      _firestore.sports.get(),
    ]);

    final inscripcionesSnap =
        resultados[0] as QuerySnapshot>;
    final deportesSnap = resultados[1] as QuerySnapshot>;

    final deportesPorId = <String, Deporte>{
      for (final doc in deportesSnap.docs) doc.id: Deporte.fromFirestore(doc),
    };

    final comprobantes = <ComprobantePago>[];
    for (final doc in inscripcionesSnap.docs) {
      final inscripcion = Inscripcion.fromFirestore(doc);
      final tienePago = inscripcion.paypalOrderId != null ||
          inscripcion.montoPagado != null;
      if (!tienePago) continue;

      final deporte = deportesPorId[inscripcion.deporteId];
      comprobantes.add(
        ComprobantePago(
          inscripcion: inscripcion,
          nombreDeporte: deporte?.nombre ?? 'Disciplina deportiva',
          disciplina: deporte?.disciplina ?? '',
        ),
      );
    }

    // Ordena del más reciente al más antiguo en memoria.
    comprobantes.sort((a, b) {
      final fechaA = a.fecha ?? DateTime.fromMillisecondsSinceEpoch(0);
      final fechaB = b.fecha ?? DateTime.fromMillisecondsSinceEpoch(0);
      return fechaB.compareTo(fechaA);
    });

    return comprobantes;
  }
}
