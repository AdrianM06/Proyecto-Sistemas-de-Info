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

const _mesesLargos = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// Ejemplo: "noviembre 2026".
String mesYAnio(DateTime fecha) =>
    '${_mesesLargos[fecha.month - 1]} ${fecha.year}';

/// Ejemplo: 16:05 → "4:05 pm".
String hora(DateTime fecha) {
  final sufijo = fecha.hour < 12 ? 'am' : 'pm';
  final hora12 = fecha.hour % 12 == 0 ? 12 : fecha.hour % 12;
  return '$hora12:${fecha.minute.toString().padLeft(2, '0')} $sufijo';
}

/// Ejemplo: "Mié 21 oct, 4:05 pm".
String fechaYHora(DateTime fecha) => '${fechaCorta(fecha)}, ${hora(fecha)}';
