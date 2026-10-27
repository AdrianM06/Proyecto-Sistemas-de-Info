/// Textos de fechas y porcentajes en español para la vista del entrenador.
library;

const _dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
const _diasLargos = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];
const _meses = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// Ejemplo: "Mié 21 oct".
String fechaCorta(DateTime fecha) =>
    '${_dias[fecha.weekday - 1]} ${fecha.day} ${_meses[fecha.month - 1]}';

/// Ejemplo: "miércoles 21 de oct. de 2026".
String fechaLarga(DateTime fecha) =>
    '${_diasLargos[fecha.weekday - 1]} ${fecha.day} de '
    '${_meses[fecha.month - 1]}. de ${fecha.year}';

/// Ejemplo: 0.875 → "88 %". Devuelve "—" si no hay dato.
String porcentaje(double? valor) =>
    valor == null ? '—' : '${(valor * 100).round()} %';
