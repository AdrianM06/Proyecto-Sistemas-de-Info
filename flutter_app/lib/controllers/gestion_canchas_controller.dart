import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/cancha.dart';
import '../services/canchas_service.dart';

class GestionCanchasController extends ChangeNotifier {
  GestionCanchasController({CanchasDataSource? datos})
      : _datos = datos ?? CanchasService();

  final CanchasDataSource _datos;

  StreamSubscription<List<Cancha>>? _suscripcion;
  List<Cancha>? _canchas;
  String? _error;
  bool _guardando = false;
  bool _liberado = false;

  bool get cargando => _canchas == null && _error == null;
  bool get guardando => _guardando;
  String? get error => _error;
  List<Cancha> get canchas => List.unmodifiable(_canchas ?? const []);

  void iniciar() {
    _suscripcion?.cancel();
    _error = null;
    _canchas = null;
    notifyListeners();
    _suscripcion = _datos.canchas().listen(
      (lista) {
        _canchas = lista;
        notifyListeners();
      },
      onError: (_) {
        _error = 'No se pudieron cargar las canchas.';
        notifyListeners();
      },
    );
  }

  Future<String?> agregarCancha({
    required String nombre,
    String ubicacion = '',
  }) async {
    if (_guardando) return null;
    _guardando = true;
    notifyListeners();
    try {
      await _datos.crearCancha(nombre: nombre, ubicacion: ubicacion);
      return null;
    } on CanchasException catch (e) {
      return e.mensaje;
    } catch (_) {
      return 'No se pudo agregar la cancha.';
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }

  Future<String?> cambiarEstado(Cancha cancha, bool activa) async {
    try {
      await _datos.cambiarEstado(cancha.id, activa);
      return null;
    } on CanchasException catch (e) {
      return e.mensaje;
    }
  }

  Future<String?> eliminarCancha(Cancha cancha) async {
    try {
      await _datos.eliminarCancha(cancha.id);
      return null;
    } on CanchasException catch (e) {
      return e.mensaje;
    }
  }

  @override
  void notifyListeners() {
    if (!_liberado) super.notifyListeners();
  }

  @override
  void dispose() {
    _liberado = true;
    _suscripcion?.cancel();
    super.dispose();
  }
}
