import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/deporte.dart';
import '../models/usuario.dart';
import '../services/gestion_entrenadores_service.dart';

/// Un entrenador con las disciplinas que tiene asignadas ahora mismo.
class EntrenadorConDisciplinas {
  const EntrenadorConDisciplinas({
    required this.entrenador,
    required this.disciplinas,
  });

  final Usuario entrenador;
  final List<Deporte> disciplinas;
}

/// Controlador (la "C" de MVC) de la gestión de entrenadores del panel admin.
///
/// Escucha en tiempo real a los entrenadores y a las disciplinas. Al asignar
/// o quitar una disciplina se escribe `sports/{id}.entrenadorId` y la lista se
/// actualiza sola cuando Firestore confirma el cambio.
class GestionEntrenadoresController extends ChangeNotifier {
  GestionEntrenadoresController({required GestionEntrenadoresDataSource datos})
    : _datos = datos;

  final GestionEntrenadoresDataSource _datos;

  StreamSubscription<List<Usuario>>? _suscripcionEntrenadores;
  StreamSubscription<List<Deporte>>? _suscripcionDeportes;
  List<Usuario>? _entrenadores;
  List<Deporte>? _deportes;
  String? _error;
  String? _ocupado;
  bool _liberado = false;

  bool get cargando =>
      _error == null && (_entrenadores == null || _deportes == null);
  String? get error => _error;

  /// Id de la disciplina que se está asignando o quitando ahora, si hay una.
  String? get ocupado => _ocupado;

  /// Disciplinas con nombre, ordenadas. Los documentos vacíos de `sports` no
  /// se pueden asignar.
  List<Deporte> get deportes {
    return [
      for (final deporte in _deportes ?? const <Deporte>[])
        if (deporte.nombre.trim().isNotEmpty && deporte.nombre != 'Sin nombre')
          deporte,
    ]..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
  }

  /// Entrenadores ordenados por nombre, cada uno con sus disciplinas.
  List<EntrenadorConDisciplinas> get entrenadores {
    final deportes = this.deportes;
    final lista = [
      for (final entrenador in _entrenadores ?? const <Usuario>[])
        EntrenadorConDisciplinas(
          entrenador: entrenador,
          disciplinas: [
            for (final deporte in deportes)
              if (deporte.entrenadorId == entrenador.uid) deporte,
          ],
        ),
    ];
    lista.sort(
      (a, b) => a.entrenador.nombreCompleto.toLowerCase().compareTo(
        b.entrenador.nombreCompleto.toLowerCase(),
      ),
    );
    return lista;
  }

  /// Nombre del entrenador que tiene la disciplina, o `null` si no tiene.
  String? entrenadorDe(Deporte deporte) {
    if (deporte.entrenadorId.isEmpty) return null;
    for (final entrenador in _entrenadores ?? const <Usuario>[]) {
      if (entrenador.uid == deporte.entrenadorId) {
        return entrenador.nombreCompleto;
      }
    }
    return 'otro usuario';
  }

  /// Empieza a escuchar. Se puede llamar de nuevo para reintentar.
  void iniciar() {
    _suscripcionEntrenadores?.cancel();
    _suscripcionDeportes?.cancel();
    _error = null;
    _entrenadores = null;
    _deportes = null;
    notifyListeners();

    _suscripcionEntrenadores = _datos.entrenadores().listen((lista) {
      _entrenadores = lista;
      notifyListeners();
    }, onError: _alFallar);
    _suscripcionDeportes = _datos.deportes().listen((lista) {
      _deportes = lista;
      notifyListeners();
    }, onError: _alFallar);
  }

  void _alFallar(Object error) {
    _error =
        'No se pudieron cargar los entrenadores. '
        'Revisa tu conexión e intenta de nuevo.';
    notifyListeners();
  }

  /// Asigna [deporte] a [entrenador]. Devuelve el error o `null` si se guardó.
  Future<String?> asignar(Usuario entrenador, Deporte deporte) {
    return _cambiar(
      deporte,
      () => _datos.asignar(entrenadorId: entrenador.uid, deporteId: deporte.id),
    );
  }

  /// Quita [deporte] a [entrenador]. Devuelve el error o `null` si se guardó.
  Future<String?> revocar(Usuario entrenador, Deporte deporte) {
    return _cambiar(
      deporte,
      () => _datos.revocar(entrenadorId: entrenador.uid, deporteId: deporte.id),
    );
  }

  Future<String?> _cambiar(
    Deporte deporte,
    Future<void> Function() accion,
  ) async {
    if (_ocupado != null) return 'Espera a que termine el cambio anterior.';
    _ocupado = deporte.id;
    notifyListeners();
    try {
      await accion();
      return null;
    } on GestionEntrenadoresException catch (e) {
      return e.mensaje;
    } catch (e) {
      return 'No se pudo guardar el cambio. Intenta de nuevo.';
    } finally {
      _ocupado = null;
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
