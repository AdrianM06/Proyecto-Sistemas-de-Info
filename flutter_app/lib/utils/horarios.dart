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
