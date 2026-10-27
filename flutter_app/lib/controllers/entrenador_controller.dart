import 'package:flutter/foundation.dart';

import '../models/asistencia.dart';
import '../models/conversores.dart';
import '../models/deporte.dart';
import '../models/usuario.dart';
import '../services/entrenador_service.dart';

/// Controlador (la "C" de MVC) de la vista del entrenador.
///
/// Recibe las acciones de las pantallas (elegir disciplina, buscar en la
/// nómina, marcar asistencia, guardar) y pide los datos a un
/// [EntrenadorDataSource]. Las pantallas solo leen su estado y se redibujan
/// cuando el controlador llama a `notifyListeners()`.
class EntrenadorController extends ChangeNotifier {
  EntrenadorController({
    required EntrenadorDataSource datos,
    required this.entrenadorId,
    DateTime Function()? reloj,
  })  : _datos = datos,
        _reloj = reloj ?? DateTime.now,
        _fecha = soloFecha((reloj ?? DateTime.now)());

  final EntrenadorDataSource _datos;
  final DateTime Function() _reloj;

  /// Id (uid) del entrenador que inició sesión.
  final String entrenadorId;

  // ---------------------------------------------------------------- estado

  bool _cargando = false;
  bool _guardando = false;
  String? _error;
  List<Deporte> _deportes = const [];
  Deporte? _deporteActual;
  List<Usuario> _nomina = const [];
  List<Asistencia> _historial = const [];
  DateTime _fecha;
  final Map<String, bool> _marcas = {};
  String _busqueda = '';

  bool get cargando => _cargando;
  bool get guardando => _guardando;
  String? get error => _error;
  List<Deporte> get deportes => List.unmodifiable(_deportes);
  Deporte? get deporteActual => _deporteActual;
  List<Usuario> get nomina => List.unmodifiable(_nomina);
  List<Asistencia> get historial => List.unmodifiable(_historial);
  DateTime get fechaAsistencia => _fecha;
  String get busqueda => _busqueda;

  /// Nómina filtrada por nombre, apellido o carnet según la búsqueda.
  List<Usuario> get nominaFiltrada {
    final texto = _busqueda.trim().toLowerCase();
    if (texto.isEmpty) return nomina;
    return _nomina.where((estudiante) {
      return estudiante.nombreCompleto.toLowerCase().contains(texto) ||
          (estudiante.carnet ?? '').contains(texto);
    }).toList();
  }

  int get inscritos => _nomina.length;

  /// Cupos libres del deporte actual (nunca negativo).
  int get cuposDisponibles {
    final cupos = _deporteActual?.cupos ?? 0;
    return cupos > inscritos ? cupos - inscritos : 0;
  }

  /// Marca actual de un estudiante: `true` presente, `false` ausente,
  /// `null` sin marcar.
  bool? marcaDe(String estudianteId) => _marcas[estudianteId];

  int get presentes => _marcas.values.where((presente) => presente).length;
  int get ausentes => _marcas.values.where((presente) => !presente).length;
  int get sinMarcar =>
      _nomina.where((estudiante) => !_marcas.containsKey(estudiante.uid)).length;

  /// Porcentaje de asistencia (0 a 1) de un estudiante en las sesiones
  /// guardadas, o `null` si todavía no hay sesiones.
  double? porcentajeDe(String estudianteId) {
    if (_historial.isEmpty) return null;
    final asistio =
        _historial.where((sesion) => sesion.estaPresente(estudianteId)).length;
    return asistio / _historial.length;
  }

  /// Promedio de asistencia (0 a 1) de todas las sesiones guardadas, o
  /// `null` si no hay sesiones o no hay inscritos.
  double? get promedioAsistencia {
    if (_historial.isEmpty || _nomina.isEmpty) return null;
    final suma = _historial.fold<double>(
      0,
      (total, sesion) => total + porcentajeDeSesion(sesion),
    );
    return suma / _historial.length;
  }

  /// Porcentaje de presentes (0 a 1) de una sesión respecto a la nómina.
  double porcentajeDeSesion(Asistencia sesion) {
    if (_nomina.isEmpty) return 0;
    final presentesEnNomina = _nomina
        .where((estudiante) => sesion.estaPresente(estudiante.uid))
        .length;
    return presentesEnNomina / _nomina.length;
  }

  /// Estudiantes con asistencia menor a [limite] (por defecto 75 %).
  List<Usuario> estudiantesEnRiesgo({double limite = 0.75}) {
    return _nomina.where((estudiante) {
      final porcentaje = porcentajeDe(estudiante.uid);
      return porcentaje != null && porcentaje < limite;
    }).toList();
  }

