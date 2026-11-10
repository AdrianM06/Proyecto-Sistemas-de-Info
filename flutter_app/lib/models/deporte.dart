import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/horarios.dart';
import 'bloque_horario.dart';
import 'conversores.dart';

/// Modelo de un documento de la colección `sports` de Cloud Firestore.
///
/// Campos: nombre, disciplina, cupos (cupo máximo), horarios (textos para
/// mostrar), bloquesHorario (los mismos horarios estructurados), diasSemana,
/// horaMinima, horaMaxima, entrenadoresIds, entrenadoresNombres, lugar y
/// etiquetas.
///
/// Una disciplina puede tener **varios entrenadores** (`entrenadoresIds`).
/// Los documentos viejos guardaban uno solo en `entrenadorId`; este modelo
/// los sigue leyendo y lo pasa a la lista.
///
/// Este modelo lo comparten la vista del entrenador, el buscador de deportes
/// y el panel del administrador.
class Deporte {
  const Deporte({
    required this.id,
    required this.nombre,
    required this.disciplina,
    required this.cupos,
    this.entrenadoresIds = const [],
    this.entrenadoresNombres = const {},
    this.horarios = const [],
    List<BloqueHorario>? bloques,
    this.lugar = '',
    this.etiquetas = const [],
  }) : _bloques = bloques;

  final String id;
  final String nombre;
  final String disciplina;
  final int cupos;

  /// Uids de los entrenadores de la disciplina.
  final List<String> entrenadoresIds;

  /// Nombre de cada entrenador (uid → "Nombre Apellido"). Se guarda en la
  /// disciplina porque los estudiantes no pueden leer los perfiles de los
  /// entrenadores.
  final Map<String, String> entrenadoresNombres;

  /// Horarios como texto, tal como se muestran: "Lun 4:00–6:00 pm".
  final List<String> horarios;
  final String lugar;
  final List<String> etiquetas;

  final List<BloqueHorario>? _bloques;

  /// Horarios estructurados (día + hora de inicio + hora de fin). Si el
  /// documento no los trae, se obtienen interpretando [horarios].
  List<BloqueHorario> get bloques => _bloques ?? bloquesDeHorarios(horarios);

  /// Días de la semana con entrenamiento (1 = lunes ... 7 = domingo).
  Set<int> get diasDeEntrenamiento => {
    for (final bloque in bloques) bloque.dia,
    ...diasDeEntrenamientoDe(horarios),
  };

  /// `true` si la disciplina entrena el día de [fecha].
  bool entrenaEl(DateTime fecha) => diasDeEntrenamiento.contains(fecha.weekday);

  /// Horarios en una sola línea, por ejemplo "Lun 4:00 pm · Mié 4:00 pm".
  String get horariosTexto =>
      horarios.isEmpty ? 'Horario por definir' : horarios.join(' · ');

  bool tieneEntrenador(String uid) => entrenadoresIds.contains(uid);
  bool get sinEntrenadores => entrenadoresIds.isEmpty;

  /// Nombres de los entrenadores, en el orden de [entrenadoresIds]. Los que
  /// no tienen nombre guardado no aparecen.
  List<String> get nombresDeEntrenadores => [
    for (final uid in entrenadoresIds)
      if ((entrenadoresNombres[uid] ?? '').trim().isNotEmpty)
        entrenadoresNombres[uid]!.trim(),
  ];

  /// "Ana Pérez, Luis Gómez", o "Por asignar" si no hay entrenadores.
  String get entrenadoresTexto {
    if (entrenadoresIds.isEmpty) return 'Por asignar';
    final nombres = nombresDeEntrenadores;
    if (nombres.isEmpty) {
      return entrenadoresIds.length == 1
          ? '1 entrenador'
          : '${entrenadoresIds.length} entrenadores';
    }
    return nombres.join(', ');
  }

