import 'conversores.dart';

/// Un bloque de entrenamiento: un día de la semana con su hora de inicio y
/// de fin.
///
/// Las horas se guardan como **minutos desde la medianoche** (0 a 1440). Así
/// se pueden comparar y ordenar como números, en la app y en Firestore:
/// 4:00 pm = 16 × 60 = 960. En Firestore cada bloque es un mapa
/// `{dia: 1, inicio: 960, fin: 1080}` dentro de la lista `bloquesHorario`.
class BloqueHorario implements Comparable<BloqueHorario> {
  const BloqueHorario({
    required this.dia,
    required this.inicio,
    required this.fin,
  });

  /// Crea el bloque a partir de horas y minutos en formato de 24 horas.
  factory BloqueHorario.desdeHoras({
    required int dia,
    required int horaInicio,
    int minutoInicio = 0,
    required int horaFin,
    int minutoFin = 0,
  }) {
    return BloqueHorario(
      dia: dia,
      inicio: horaInicio * 60 + minutoInicio,
      fin: horaFin * 60 + minutoFin,
    );
  }

  /// Día de la semana, igual que `DateTime.weekday`: 1 = lunes ... 7 = domingo.
  final int dia;

  /// Hora de inicio en minutos desde la medianoche.
  final int inicio;

  /// Hora de fin en minutos desde la medianoche. Siempre mayor que [inicio].
  final int fin;

  static const int minutosPorDia = 24 * 60;

  static const List<String> _dias = [
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
    'Dom',
  ];

  /// Duración del entrenamiento.
  Duration get duracion => Duration(minutes: fin - inicio);

  /// `true` si el día está entre 1 y 7 y el fin es posterior al inicio,
  /// dentro del mismo día.
  bool get esValido =>
      dia >= 1 &&
      dia <= 7 &&
      inicio >= 0 &&
      fin <= minutosPorDia &&
      fin > inicio;

  /// `true` si los dos bloques caen el mismo día y sus horas se cruzan.
  ///
  /// Un bloque que termina justo cuando empieza el otro (4:00–6:00 pm y
  /// 6:00–8:00 pm) **no** choca.
  bool seSolapaCon(BloqueHorario otro) =>
      dia == otro.dia && inicio < otro.fin && otro.inicio < fin;

  /// `true` si el bloque empieza y termina dentro de la franja
  /// [desde]–[hasta] (en minutos desde la medianoche).
  bool estaDentroDe(int desde, int hasta) => inicio >= desde && fin <= hasta;

  /// Abreviatura del día, por ejemplo "Mié".
  String get nombreDia => (dia >= 1 && dia <= 7) ? _dias[dia - 1] : '?';

  /// Texto para la interfaz, por ejemplo "Lun 4:00 pm – 6:00 pm".
  String get texto => '$nombreDia ${horaTexto(inicio)} – ${horaTexto(fin)}';

  /// Convierte minutos desde la medianoche a "4:00 pm".
  static String horaTexto(int minutos) {
    final hora24 = (minutos ~/ 60) % 24;
    final minuto = minutos % 60;
    final sufijo = hora24 < 12 ? 'am' : 'pm';
    final hora12 = hora24 % 12 == 0 ? 12 : hora24 % 12;
    return '$hora12:${minuto.toString().padLeft(2, '0')} $sufijo';
  }

  Map<String, dynamic> toJson() => {'dia': dia, 'inicio': inicio, 'fin': fin};

  /// Patrón Factory Method: lee un mapa `{dia, inicio, fin}` de Firestore.
  /// Devuelve `null` si el mapa no describe un bloque válido.
  static BloqueHorario? fromJson(dynamic json) {
    if (json is! Map) return null;
    final bloque = BloqueHorario(
      dia: enteroDe(json['dia']),
      inicio: enteroDe(json['inicio'], porDefecto: -1),
      fin: enteroDe(json['fin'], porDefecto: -1),
    );
    return bloque.esValido ? bloque : null;
  }

  @override
  int compareTo(BloqueHorario otro) {
    if (dia != otro.dia) return dia.compareTo(otro.dia);
    if (inicio != otro.inicio) return inicio.compareTo(otro.inicio);
    return fin.compareTo(otro.fin);
  }

  @override
  bool operator ==(Object other) =>
      other is BloqueHorario &&
      other.dia == dia &&
      other.inicio == inicio &&
      other.fin == fin;

  @override
  int get hashCode => Object.hash(dia, inicio, fin);

  @override
  String toString() => texto;
}
