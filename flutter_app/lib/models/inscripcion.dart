class Inscripcion {
  const Inscripcion({
    required this.id,
    required this.estudianteId,
    required this.deporteId,
    required this.estado,
    this.fechaInscripcion,
    this.paypalOrderId,
    this.montoPagado,
    this.paypalPayerEmail,
  });

  final String id;
  final String estudianteId;
  final String deporteId;
  final EstadoInscripcion estado;
  final DateTime? fechaInscripcion;
  final String? paypalOrderId;
  final double? montoPagado;
  final String? paypalPayerEmail;

  bool get estaActiva => estado == EstadoInscripcion.activa;

  factory Inscripcion.fromJson(Map<String, dynamic> json, {required String id}) {
    final estado = textoDe(json['estado']).trim().toLowerCase();
    final rawMonto = json['montoPagado'];
    final monto = rawMonto is num
        ? rawMonto.toDouble()
        : double.tryParse(textoDe(rawMonto).trim());
    final orderId = textoDe(json['paypalOrderId']).trim();
    final payerEmail = textoDe(json['paypalPayerEmail']).trim();

    return Inscripcion(
      id: id,
      estudianteId: textoDe(json['estudianteId']),
      deporteId: textoDe(json['deporteId']),
      estado: estado == 'retirada'
          ? EstadoInscripcion.retirada
          : EstadoInscripcion.activa,
      fechaInscripcion: fechaDe(json['fechaInscripcion']),
      paypalOrderId: orderId.isEmpty ? null : orderId,
      montoPagado: monto,
      paypalPayerEmail: payerEmail.isEmpty ? null : payerEmail,
    );
  }

  factory Inscripcion.fromFirestore(DocumentSnapshot> doc) {
    return Inscripcion.fromJson(doc.data() ?? const {}, id: doc.id);
  }

  Map<String, dynamic> toJson() => {
        'estudianteId': estudianteId,
        'deporteId': deporteId,
        'estado': estado.name,
        'fechaInscripcion': fechaInscripcion == null
            ? null
            : Timestamp.fromDate(fechaInscripcion!),
        if (paypalOrderId != null) 'paypalOrderId': paypalOrderId,
        if (montoPagado != null) 'montoPagado': montoPagado,
        if (paypalPayerEmail != null) 'paypalPayerEmail': paypalPayerEmail,
      };
}
