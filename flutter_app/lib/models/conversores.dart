import 'package:cloud_firestore/cloud_firestore.dart';

/// Funciones de apoyo para leer los datos que llegan de Cloud Firestore.
///
/// Los documentos de Firestore son mapas sin tipos fijos: un campo puede
/// faltar, venir nulo o con un tipo distinto al esperado. Estas funciones
/// convierten cada valor de forma segura y las usan los constructores
/// `fromJson` (patrón Factory Method) de todos los modelos.

/// Devuelve el valor como texto, o [porDefecto] si es nulo.
String textoDe(dynamic valor, {String porDefecto = ''}) {
  if (valor == null) return porDefecto;
  return valor.toString();
}

/// Devuelve el valor como texto, o `null` si está vacío o no existe.
String? textoOpcionalDe(dynamic valor) {
  if (valor == null) return null;
  final texto = valor.toString().trim();
  return texto.isEmpty ? null : texto;
}

/// Devuelve el valor como entero, aceptando números y textos numéricos.
int enteroDe(dynamic valor, {int porDefecto = 0}) {
  if (valor is int) return valor;
  if (valor is num) return valor.toInt();
  if (valor is String) return int.tryParse(valor.trim()) ?? porDefecto;
  return porDefecto;
}

/// Devuelve el valor como booleano, aceptando `true/false`, `"true"` y `1/0`.
bool booleanoDe(dynamic valor, {bool porDefecto = false}) {
  if (valor is bool) return valor;
  if (valor is num) return valor != 0;
  if (valor is String) {
    final texto = valor.trim().toLowerCase();
    if (texto == 'true' || texto == 'si' || texto == 'sí') return true;
    if (texto == 'false' || texto == 'no') return false;
  }
  return porDefecto;
}

/// Convierte un `Timestamp` de Firestore, un `DateTime`, un texto ISO 8601
/// o milisegundos en un `DateTime`. Devuelve `null` si no se puede.
DateTime? fechaDe(dynamic valor) {
  if (valor == null) return null;
  if (valor is Timestamp) return valor.toDate();
  if (valor is DateTime) return valor;
  if (valor is int) return DateTime.fromMillisecondsSinceEpoch(valor);
  if (valor is String) return DateTime.tryParse(valor);
  return null;
}

/// Devuelve una lista de textos a partir de una lista de Firestore.
List<String> listaDeTextosDe(dynamic valor) {
  if (valor is Iterable) {
    return valor
        .where((elemento) => elemento != null)
        .map((elemento) => elemento.toString())
        .toList();
  }
  return const [];
}

/// Quita la hora de una fecha (deja solo año, mes y día).
DateTime soloFecha(DateTime fecha) => DateTime(fecha.year, fecha.month, fecha.day);

/// Formatea una fecha como `aaaa-mm-dd` (por ejemplo, `2026-10-21`).
String claveDeFecha(DateTime fecha) {
  final mes = fecha.month.toString().padLeft(2, '0');
  final dia = fecha.day.toString().padLeft(2, '0');
  return '${fecha.year}-$mes-$dia';
}
