import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/bloque_horario.dart';
import '../models/deporte.dart';
import '../models/usuario.dart';
import '../services/gestion_entrenadores_service.dart';
import '../utils/choques_horario.dart';
import '../utils/horarios.dart';

/// Controlador (la "C" de MVC) del formulario para crear o editar una
/// disciplina.
///
/// Maneja la lista de horarios (cada uno se interpreta en bloques de día +
/// hora de inicio + hora de fin) y la lista de entrenadores. Al elegir un
/// entrenador comprueba, con los datos en tiempo real, que los horarios no
/// choquen con las otras disciplinas que dicta; el servicio lo vuelve a
/// comprobar dentro de la transacción al guardar.
class FormularioDisciplinaController extends ChangeNotifier {
  FormularioDisciplinaController({
    required GestionEntrenadoresDataSource datos,
    this.original,
  }) : _datos = datos,
       _horarios = [...?original?.horarios],
       _seleccionados = [...?original?.entrenadoresIds];

  final GestionEntrenadoresDataSource _datos;

  /// Disciplina que se edita, o `null` si se está creando una nueva.
  final Deporte? original;

  final List<String> _horarios;
  final List<String> _seleccionados;
  StreamSubscription<List<Usuario>>? _suscripcionEntrenadores;
  StreamSubscription<List<Deporte>>? _suscripcionDeportes;
  List<Usuario> _entrenadores = const [];
  List<Deporte> _deportes = const [];
  bool _cargandoEntrenadores = true;
  bool _guardando = false;
  bool _ultimoErrorFueChoque = false;
  bool _liberado = false;

  bool get editando => original != null;
  bool get guardando => _guardando;
  bool get cargandoEntrenadores => _cargandoEntrenadores;

  /// `true` si el último error de [guardar] o [alternarEntrenador] fue un
  /// choque de horario (la vista lo muestra en un diálogo).
  bool get ultimoErrorFueChoque => _ultimoErrorFueChoque;

  List<String> get horarios => List.unmodifiable(_horarios);

  /// Bloques estructurados de todos los horarios, ordenados.
  List<BloqueHorario> get bloques => bloquesDeHorarios(_horarios);

  /// Entrenadores registrados, ordenados por nombre.
  List<Usuario> get entrenadores => [..._entrenadores]
    ..sort(
      (a, b) => a.nombreCompleto.toLowerCase().compareTo(
        b.nombreCompleto.toLowerCase(),
      ),
    );

  List<String> get seleccionados => List.unmodifiable(_seleccionados);
  bool estaSeleccionado(Usuario entrenador) =>
      _seleccionados.contains(entrenador.uid);

  void iniciar() {
    _suscripcionEntrenadores = _datos.entrenadores().listen(
      (lista) {
        _entrenadores = lista;
        _cargandoEntrenadores = false;
        notifyListeners();
      },
      onError: (Object _) {
        _cargandoEntrenadores = false;
        notifyListeners();
      },
    );
    _suscripcionDeportes = _datos.deportes().listen((lista) {
      _deportes = lista;
      notifyListeners();
    }, onError: (Object _) {});
  }

  /// Agrega una línea de horario como "Lun y Mié 4:00 pm - 6:00 pm".
  /// Devuelve el error para mostrar, o `null` si se agregó.
  String? agregarHorario(String texto) {
    final limpio = texto.trim();
    if (limpio.isEmpty) return 'Escribe el horario.';
    final resultado = interpretarHorario(limpio);
    if (!resultado.esValido) return resultado.error;
    final error = validarHorarios([..._horarios, limpio]);
    if (error != null) return error;
    _horarios.add(limpio);
    notifyListeners();
    return null;
  }

  void quitarHorario(String horario) {
    _horarios.remove(horario);
    notifyListeners();
  }

  /// Choques de los horarios actuales con las otras disciplinas que dicta
  /// [entrenador].
  List<ChoqueHorario> choquesDe(Usuario entrenador) {
    return buscarChoques(
      bloques: bloques,
      asignadas: [
        for (final deporte in _deportes)
          if (deporte.tieneEntrenador(entrenador.uid)) deporte,
      ],
      disciplinaId: original?.id,
    );
  }

  /// Marca o desmarca a [entrenador]. No lo marca si su horario choca;
  /// entonces devuelve el mensaje del choque.
  String? alternarEntrenador(Usuario entrenador, {String? nombreDisciplina}) {
    _ultimoErrorFueChoque = false;
    if (_seleccionados.remove(entrenador.uid)) {
      notifyListeners();
      return null;
    }
    final mensaje = mensajeDeChoques(
      entrenador: entrenador.nombreCompleto,
      disciplina: _nombreOEsta(nombreDisciplina),
      choques: choquesDe(entrenador),
    );
    if (mensaje != null) {
      _ultimoErrorFueChoque = true;
      return mensaje;
    }
    _seleccionados.add(entrenador.uid);
    notifyListeners();
    return null;
  }

  String _nombreOEsta(String? nombre) =>
      (nombre ?? '').trim().isEmpty ? 'esta disciplina' : nombre!.trim();

  String _nombreDe(String uid) {
    for (final entrenador in _entrenadores) {
      if (entrenador.uid == uid) return entrenador.nombreCompleto;
    }
    return original?.entrenadoresNombres[uid] ?? 'Entrenador';
  }

  /// Valida y guarda la disciplina. Devuelve el error o `null` si se guardó.
  Future<String?> guardar({
    required String nombre,
    required String disciplina,
    required String lugar,
    required int cupos,
    required List<String> etiquetas,
  }) async {
    _ultimoErrorFueChoque = false;
    if (nombre.trim().isEmpty) return 'Ingresa el nombre de la disciplina.';
    if (cupos <= 0) return 'Los cupos deben ser un número mayor que cero.';
    final errorHorarios = validarHorarios(_horarios);
    if (errorHorarios != null) return errorHorarios;

    for (final uid in _seleccionados) {
      final entrenador = _entrenadores.where((e) => e.uid == uid);
      if (entrenador.isEmpty) continue;
      final mensaje = mensajeDeChoques(
        entrenador: entrenador.first.nombreCompleto,
        disciplina: nombre.trim(),
        choques: choquesDe(entrenador.first),
      );
      if (mensaje != null) {
        _ultimoErrorFueChoque = true;
        return mensaje;
      }
    }
    if (_guardando) return null;

    final deporte = Deporte(
      id: original?.id ?? '',
      nombre: nombre.trim(),
      disciplina: disciplina.trim(),
      cupos: cupos,
      entrenadoresIds: List.of(_seleccionados),
      entrenadoresNombres: {
        for (final uid in _seleccionados) uid: _nombreDe(uid),
      },
      horarios: List.of(_horarios),
      bloques: bloques,
      lugar: lugar.trim(),
      etiquetas: etiquetas,
    );

    _guardando = true;
    notifyListeners();
    try {
      await _datos.guardarDisciplina(deporte);
      return null;
    } on ChoqueHorarioException catch (e) {
      _ultimoErrorFueChoque = true;
      return e.mensaje;
    } on GestionEntrenadoresException catch (e) {
      return e.mensaje;
    } catch (_) {
      return 'No se pudo guardar la disciplina. Intenta de nuevo.';
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }

  @override
  void notifyListeners() {
    if (!_liberado) super.notifyListeners();
  }

  @override
  void dispose() {
    _liberado = true;
    _suscripcionEntrenadores?.cancel();
    _suscripcionDeportes?.cancel();
    super.dispose();
  }
}
