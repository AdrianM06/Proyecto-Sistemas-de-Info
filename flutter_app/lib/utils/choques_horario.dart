import '../models/bloque_horario.dart';
import '../models/deporte.dart';

/// Un choque de horario: un bloque de la disciplina que se quiere asignar
/// cae el mismo día y a la misma hora que un bloque de otra disciplina del
/// entrenador.
class ChoqueHorario {
  const ChoqueHorario({
    required this.nuevo,
    required this.existente,
    required this.deporte,
  });

  /// Bloque de la disciplina que se quiere asignar.
  final BloqueHorario nuevo;

  /// Bloque con el que choca.
  final BloqueHorario existente;

  /// Disciplina que el entrenador ya tiene y con la que choca.
  final Deporte deporte;

  /// "Lun 4:00 pm – 6:00 pm choca con Fútbol (Lun 5:00 pm – 7:00 pm)".
  String get descripcion =>
      '${nuevo.texto} choca con ${deporte.nombre} (${existente.texto})';
}

/// Compara los [bloques] de una disciplina con los de las disciplinas que el
/// entrenador ya tiene ([asignadas]) y devuelve todos los choques.
///
/// [disciplinaId] es la disciplina que se está asignando: si ya estuviera
/// entre las asignadas, no se compara consigo misma.
List<ChoqueHorario> buscarChoques({
  required List<BloqueHorario> bloques,
  required Iterable<Deporte> asignadas,
  String? disciplinaId,
}) {
  final choques = <ChoqueHorario>[];
  for (final deporte in asignadas) {
    if (deporte.id == disciplinaId) continue;
    for (final existente in deporte.bloques) {
      for (final nuevo in bloques) {
        if (nuevo.seSolapaCon(existente)) {
          choques.add(
            ChoqueHorario(nuevo: nuevo, existente: existente, deporte: deporte),
          );
        }
      }
    }
  }
  return choques;
}

/// Mensaje para el administrador cuando hay choques, o `null` si no hay.
String? mensajeDeChoques({
  required String entrenador,
  required String disciplina,
  required List<ChoqueHorario> choques,
}) {
  if (choques.isEmpty) return null;
  final detalles = {for (final choque in choques) '• ${choque.descripcion}'};
  return 'No se puede asignar $disciplina a $entrenador porque se cruza con '
      'otra disciplina que ya dicta:\n${detalles.join('\n')}';
}

/// Excepción que lanzan los servicios cuando una asignación chocaría con el
/// horario del entrenador. [mensaje] está listo para mostrar.
class ChoqueHorarioException implements Exception {
  const ChoqueHorarioException(this.mensaje, this.choques);

  final String mensaje;
  final List<ChoqueHorario> choques;

  @override
  String toString() => mensaje;
}
