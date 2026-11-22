import 'package:flutter/foundation.dart';

import '../services/pagos_service.dart';

class PagosController extends ChangeNotifier {
  PagosController({
    required PagosDataSource datos,
    required this.estudianteId,
  }) : _datos = datos;

  final PagosDataSource _datos;
  final String estudianteId;

  bool _cargando = false;
  String? _error;
  List<ComprobantePago> _pagos = const [];
  bool _liberado = false;

  bool get cargando => _cargando;
  String? get error => _error;
  List<ComprobantePago> get pagos => List.unmodifiable(_pagos);
  int get cantidadPagos => _pagos.length;

  double get totalPagado =>
      _pagos.fold<double>(0.0, (suma, item) => suma + item.monto);

  Future<void> iniciar() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _pagos = await _datos.pagosDeEstudiante(estudianteId);
    } catch (_) {
      _pagos = const [];
      _error = 'No se pudo cargar tu historial de pagos.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> recargar() => iniciar();

  @override
  void notifyListeners() {
    if (!_liberado) super.notifyListeners();
  }

  @override
  void dispose() {
    _liberado = true;
    super.dispose();
  }
}