  /// Copia de la disciplina con otros entrenadores.
  Deporte conEntrenadores(List<String> ids, [Map<String, String>? nombres]) {
    return Deporte(
      id: id,
      nombre: nombre,
      disciplina: disciplina,
      cupos: cupos,
      entrenadoresIds: List.unmodifiable(ids),
      entrenadoresNombres: Map.unmodifiable(nombres ?? entrenadoresNombres),
      horarios: horarios,
      bloques: _bloques,
      lugar: lugar,
      etiquetas: etiquetas,
    );
  }

  /// Patrón Factory Method: crea un [Deporte] a partir del mapa guardado en
  /// Firestore. Acepta los horarios como textos ("Lun 4:00-6:00 pm") o como
  /// mapas ({dia, horaInicio, horaFin}), y el entrenador viejo
  /// (`entrenadorId`) o la lista nueva (`entrenadoresIds`).
  factory Deporte.fromJson(Map<String, dynamic> json, {required String id}) {
    return Deporte(
      id: id,
      nombre: textoDe(json['nombre'], porDefecto: 'Sin nombre'),
      disciplina: textoDe(json['disciplina']),
      cupos: enteroDe(json['cupos']),
      entrenadoresIds: leerEntrenadoresIds(json),
      entrenadoresNombres: _leerNombres(json['entrenadoresNombres']),
      horarios: _leerHorarios(json['horarios']),
      bloques: _leerBloques(json['bloquesHorario']),
      lugar: textoDe(json['lugar']),
      etiquetas:
          (json['etiquetas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
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
    'entrenadoresIds': entrenadoresIds,
    'entrenadoresNombres': entrenadoresNombres,
    'horarios': horarios,
    ...camposDeHorario(bloques),
    'lugar': lugar,
    'etiquetas': etiquetas,
  };

  /// Campos consultables que se derivan de los bloques:
  /// - `bloquesHorario`: `[{dia: 1, inicio: 960, fin: 1080}, ...]`, con las
  ///   horas en minutos desde la medianoche.
  /// - `diasSemana`: `[1, 3]`, para consultas `arrayContains` por día.
  /// - `horaMinima` / `horaMaxima`: la hora más temprana de inicio y la más
  ///   tardía de fin, para consultas por rango de horas, por ejemplo
  ///   `where('horaMinima', isGreaterThanOrEqualTo: 840)`.
  static Map<String, dynamic> camposDeHorario(List<BloqueHorario> bloques) {
    final ordenados = [...bloques]..sort();
    return {
      'bloquesHorario': [for (final bloque in ordenados) bloque.toJson()],
      'diasSemana': {for (final bloque in ordenados) bloque.dia}.toList()
        ..sort(),
      'horaMinima': ordenados.isEmpty
          ? null
          : ordenados.map((b) => b.inicio).reduce((a, b) => a < b ? a : b),
      'horaMaxima': ordenados.isEmpty
          ? null
          : ordenados.map((b) => b.fin).reduce((a, b) => a > b ? a : b),
    };
  }

  /// Uids de los entrenadores de un documento de `sports`, incluido el
  /// campo viejo `entrenadorId` si todavía existe.
  static List<String> leerEntrenadoresIds(Map<String, dynamic> json) {
    final ids = <String>[];
    final lista = json['entrenadoresIds'];
    if (lista is Iterable) {
      for (final valor in lista) {
        final uid = textoDe(valor).trim();
        if (uid.isNotEmpty && !ids.contains(uid)) ids.add(uid);
      }
    }
    final viejo = textoDe(json['entrenadorId']).trim();
    if (viejo.isNotEmpty && !ids.contains(viejo)) ids.add(viejo);
    return ids;
  }

  static Map<String, String> _leerNombres(dynamic valor) {
    if (valor is! Map) return const {};
    return {
      for (final entrada in valor.entries)
        if (textoDe(entrada.value).trim().isNotEmpty)
          entrada.key.toString(): textoDe(entrada.value).trim(),
    };
  }

  static List<BloqueHorario>? _leerBloques(dynamic valor) {
    if (valor is! Iterable) return null;
    final bloques = <BloqueHorario>[
      for (final elemento in valor) ?BloqueHorario.fromJson(elemento),
    ];
    return bloques.isEmpty ? null : (bloques..sort());
  }

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
