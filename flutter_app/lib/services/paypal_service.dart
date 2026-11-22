import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/paypal_config.dart';

class PaypalException implements Exception {
  const PaypalException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

class PaypalOrdenCreada {
  const PaypalOrdenCreada({
    required this.orderId,
    required this.approveUrl,
  });

  final String orderId;
  final String approveUrl;
}

class PaypalResultadoPago {
  const PaypalResultadoPago({
    required this.completado,
    required this.orderId,
    this.payerEmail,
  });

  final bool completado;
  final String orderId;
  final String? payerEmail;
}

class PaypalService {
  PaypalService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get _baseUrl => PaypalConfig.sandboxMode
      ? 'https://api-m.sandbox.paypal.com'
      : 'https://api-m.paypal.com';

  Future<String> _obtenerAccessToken() async {
    final credenciales = base64Encode(
      utf8.encode('${PaypalConfig.clientId}:${PaypalConfig.secretKey}'),
    );

    final respuesta = await _client.post(
      Uri.parse('$_baseUrl/v1/oauth2/token'),
      headers: {
        'Authorization': 'Basic $credenciales',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'grant_type=client_credentials',
    );

    if (respuesta.statusCode != 200) {
      throw const PaypalException(
        'No se pudo autenticar con PayPal. Verifica tu Client ID y Secret Key.',
      );
    }

    final data = jsonDecode(respuesta.body) as Map<String, dynamic>;
    final token = data['access_token']?.toString();
    if (token == null || token.isEmpty) {
      throw const PaypalException('PayPal no devolvió un token de acceso válido.');
    }
    return token;
  }

  /// Crea una orden de pago en PayPal y devuelve su ID y enlace de aprobación.
  Future<PaypalOrdenCreada> crearOrden({
    required double monto,
    required String descripcion,
  }) async {
    final token = await _obtenerAccessToken();
    final montoTexto = monto.toStringAsFixed(2);

    final respuesta = await _client.post(
      Uri.parse('$_baseUrl/v2/checkout/orders'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'intent': 'CAPTURE',
        'purchase_units': [
          {
            'description': descripcion,
            'amount': {
              'currency_code': PaypalConfig.moneda,
              'value': montoTexto,
            },
          },
        ],
        'application_context': {
          'brand_name': 'UNIMET Sports',
          'user_action': 'PAY_NOW',
          'return_url': 'https://developer.paypal.com',
          'cancel_url': 'https://developer.paypal.com',
        },
      }),
    );

    if (respuesta.statusCode != 201 && respuesta.statusCode != 200) {
      throw const PaypalException('No se pudo generar la orden de pago en PayPal.');
    }

    final data = jsonDecode(respuesta.body) as Map<String, dynamic>;
    final orderId = data['id']?.toString() ?? '';
    final links = (data['links'] as List<dynamic>?) ?? const [];

    String approveUrl = '';
    for (final link in links) {
      if (link is Map && link['rel'] == 'approve') {
        approveUrl = link['href']?.toString() ?? '';
        break;
      }
    }

    if (orderId.isEmpty || approveUrl.isEmpty) {
      throw const PaypalException('PayPal no devolvió el enlace de pago.');
    }

    return PaypalOrdenCreada(orderId: orderId, approveUrl: approveUrl);
  }

  /// Consulta la orden; si el estudiante ya la aprobó en el navegador, captura el pago.
  Future<PaypalResultadoPago> capturarSiAprobada(String orderId) async {
    final token = await _obtenerAccessToken();

    final consulta = await _client.get(
      Uri.parse('$_baseUrl/v2/checkout/orders/$orderId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (consulta.statusCode != 200) {
      return PaypalResultadoPago(completado: false, orderId: orderId);
    }

    final ordenData = jsonDecode(consulta.body) as Map<String, dynamic>;
    final estado = ordenData['status']?.toString() ?? '';

    if (estado == 'COMPLETED') {
      final payer = ordenData['payer'] as Map<String, dynamic>?;
      return PaypalResultadoPago(
        completado: true,
        orderId: orderId,
        payerEmail: payer?['email_address']?.toString(),
      );
    }

    if (estado == 'VOIDED') {
      throw const PaypalException('La orden de pago fue cancelada en PayPal.');
    }

    if (estado != 'APPROVED') {
      return PaypalResultadoPago(completado: false, orderId: orderId);
    }

    // El estudiante aprobó en PayPal: capturamos el cobro.
    final captura = await _client.post(
      Uri.parse('$_baseUrl/v2/checkout/orders/$orderId/capture'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (captura.statusCode != 201 && captura.statusCode != 200) {
      throw const PaypalException('El pago fue aprobado pero falló su captura.');
    }

    final capturaData = jsonDecode(captura.body) as Map<String, dynamic>;
    final estadoCaptura = capturaData['status']?.toString() ?? '';
    final payer = capturaData['payer'] as Map<String, dynamic>?;

    return PaypalResultadoPago(
      completado: estadoCaptura == 'COMPLETED',
      orderId: orderId,
      payerEmail: payer?['email_address']?.toString(),
    );
  }
}
