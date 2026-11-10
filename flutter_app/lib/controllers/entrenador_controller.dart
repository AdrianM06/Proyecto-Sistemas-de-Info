import 'package:flutter/foundation.dart';

import '../models/asistencia.dart';
import '../models/conversores.dart';
import '../models/deporte.dart';
import '../models/usuario.dart';
import '../services/entrenador_service.dart';

/// Una sesión de entrenamiento vista desde un estudiante: si asistió y la
/// fecha y hora exactas del registro (`null` en registros viejos).
class RegistroDeAsistencia {
  const RegistroDeAsistencia({
    required this.fecha,
    required this.presente,
    this.hora,
  });

  /// Día de la sesión.
  final DateTime fecha;
  final bool presente;

  /// Fecha y hora en que se marcó presente; `null` si faltó o si el
  /// registro es anterior a que se guardara la hora.
  final DateTime? hora;
}

/// Asistencia de un estudiante en un mes.
class AsistenciaMensual {
  const AsistenciaMensual({required this.mes, required this.registros});

  /// Día 1 del mes.
  final DateTime mes;

  /// Sesiones del mes, de la más antigua a la más reciente.
  final List<RegistroDeAsistencia> registros;

  int get sesiones => registros.length;
  int get asistencias => registros.where((r) => r.presente).length;
  int get faltas => sesiones - asistencias;

  /// Porcentaje (0 a 1) del mes, o `null` si no hubo sesiones.
  double? get porcentaje => sesiones == 0 ? null : asistencias / sesiones;
}

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

  /// Momento exacto en que se marcó presente a cada estudiante en la sesión
  /// abierta. Se guarda en `horasPresentes` al guardar la asistencia.
  final Map<String, DateTime> _horasMarcadas = {};

  /// Estudiantes presentes en un registro viejo que no guardó la hora. Si el
  /// entrenador vuelve a guardar esa sesión sin tocarlos, siguen sin hora
  /// (no se inventa una).
  final Set<String> _presentesSinHora = {};
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

  /// `true` si la disciplina actual entrena el día de la fecha elegida. Solo
  /// en esos días se puede tomar asistencia.
  bool get hayEntrenamientoEnFecha => _deporteActual?.entrenaEl(_fecha) ?? false;

  /// `true` si el horario de la disciplina no nombra ningún día.
  bool get horarioSinDias => (_deporteActual?.diasDeEntrenamiento ?? {}).isEmpty;

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

  /// Meses (día 1 de cada mes) con sesiones guardadas, del más reciente al
  /// más antiguo. Incluye siempre el mes actual.
  List<DateTime> get mesesConSesiones {
    final hoy = _reloj();
    final meses = <DateTime>{
      DateTime(hoy.year, hoy.month),
      for (final sesion in _historial)
        DateTime(sesion.fecha.year, sesion.fecha.month),
    }.toList()..sort((a, b) => b.compareTo(a));
    return meses;
  }

  /// Detalle de la asistencia de un estudiante en el mes de [mes]: cada
  /// sesión guardada de ese mes, si asistió y a qué hora se registró.
  AsistenciaMensual asistenciaMensualDe(String estudianteId, DateTime mes) {
    final registros = [
      for (final sesion in _historial)
        if (sesion.fecha.year == mes.year && sesion.fecha.month == mes.month)
          RegistroDeAsistencia(
            fecha: sesion.fecha,
            presente: sesion.estaPresente(estudianteId),
            hora: sesion.horaDe(estudianteId),
          ),
    ]..sort((a, b) => a.fecha.compareTo(b.fecha));
    return AsistenciaMensual(
      mes: DateTime(mes.year, mes.month),
      registros: registros,
    );
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
    _anotarHora(estudianteId, presente: presente);
    _marcas[estudianteId] = presente;
    notifyListeners();
  }

  void marcarTodos({required bool presentes}) {
    for (final estudiante in _nomina) {
      _anotarHora(estudiante.uid, presente: presentes);
      _marcas[estudiante.uid] = presentes;
    }
    notifyListeners();
  }

  /// Anota la fecha y hora en que el estudiante pasa a "presente". Si ya
  /// estaba presente, conserva la hora original.
  void _anotarHora(String estudianteId, {required bool presente}) {
    if (!presente) {
      _horasMarcadas.remove(estudianteId);
      _presentesSinHora.remove(estudianteId);
    } else if (_marcas[estudianteId] != true) {
      _horasMarcadas[estudianteId] = _reloj();
      _presentesSinHora.remove(estudianteId);
    }
  }

  /// Fecha y hora en que se marcó presente al estudiante en la sesión
  /// abierta, o `null`.
  DateTime? horaMarcadaDe(String estudianteId) => _horasMarcadas[estudianteId];

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
    if (!hayEntrenamientoEnFecha) {
      _error = 'No hay entrenamiento pautado para este día.';
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

    final ahora = _reloj();
    final presentesIds = _nomina
        .where((estudiante) => _marcas[estudiante.uid] == true)
        .map((estudiante) => estudiante.uid)
        .toList();
    final asistencia = Asistencia(
      deporteId: deporte.id,
      fecha: _fecha,
      entrenadorId: entrenadorId,
      presentes: presentesIds,
      registradaEn: ahora,
      horasPresentes: {
        for (final uid in presentesIds)
          if (!_presentesSinHora.contains(uid))
            uid: _horasMarcadas[uid] ?? ahora,
      },
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
    // Las tres consultas son independientes: se piden a la vez para no
    // esperar una ronda de red por cada una.
    final resultados = await Future.wait([
      _datos.nominaDelDeporte(deporte.id),
      _datos.historialDeAsistencia(deporte.id),
      _datos.asistenciaDelDia(deporte.id, _fecha),
    ]);
    _nomina = resultados[0] as List<Usuario>;
    _historial = resultados[1] as List<Asistencia>;
    _aplicarAsistencia(resultados[2] as Asistencia?);
  }

  Future<void> _cargarAsistenciaDelDia() async {
    final deporte = _deporteActual;
    if (deporte == null) {
      _marcas.clear();
      return;
    }
    _aplicarAsistencia(await _datos.asistenciaDelDia(deporte.id, _fecha));
  }

  void _aplicarAsistencia(Asistencia? guardada) {
    _marcas.clear();
    _horasMarcadas.clear();
    _presentesSinHora.clear();
    if (guardada == null) return;
    for (final estudiante in _nomina) {
      final uid = estudiante.uid;
      _marcas[uid] = guardada.estaPresente(uid);
      if (!guardada.estaPresente(uid)) continue;
      // Al editar una sesión ya guardada se conservan las horas originales.
      final hora = guardada.horaDe(uid);
      if (hora != null) {
        _horasMarcadas[uid] = hora;
      } else {
        _presentesSinHora.add(uid);
      }
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
