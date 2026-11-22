import 'package:cloud_firestore/cloud_firestore.dart';

import 'bloque_horario.dart';
import 'conversores.dart';

class EventoDeportivo {
  const EventoDeportivo({
    required this.id,
    required this.titulo,
    required this.deporteId,
    required this.deporteNombre,
    required this.canchaId,
    required this.canchaNombre,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    this.descripcion = '',
    this.creadoPor = '',
  });

  final String id;
  final String titulo;
  final String descripcion;
  final String deporteId;
  final String deporteNombre;
  final String canchaId;
  final String canchaNombre;
  final DateTime fecha;
  final int horaInicio;
  final int horaFin;
  final String creadoPor;

  String get horarioTexto =>
      '${BloqueHorario.horaTexto(horaInicio)} – ${BloqueHorario.horaTexto(horaFin)}';

  bool ocurreEl(DateTime dia) =>
      fecha.year == dia.year &&
      fecha.month == dia.month &&
      fecha.day == dia.day;

  bool chocaEnCanchaCon(EventoDeportivo otro) {
    if (id.isNotEmpty && id == otro.id) return false;
    if (canchaId != otro.canchaId || !ocurreEl(otro.fecha)) return false;
    return horaInicio < otro.horaFin && otro.horaInicio < finReal(otro);
  }

  int finReal(EventoDeportivo otro) => otro.horaFin;

  factory EventoDeportivo.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final fechaCruda = fechaDe(json['fecha']) ?? DateTime.now();
    return EventoDeportivo(
      id: id,
      titulo: textoDe(json['titulo'], porDefecto: 'Evento deportivo'),
      descripcion: textoDe(json['descripcion']),
      deporteId: textoDe(json['deporteId']),
      deporteNombre: textoDe(json['deporteNombre']),
      canchaId: textoDe(json['canchaId']),
      canchaNombre: textoDe(json['canchaNombre']),
      fecha: soloFecha(fechaCruda),
      horaInicio: enteroDe(json['horaInicio'], porDefecto: 480),
      horaFin: enteroDe(json['horaFin'], porDefecto: 600),
      creadoPor: textoDe(json['creadoPor']),
    );
  }

  factory EventoDeportivo.fromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>?;
  return EventoDeportivo.fromJson(data ?? const {}, id: doc.id);
}

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'descripcion': descripcion,
        'deporteId': deporteId,
        'deporteNombre': deporteNombre,
        'canchaId': canchaId,
        'canchaNombre': canchaNombre,
        'fecha': Timestamp.fromDate(soloFecha(fecha)),
        'horaInicio': horaInicio,
        'horaFin': horaFin,
        'creadoPor': creadoPor,
      };
}
