import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/cancha.dart';
import '../models/conversores.dart';
import '../models/deporte.dart';
import '../models/evento.dart';
import '../services/canchas_service.dart';
import '../services/eventos_service.dart';
import '../services/gestion_entrenadores_service.dart';

class GestionEventosController extends ChangeNotifier {
  GestionEventosController({
    required this.adminId,
    EventosDataSource? eventosDatos,
    CanchasDataSource? canchasDatos,
    GestionEntrenadoresDataSource? deportesDatos,
  })  : _eventosDatos = eventosDatos ?? EventosService(),
        _canchasDatos = canchasDatos ?? CanchasService(),
        _deportesDatos = deportesDatos ?? GestionEntrenadoresService();

  final String adminId;
  final EventosDataSource _eventosDatos;
  final CanchasDataSource _canchasDatos;
  final GestionEntrenadoresDataSource _deportesDatos;

  StreamSubscription<List<EventoDeportivo>>? _subEventos;
  StreamSubscription<List<Cancha>>? _subCanchas;
  StreamSubscription<List<Deporte>>? _subDeportes;

  List<EventoDeportivo>? _eventos;
  List<Cancha> _canchas = const [];
  List<Deporte> _deportes = const [];
  String? _error;
  bool _guardando = false;
  bool _liberado = false;

  bool get cargando => _eventos == null && _error == null;
  bool get guardando => _guardando;
  String? get error => _error;
  List<EventoDeportivo> get eventos => List.unmodifiable(_eventos ?? const []);
  List<Cancha> get canchasActivas =>
      _canchas.where((c) => c.activa).toList(growable: false);
  List<Deporte> get deportes => [..._deportes]
    ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

  void iniciar() {
    _subEventos?.cancel();
    _subCanchas?.cancel();
    _subDeportes?.cancel();
    _error = null;
    _eventos = null;
    notifyListeners();

    _subEventos = _eventosDatos.eventos().listen(
      (lista) {
        _eventos = lista;
        notifyListeners();
      },
      onError: (_) {
        _error = 'No se pudieron cargar los eventos.';
        notifyListeners();
      },
    );
    _subCanchas = _canchasDatos.canchas().listen((lista) {
      _canchas = lista;
      notifyListeners();
    });
    _subDeportes = _deportesDatos.deportes().listen((lista) {
      _deportes = lista;
      notifyListeners();
    });
  }

  Future<String?> crearEvento({
    required String titulo,
    required Deporte? deporte,
    required Cancha? cancha,
    required DateTime? fecha,
    required int horaInicio,
    required int horaFin,
    String descripcion = '',
  }) async {
    if (titulo.trim().isEmpty) return 'Ingresa el título del evento.';
    if (deporte == null) return 'Selecciona una disciplina.';
    if (cancha == null) return 'Selecciona una cancha de la lista.';
    if (fecha == null) return 'Selecciona la fecha del evento.';
    if (horaFin <= horaInicio) {
      return 'La hora de fin debe ser posterior a la hora de inicio.';
    }
    if (_guardando) return null;

    final evento = EventoDeportivo(
      id: '',
      titulo: titulo.trim(),
      descripcion: descripcion.trim(),
      deporteId: deporte.id,
      deporteNombre: deporte.nombre,
      canchaId: cancha.id,
      canchaNombre: cancha.nombre,
      fecha: soloFecha(fecha),
      horaInicio: horaInicio,
      horaFin: horaFin,
      creadoPor: adminId,
    );

    _guardando = true;
    notifyListeners();
    try {
      await _eventosDatos.crearEvento(evento);
      return null;
    } on EventosException catch (e) {
      return e.mensaje;
    } catch (_) {
      return 'No se pudo guardar el evento. Intenta de nuevo.';
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }

  Future<String?> eliminarEvento(EventoDeportivo evento) async {
    try {
      await _eventosDatos.eliminarEvento(evento.id);
      return null;
    } on EventosException catch (e) {
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
    _subEventos?.cancel();
    _subCanchas?.cancel();
    _subDeportes?.cancel();
    super.dispose();
  }
}
