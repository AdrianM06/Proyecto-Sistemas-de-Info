import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/conversores.dart';
import '../models/deporte.dart';
import '../services/inicio_estudiante_service.dart';
import '../models/evento.dart';
import '../services/eventos_service.dart';

/// Controlador (la "C" de MVC) del inicio del estudiante.
///
/// Escucha en tiempo real las inscripciones del estudiante y los deportes.
/// Cuando el estudiante se inscribe o se retira, o el administrador cambia un
/// horario, el calendario y la lista de disciplinas se actualizan solos, sin
/// recargar la página.
class InicioEstudianteController extends ChangeNotifier {
  InicioEstudianteController({
    required InicioEstudianteDataSource datos,
    EventosDataSource? eventosDatos,
    required this.estudianteId,
    DateTime Function()? reloj,
  }) : _datos = datos,
       _eventosDatos = eventosDatos ?? EventosService(),
       _reloj = reloj ?? DateTime.now;

  final InicioEstudianteDataSource _datos;
  final EventosDataSource _eventosDatos;
  final DateTime Function() _reloj;

  /// Id (uid) del estudiante que inició sesión.
  final String estudianteId;

  StreamSubscription<Set<String>>? _suscripcionInscritos;
  StreamSubscription<List<Deporte>>? _suscripcionDeportes;
  Set<String>? _inscritos;
  List<Deporte>? _deportes;
  String? _error;
  bool _liberado = false;

  /// `true` hasta que llegan las inscripciones y los deportes.
  bool get cargando =>
      _error == null && (_inscritos == null || _deportes == null);
  String? get error => _error;

  /// Hoy, sin la hora.
  DateTime get hoy => soloFecha(_reloj());

  /// Disciplinas donde el estudiante está inscrito, ordenadas por nombre.
  List<Deporte> get disciplinas {
    final inscritos = _inscritos ?? const <String>{};
    return [
      for (final deporte in _deportes ?? const <Deporte>[])
        if (inscritos.contains(deporte.id)) deporte,
    ]..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
  }

  /// Disciplinas del estudiante que entrenan el día de [fecha].
  List<Deporte> entrenamientosDe(DateTime fecha) {
    return [
      for (final deporte in disciplinas)
        if (deporte.entrenaEl(fecha)) deporte,
    ];
  }

  /// Primer día, desde hoy y dentro de los próximos 7, con entrenamiento.
  DateTime? get proximoEntrenamiento {
    final inicio = hoy;
    for (var i = 0; i < 7; i++) {
      final dia = DateTime(inicio.year, inicio.month, inicio.day + i);
      if (entrenamientosDe(dia).isNotEmpty) return dia;
    }
    return null;
  }

/// Eventos de las disciplinas donde el estudiante está inscrito.
  List<EventoDeportivo> get eventosInscritos {
    final inscritos = _inscritos ?? const <String>{};
    return [
      for (final evento in _eventos)
        if (inscritos.contains(evento.deporteId)) evento,
    ];
  }

/// Eventos del estudiante que ocurren el día de [fecha].
  List<EventoDeportivo> eventosDe(DateTime fecha) {
    return [
      for (final evento in eventosInscritos)
        if (evento.ocurreEl(fecha)) evento,
    ];
  }

  /// `true` si el estudiante tiene entrenamiento o evento ese día.
  bool tieneActividadEl(DateTime fecha) =>
      entrenamientosDe(fecha).isNotEmpty || eventosDe(fecha).isNotEmpty;
  
  /// Empieza a escuchar. Se puede llamar de nuevo para reintentar.
  void iniciar() {
    _suscripcionInscritos?.cancel();
    _suscripcionDeportes?.cancel();
    _error = null;
    _inscritos = null;
    _deportes = null;
    notifyListeners();

    _suscripcionInscritos = _datos.deportesInscritos(estudianteId).listen((
      ids,
    ) {
      _inscritos = ids;
      notifyListeners();
    }, onError: _alFallar);
    _suscripcionDeportes = _datos.deportes().listen((lista) {
      _deportes = lista;
      notifyListeners();
    }, onError: _alFallar);
    _suscripcionEventos?.cancel();
    _suscripcionEventos = _eventosDatos.eventos().listen((lista) {
      _eventos = lista;
      notifyListeners();
    }, onError: (_) {});
  }

  void _alFallar(Object error) {
    _error =
        'No se pudieron cargar tus disciplinas. '
        'Revisa tu conexión e intenta de nuevo.';
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_liberado) super.notifyListeners();
  }

  @override
  void dispose() {
    _liberado = true;
    _suscripcionInscritos?.cancel();
    _suscripcionDeportes?.cancel();
    _suscripcionEventos?.cancel();
    super.dispose();
  }
}
