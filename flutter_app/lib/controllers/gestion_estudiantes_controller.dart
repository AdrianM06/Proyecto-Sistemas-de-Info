import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/usuario.dart';
import '../services/gestion_estudiantes_service.dart';

/// Controlador (la "C" de MVC) de la gestión de estudiantes del panel admin.
///
/// Escucha a los estudiantes en tiempo real y permite habilitarlos o
/// deshabilitarlos (`estadoActivo`). El cambio se ve en el interruptor al
/// instante; si Firestore lo rechaza, el interruptor vuelve a su estado.
///
/// Un estudiante deshabilitado **sí puede iniciar sesión** y entrar a la
/// plataforma; lo que no puede es inscribirse en disciplinas nuevas.
class GestionEstudiantesController extends ChangeNotifier {
  GestionEstudiantesController({required GestionEstudiantesDataSource datos})
    : _datos = datos;

  final GestionEstudiantesDataSource _datos;

  StreamSubscription<List<Usuario>>? _suscripcion;
  List<Usuario>? _estudiantes;
  String? _error;
  String _busqueda = '';

  /// Estado elegido en la pantalla que Firestore todavía no confirmó.
  final Map<String, bool> _pendientes = {};
  bool _liberado = false;

  bool get cargando => _estudiantes == null && _error == null;
  String? get error => _error;
  String get busqueda => _busqueda;

  /// `true` mientras se guarda el cambio de ese estudiante.
  bool guardando(String uid) => _pendientes.containsKey(uid);

  /// Estado que se muestra: el que se acaba de elegir o el de Firestore.
  bool estaActivo(Usuario estudiante) =>
      _pendientes[estudiante.uid] ?? estudiante.estadoActivo;

  List<Usuario> get _todos => [...?_estudiantes]
    ..sort(
      (a, b) => a.nombreCompleto.toLowerCase().compareTo(
        b.nombreCompleto.toLowerCase(),
      ),
    );

  /// Estudiantes ordenados por nombre y filtrados por la búsqueda (nombre,
  /// correo, carnet o cédula).
  List<Usuario> get estudiantes {
    final texto = _busqueda.trim().toLowerCase();
    if (texto.isEmpty) return _todos;
    return _todos.where((e) {
      return e.nombreCompleto.toLowerCase().contains(texto) ||
          e.email.toLowerCase().contains(texto) ||
          (e.carnet ?? '').contains(texto) ||
          (e.cedula ?? '').toLowerCase().contains(texto);
    }).toList();
  }

  int get activos => (_estudiantes ?? const []).where(estaActivo).length;
  int get inactivos => (_estudiantes?.length ?? 0) - activos;

  void iniciar() {
    _suscripcion?.cancel();
    _error = null;
    _estudiantes = null;
    notifyListeners();
    _suscripcion = _datos.estudiantes().listen(
      (lista) {
        _estudiantes = lista;
        notifyListeners();
      },
      onError: (Object _) {
        _error =
            'No se pudieron cargar los estudiantes. '
            'Revisa tu conexión e intenta de nuevo.';
        notifyListeners();
      },
    );
  }

  void buscar(String texto) {
    _busqueda = texto;
    notifyListeners();
  }

  /// Habilita o deshabilita a [estudiante]. Devuelve el error o `null` si se
  /// guardó.
  Future<String?> cambiarEstado(Usuario estudiante, bool activo) async {
    if (guardando(estudiante.uid)) return null;
    _pendientes[estudiante.uid] = activo;
    notifyListeners();
    try {
      await _datos.cambiarEstado(uid: estudiante.uid, activo: activo);
      return null;
    } on GestionEstudiantesException catch (e) {
      return e.mensaje;
    } catch (_) {
      return 'No se pudo guardar el cambio. Intenta de nuevo.';
    } finally {
      _pendientes.remove(estudiante.uid);
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
    _suscripcion?.cancel();
    super.dispose();
  }
}
