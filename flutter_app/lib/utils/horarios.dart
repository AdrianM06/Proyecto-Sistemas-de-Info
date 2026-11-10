import '../models/bloque_horario.dart';

/// Abreviaturas de los días, de lunes (posición 0) a domingo (posición 6).
/// El número de día es el mismo de `DateTime.weekday`: lunes = 1, domingo = 7.
const List<String> abreviaturasDias = [
  'Lun',
  'Mar',
  'Mié',
  'Jue',
  'Vie',
  'Sáb',
  'Dom',
];

const List<String> nombresDias = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

const Map<String, int> _porPrefijo = {
  'lun': 1,
  'mar': 2,
  'mie': 3,
  'jue': 4,
  'vie': 5,
  'sab': 6,
  'dom': 7,
};

final RegExp _dia = RegExp(
  r'\b(lunes|lun|martes|mar|miercoles|mie|jueves|jue|viernes|vie|sabados|sabado|sab|domingos|domingo|dom)\b',
);

/// Texto que une dos días y significa "desde ... hasta", por ejemplo
/// "Lun a Vie" o "Lun - Vie".
const Set<String> _unionDeRango = {'a', 'al', 'hasta', '-', '–', '—'};

String _plano(String texto) {
  const origen = 'áéíóúüñ';
  const destino = 'aeiouun';
  final buffer = StringBuffer();
  for (final letra in texto.toLowerCase().split('')) {
    final posicion = origen.indexOf(letra);
    buffer.write(posicion == -1 ? letra : destino[posicion]);
  }
  return buffer.toString();
}

/// Días de la semana (1 = lunes ... 7 = domingo) que nombra un horario.
///
/// El administrador escribe los horarios como texto libre, así que acepta
/// varios días en una línea: "Lun y Mié 2:00 PM - 4:00 PM", "Martes, Jueves
/// 5 pm", "Lun a Vie 7:00 am". Una línea sin días devuelve un conjunto
/// vacío.
Set<int> diasDeSemanaDe(String horario) {
  final texto = _plano(horario);
  final coincidencias = _dia.allMatches(texto).toList();
  final dias = <int>{};
  for (var i = 0; i < coincidencias.length; i++) {
    final dia = _porPrefijo[coincidencias[i].group(1)!.substring(0, 3)]!;
    dias.add(dia);
    if (i == 0) continue;
    final anterior =
        _porPrefijo[coincidencias[i - 1].group(1)!.substring(0, 3)]!;
    final entre = texto
        .substring(coincidencias[i - 1].end, coincidencias[i].start)
        .trim();
    if (_unionDeRango.contains(entre)) {
      var actual = anterior;
      while (actual != dia) {
        actual = actual % 7 + 1;
        dias.add(actual);
      }
    }
  }
  return dias;
}

/// Unión de los días de todos los horarios de una disciplina.
Set<int> diasDeEntrenamientoDe(Iterable<String> horarios) {
  return {for (final horario in horarios) ...diasDeSemanaDe(horario)};
}

/// Número de día (1 = lunes) de una abreviatura como "Mié", o `null`.
int? numeroDeDia(String abreviatura) {
  final plano = _plano(abreviatura.trim());
  if (plano.length < 3) return null;
  return _porPrefijo[plano.substring(0, 3)];
}

// ------------------------------------------------------- horas estructuradas

/// Resultado de interpretar una línea de horario como "Lun y Mié 4:00 pm -
/// 6:00 pm": los bloques (día + hora de inicio + hora de fin) o el motivo
/// por el que no se pudo leer.
class HorarioInterpretado {
  const HorarioInterpretado._(this.bloques, this.error);

  const HorarioInterpretado.valido(List<BloqueHorario> bloques)
    : this._(bloques, null);

  const HorarioInterpretado.invalido(String error) : this._(const [], error);

  final List<BloqueHorario> bloques;

  /// Mensaje listo para mostrar en el formulario, o `null` si es válido.
  final String? error;

  bool get esValido => error == null;
}

/// "4:00 pm - 6:00 pm", "4–6 pm", "14:00 a 16:00", "9 am hasta 11 am".
final RegExp _rangoDeHoras = RegExp(
  r'(?<![\d:])(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\s*(?:-|–|—|\ba\b|\bal\b|\bhasta\b)\s*(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
);

/// "p.m.", "p. m." y "P.M." pasan a "pm" (igual con "am").
final RegExp _sufijoConPuntos = RegExp(r'\b([ap])\.\s?m\.?');

const String _ejemploHorario = '"Lun y Mié 4:00 pm - 6:00 pm"';

/// Convierte una hora a minutos desde la medianoche. Con [sufijo] (`am`/`pm`)
/// la hora va de 1 a 12; sin sufijo se toma en formato de 24 horas.
int? _aMinutos(int hora, int minuto, String? sufijo) {
  if (minuto > 59) return null;
  if (sufijo == null) {
    if (hora > 24 || (hora == 24 && minuto > 0)) return null;
    return hora * 60 + minuto;
  }
  if (hora < 1 || hora > 12) return null;
  return (hora % 12 + (sufijo == 'pm' ? 12 : 0)) * 60 + minuto;
}

