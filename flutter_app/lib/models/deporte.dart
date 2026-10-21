import 'package:cloud_firestore/cloud_firestore.dart';

import 'conversores.dart';

/// Modelo de un documento de la colección `sports` de Cloud Firestore.
///
/// Campos según el documento del Hito 2: nombre, disciplina, cupos,
/// entrenadorId, horarios (lista) y lugar. `cupos` es el cupo máximo de la
/// disciplina.
///
/// Este modelo lo comparten la vista del entrenador y el buscador de
/// deportes.
class Deporte {
  const Deporte({
    required this.id,
    required this.nombre,
    required this.disciplina,
    required this.cupos,
    required this.entrenadorId,
    this.horarios = const [],
    this.lugar = '',
  });

  final String id;
  final String nombre;
  final String disciplina;
  final int cupos;
  final String entrenadorId;
  final List<String> horarios;
  final String lugar;

  /// Horarios en una sola línea, por ejemplo "Lun 4:00 pm · Mié 4:00 pm".
  String get horariosTexto =>
      horarios.isEmpty ? 'Horario por definir' : horarios.join(' · ');

  /// Patrón Factory Method: crea un [Deporte] a partir del mapa guardado en
  /// Firestore. Acepta los horarios como textos ("Lun 4:00-6:00 pm") o como
  /// mapas ({dia, horaInicio, horaFin}).
  factory Deporte.fromJson(Map<String, dynamic> json, {required String id}) {
    return Deporte(
      id: id,
      nombre: textoDe(json['nombre'], porDefecto: 'Sin nombre'),
      disciplina: textoDe(json['disciplina']),
      cupos: enteroDe(json['cupos']),
      entrenadorId: textoDe(json['entrenadorId']),
      horarios: _leerHorarios(json['horarios']),
      lugar: textoDe(json['lugar']),
    );
  }

  /// Crea un [Deporte] directamente desde un documento de Firestore.
  factory Deporte.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Deporte.fromJson(doc.data() ?? const {}, id: doc.id);
  }

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'disciplina': disciplina,
        'cupos': cupos,
        'entrenadorId': entrenadorId,
        'horarios': horarios,
        'lugar': lugar,
      };

  static List<String> _leerHorarios(dynamic valor) {
    if (valor is! Iterable) return const [];
    final horarios = <String>[];
    for (final elemento in valor) {
      if (elemento is Map) {
        final dia = textoDe(elemento['dia']);
        final inicio = textoDe(elemento['horaInicio']);
        final fin = textoDe(elemento['horaFin']);
        final rango = [inicio, fin].where((hora) => hora.isNotEmpty).join('–');
        final texto = [dia, rango].where((parte) => parte.isNotEmpty).join(' ');
        if (texto.isNotEmpty) horarios.add(texto);
      } else if (elemento != null) {
        horarios.add(elemento.toString());
      }
    }
    return horarios;
  }
}
