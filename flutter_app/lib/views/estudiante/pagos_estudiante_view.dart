import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/paypal_config.dart';
import '../../controllers/pagos_controller.dart';
import '../../services/pagos_service.dart';
import '../entrenador/widgets/entrenador_widgets.dart';
import '../theme/saman_colors.dart';
import 'estudiante_scaffold.dart';

class PagosEstudianteView extends StatefulWidget {
  const PagosEstudianteView({
    super.key,
    required this.controller,
    this.avatar,
    this.onInicio,
    this.onCatalogo,
    this.onPerfil,
    this.onPaginaPrincipal,
    this.onCerrarSesion,
  });

  factory PagosEstudianteView.conFirestore({
    Key? key,
    String? estudianteId,
    Widget? avatar,
    VoidCallback? onInicio,
    VoidCallback? onCatalogo,
    VoidCallback? onPerfil,
    VoidCallback? onPaginaPrincipal,
    VoidCallback? onCerrarSesion,
  }) {
    final uid = estudianteId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    return PagosEstudianteView(
      key: key,
      controller: PagosController(
        datos: PagosService(),
        estudianteId: uid,
      ),
      avatar: avatar,
      onInicio: onInicio,
      onCatalogo: onCatalogo,
      onPerfil: onPerfil,
      onPaginaPrincipal: onPaginaPrincipal,
      onCerrarSesion: onCerrarSesion,
    );
  }

  final PagosController controller;
  final Widget? avatar;
  final VoidCallback? onInicio;
  final VoidCallback? onCatalogo;
  final VoidCallback? onPerfil;
  final VoidCallback? onPaginaPrincipal;
  final VoidCallback? onCerrarSesion;

  @override
  State<PagosEstudianteView> createState() => _PagosEstudianteViewState();
}

class _PagosEstudianteViewState extends State<PagosEstudianteView> {
  PagosController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.iniciar();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Fecha pendiente';
    final d = fecha.day.toString().padLeft(2, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    final y = fecha.year;
    final h = fecha.hour.toString().padLeft(2, '0');
    final min = fecha.minute.toString().padLeft(2, '0');
    return '$d/$m/$y · $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    return EstudianteScaffold(
      seccion: SeccionEstudiante.pagos,
      avatar: widget.avatar,
      onInicio: widget.onInicio,
      onCatalogo: widget.onCatalogo,
      onPerfil: widget.onPerfil,
      onPaginaPrincipal: widget.onPaginaPrincipal,
      onCerrarSesion: widget.onCerrarSesion,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.cargando && _controller.pagos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.error != null) {
            return MensajeVacio(
              icono: Icons.wifi_off,
              titulo: 'No se pudieron cargar tus pagos',
              detalle: _controller.error,
              accion: FilledButton(
                onPressed: _controller.recargar,
                child: const Text('Reintentar'),
              ),
            );
          }

          final pagos = _controller.pagos;

          return RefreshIndicator(
            onRefresh: _controller.recargar,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _TarjetaResumenPagos(
                  totalPagado: _controller.totalPagado,
                  cantidadComprobantes: _controller.cantidadPagos,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Historial de transacciones',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: SamanColors.azulNoche,
                  ),
                ),
                const SizedBox(height: 10),
                if (pagos.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: MensajeVacio(
                      icono: Icons.receipt_long_outlined,
                      titulo: 'Aún no tienes pagos registrados',
                      detalle:
                          'Cuando te inscribas en una disciplina desde el catálogo, '
                          'tu comprobante de PayPal aparecerá aquí.',
                      accion: widget.onCatalogo == null
                          ? null
                          : FilledButton.icon(
                              onPressed: widget.onCatalogo,
                              icon: const Icon(Icons.sports_soccer_outlined),
                              label: const Text('Ir al catálogo'),
                            ),
                    ),
                  )
                else
                  for (final comprobante in pagos) ...[
                    _TarjetaComprobante(
                      comprobante: comprobante,
                      fechaTexto: _formatearFecha(comprobante.fecha),
                      onTap: () => _mostrarDetalleRecibo(comprobante),
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _mostrarDetalleRecibo(ComprobantePago comprobante) {
    showDialog<void>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('Comprobante de Pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _filaDetalle('Disciplina', comprobante.nombreDeporte),
            if (comprobante.disciplina.isNotEmpty)
              _filaDetalle('Categoría', comprobante.disciplina),
            _filaDetalle(
              'Monto pagado',
              '\$${comprobante.monto.toStringAsFixed(2)} ${PaypalConfig.moneda}',
            ),
            _filaDetalle('Fecha', _formatearFecha(comprobante.fecha)),
            _filaDetalle(
              'Estado de inscripción',
              comprobante.inscripcionActiva ? 'Activa' : 'Retirada',
            ),
            if (comprobante.correoPagador != null)
              _filaDetalle('Cuenta PayPal', comprobante.correoPagador!),
            const Divider(height: 20),
            const Text(
              'ID de Orden PayPal',
              style: TextStyle(fontSize: 12, color: SamanColors.neutro500),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    comprobante.orderId,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copiar ID',
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: comprobante.orderId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ID de orden copiado al portapapeles'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(contextoDialogo).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _filaDetalle(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              '$etiqueta:',
              style: const TextStyle(
                color: SamanColors.neutro500,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaResumenPagos extends StatelessWidget {
  const _TarjetaResumenPagos({
    required this.totalPagado,
    required this.cantidadComprobantes,
  });

  final double totalPagado;
  final int cantidadComprobantes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SamanColors.azul,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total pagado en inscripciones',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${totalPagado.toStringAsFixed(2)} ${PaypalConfig.moneda}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cantidadComprobantes == 1
                      ? '1 comprobante aprobado vía PayPal'
                      : '$cantidadComprobantes comprobantes aprobados vía PayPal',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaComprobante extends StatelessWidget {
  const _TarjetaComprobante({
    required this.comprobante,
    required this.fechaTexto,
    required this.onTap,
  });

  final ComprobantePago comprobante;
  final String fechaTexto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comprobante.nombreDeporte,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: SamanColors.azulNoche,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fechaTexto,
                      style: const TextStyle(
                        fontSize: 12,
                        color: SamanColors.neutro500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Orden: ${comprobante.orderId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: SamanColors.neutro500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${comprobante.monto.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: SamanColors.azulNoche,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: comprobante.inscripcionActiva
                          ? Colors.green.shade50
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      comprobante.inscripcionActiva ? 'Pagado' : 'Retirada',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: comprobante.inscripcionActiva
                            ? Colors.green[800]
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