  // --------------------------------------------------------------- acciones

  /// Carga las disciplinas del entrenador y selecciona la primera.
  Future<void> iniciar() async {
    await _ejecutar(() async {
      _deportes = await _datos.deportesDelEntrenador(entrenadorId);
      _deporteActual = _deportes.isEmpty ? null : _deportes.first;
      await _cargarDatosDelDeporte();
    });
  }

  /// Cambia la disciplina seleccionada y carga su nómina e historial.
  Future<void> seleccionarDeporte(Deporte deporte) async {
    if (deporte.id == _deporteActual?.id) return;
    _deporteActual = deporte;
    _busqueda = '';
    await _ejecutar(_cargarDatosDelDeporte);
  }

  /// Vuelve a pedir los datos del deporte actual.
  Future<void> recargar() => _ejecutar(_cargarDatosDelDeporte);

  void buscarEnNomina(String texto) {
    _busqueda = texto;
    notifyListeners();
  }

  /// Cambia la fecha de la sesión y carga la asistencia guardada de ese día.
  Future<void> cambiarFecha(DateTime fecha) async {
    _fecha = soloFecha(fecha);
    await _ejecutar(_cargarAsistenciaDelDia);
  }

  /// Vuelve a la fecha de hoy.
  Future<void> irAHoy() => cambiarFecha(_reloj());

  void marcar(String estudianteId, {required bool presente}) {
    _marcas[estudianteId] = presente;
    notifyListeners();
  }

  void marcarTodos({required bool presentes}) {
    for (final estudiante in _nomina) {
      _marcas[estudiante.uid] = presentes;
    }
    notifyListeners();
  }

  /// Guarda la asistencia de la fecha seleccionada.
  ///
  /// Devuelve `false` (y deja un mensaje en [error]) si hay estudiantes sin
  /// marcar, si no hay disciplina seleccionada o si falla el guardado.
  Future<bool> guardarAsistencia() async {
    final deporte = _deporteActual;
    if (deporte == null) {
      _error = 'Selecciona una disciplina antes de tomar asistencia.';
      notifyListeners();
      return false;
    }
    if (_nomina.isEmpty) {
      _error = 'La disciplina no tiene estudiantes inscritos.';
      notifyListeners();
      return false;
    }
    if (sinMarcar > 0) {
      final faltan = sinMarcar;
      _error = faltan == 1
          ? 'Falta 1 estudiante por marcar.'
          : 'Faltan $faltan estudiantes por marcar.';
      notifyListeners();
      return false;
    }

    final asistencia = Asistencia(
      deporteId: deporte.id,
      fecha: _fecha,
      entrenadorId: entrenadorId,
      presentes: _nomina
          .where((estudiante) => _marcas[estudiante.uid] == true)
          .map((estudiante) => estudiante.uid)
          .toList(),
    );

    _guardando = true;
    _error = null;
    notifyListeners();
    try {
      await _datos.guardarAsistencia(asistencia);
      _historial = [
        asistencia,
        ..._historial.where((sesion) => sesion.id != asistencia.id),
      ]..sort((a, b) => b.fecha.compareTo(a.fecha));
      return true;
    } catch (e) {
      _error = 'No se pudo guardar la asistencia. Intenta de nuevo.';
      return false;
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }

  void limpiarError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------- internos

  Future<void> _cargarDatosDelDeporte() async {
    final deporte = _deporteActual;
    if (deporte == null) {
      _nomina = const [];
      _historial = const [];
      _marcas.clear();
      return;
    }
    final resultados = await Future.wait([
      _datos.nominaDelDeporte(deporte.id),
      _datos.historialDeAsistencia(deporte.id),
    ]);
    _nomina = resultados[0] as List<Usuario>;
    _historial = resultados[1] as List<Asistencia>;
    await _cargarAsistenciaDelDia();
  }

  Future<void> _cargarAsistenciaDelDia() async {
    _marcas.clear();
    final deporte = _deporteActual;
    if (deporte == null) return;
    final guardada = await _datos.asistenciaDelDia(deporte.id, _fecha);
    if (guardada == null) return;
    for (final estudiante in _nomina) {
      _marcas[estudiante.uid] = guardada.estaPresente(estudiante.uid);
    }
  }

  Future<void> _ejecutar(Future<void> Function() accion) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      await accion();
    } catch (e) {
      _error = 'No se pudieron cargar los datos. Revisa tu conexión.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}