/// Interpreta las horas de un rango. Si solo una de las dos horas trae
/// `am`/`pm`, la otra lo hereda ("4:00–6:00 pm" = 4 a 6 de la tarde), salvo
/// que así el inicio quede después del fin ("11:00–1:00 pm" = 11 am a 1 pm).
(int, int)? _rangoEnMinutos(RegExpMatch rango) {
  final h1 = int.parse(rango.group(1)!);
  final m1 = int.parse(rango.group(2) ?? '0');
  final h2 = int.parse(rango.group(4)!);
  final m2 = int.parse(rango.group(5) ?? '0');
  var s1 = rango.group(3);
  var s2 = rango.group(6);

  if (s1 == null && s2 != null) {
    s1 = s2;
    final inicio = _aMinutos(h1, m1, s1);
    final fin = _aMinutos(h2, m2, s2);
    if (inicio != null && fin != null && inicio >= fin) {
      s1 = s2 == 'pm' ? 'am' : 'pm';
    }
  } else if (s1 != null && s2 == null) {
    s2 = s1;
    final inicio = _aMinutos(h1, m1, s1);
    final fin = _aMinutos(h2, m2, s2);
    if (inicio != null && fin != null && fin <= inicio && s1 == 'am') {
      s2 = 'pm';
    }
  }

  final inicio = _aMinutos(h1, m1, s1);
  var fin = _aMinutos(h2, m2, s2);
  if (inicio == null || fin == null) return null;
  // "11:00 pm - 12:00 am" termina a la medianoche.
  if (fin == 0 && inicio > 0) fin = BloqueHorario.minutosPorDia;
  return (inicio, fin);
}

/// Interpreta una línea de horario escrita por el administrador.
///
/// Acepta los formatos que ya existen en la base de datos:
/// "Lun y Mié 2:00 PM - 4:00 PM", "Lun 4:00–6:00 pm", "Sáb 9:00–11:00 am",
/// "Lun a Vie 14:00 - 16:00" y varios rangos en una línea
/// ("Lun 8-10 am, Mié 2-4 pm"). Cada rango de horas se aplica a los días
/// escritos antes de él (o, si no hay, a los de después).
HorarioInterpretado interpretarHorario(String horario) {
  final texto = _plano(horario)
      .replaceAllMapped(_sufijoConPuntos, (m) => '${m.group(1)}m');
  final rangos = _rangoDeHoras.allMatches(texto).toList();
  if (rangos.isEmpty) {
    return HorarioInterpretado.invalido(
      'Indica la hora de inicio y la hora de fin, por ejemplo $_ejemploHorario.',
    );
  }

  final bloques = <BloqueHorario>{};
  Set<int> diasAnteriores = const {};
  for (var i = 0; i < rangos.length; i++) {
    final desde = i == 0 ? 0 : rangos[i - 1].end;
    var dias = diasDeSemanaDe(texto.substring(desde, rangos[i].start));
    if (dias.isEmpty) dias = diasAnteriores;
    if (dias.isEmpty) {
      final hasta = i + 1 < rangos.length ? rangos[i + 1].start : texto.length;
      dias = diasDeSemanaDe(texto.substring(rangos[i].end, hasta));
    }
    if (dias.isEmpty) {
      return HorarioInterpretado.invalido(
        'Indica el día o los días, por ejemplo $_ejemploHorario.',
      );
    }
    diasAnteriores = dias;

    final minutos = _rangoEnMinutos(rangos[i]);
    if (minutos == null) {
      return HorarioInterpretado.invalido(
        'La hora "${rangos[i].group(0)!.trim()}" no es válida. '
        'Usa el formato de 12 horas con am/pm o el de 24 horas.',
      );
    }
    final (inicio, fin) = minutos;
    if (fin <= inicio) {
      return HorarioInterpretado.invalido(
        'La hora de fin debe ser posterior a la de inicio '
        '("${rangos[i].group(0)!.trim()}").',
      );
    }
    for (final dia in dias) {
      bloques.add(BloqueHorario(dia: dia, inicio: inicio, fin: fin));
    }
  }
  return HorarioInterpretado.valido(bloques.toList()..sort());
}

/// Bloques de todas las líneas de horario. Las líneas que no se pueden
/// interpretar (por ejemplo "Martes 5 pm", sin hora de fin) se ignoran.
List<BloqueHorario> bloquesDeHorarios(Iterable<String> horarios) {
  final bloques = <BloqueHorario>{
    for (final horario in horarios) ...interpretarHorario(horario).bloques,
  };
  return bloques.toList()..sort();
}

/// Pares de bloques de la misma lista que se solapan entre sí.
List<(BloqueHorario, BloqueHorario)> solapamientosEntre(
  List<BloqueHorario> bloques,
) {
  final pares = <(BloqueHorario, BloqueHorario)>[];
  for (var i = 0; i < bloques.length; i++) {
    for (var j = i + 1; j < bloques.length; j++) {
      if (bloques[i].seSolapaCon(bloques[j])) {
        pares.add((bloques[i], bloques[j]));
      }
    }
  }
  return pares;
}

/// Valida las líneas de horario del formulario de una disciplina. Devuelve
/// el primer error o `null` si todas son válidas y no se solapan entre sí.
String? validarHorarios(List<String> horarios) {
  final lineas = [
    for (final horario in horarios)
      if (horario.trim().isNotEmpty) horario.trim(),
  ];
  if (lineas.isEmpty) return 'Agrega al menos un horario.';
  final bloques = <BloqueHorario>[];
  for (final linea in lineas) {
    final resultado = interpretarHorario(linea);
    if (!resultado.esValido) return resultado.error;
    bloques.addAll(resultado.bloques);
  }
  final solapados = solapamientosEntre(bloques);
  if (solapados.isNotEmpty) {
    final (a, b) = solapados.first;
    return 'Los horarios se solapan entre sí: ${a.texto} y ${b.texto}.';
  }
  return null;
}
