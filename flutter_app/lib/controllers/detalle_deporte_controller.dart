import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/resena.dart';
import '../services/resena_service.dart';

/// Controlador (la "C" de MVC) del detalle de una disciplina con sus reseñas.
///
/// Escucha las reseñas en tiempo real, calcula el promedio y deja publicar
/// o editar la reseña del estudiante que inició sesión, solo si tiene o tuvo
/// una inscripción en la disciplina.
class DetalleDeporteController extends ChangeNotifier {
  DetalleDeporteController({
    required ResenasDataSource datos,
    required this.deporteId,
    this.estudianteId,
  }) : _datos = datos;

  final ResenasDataSource _datos;
  final String deporteId;

  /// Uid del estudiante con sesión; `null` si nadie inició sesión como
  /// estudiante (entonces solo se pueden leer las reseñas).
  final String? estudianteId;

  StreamSubscription<List<Resena>>? _suscripcion;
  List<Resena>? _resenas;
  String? _errorCarga;
  bool _verificando = false;
  bool _participo = false;
  bool _enviando = false;
  bool _liberado = false;

  bool get cargando => _resenas == null && _errorCarga == null;
  String? get errorCarga => _errorCarga;
  List<Resena> get resenas => List.unmodifiable(_resenas ?? const <Resena>[]);
  int get cantidad => _resenas?.length ?? 0;

  /// Promedio de estrellas, o `null` si todavía no hay reseñas.
  double? get promedio {
    final lista = _resenas;
    if (lista == null || lista.isEmpty) return null;
    final suma = lista.fold<int>(0, (total, resena) => total + resena.rating);
    return suma / lista.length;
  }

  /// La reseña que ya publicó el estudiante, si existe.
  Resena? get miResena {
    final id = estudianteId;
    if (id == null) return null;
    for (final resena in _resenas ?? const <Resena>[]) {
      if (resena.estudianteId == id) return resena;
    }
    return null;
  }

  bool get haySesion => estudianteId != null;

  /// `true` mientras se comprueba si el estudiante participó en la disciplina.
  bool get verificando => _verificando;

  /// `true` si el estudiante puede publicar (o editar) su reseña.
  bool get puedeResenar => haySesion && _participo;
  bool get enviando => _enviando;

  /// Empieza a escuchar las reseñas y comprueba si el estudiante participó.
  void iniciar() {
    _suscripcion?.cancel();
    _errorCarga = null;
    notifyListeners();
    _suscripcion = _datos
        .resenasDe(deporteId)
        .listen(
          (lista) {
            _resenas = lista;
            _errorCarga = null;
            notifyListeners();
          },
          onError: (Object _) {
            _errorCarga =
                'No se pudieron cargar las reseñas. '
                'Revisa tu conexión e intenta de nuevo.';
            notifyListeners();
          },
        );
    _verificarParticipacion();
  }

  Future<void> _verificarParticipacion() async {
    final id = estudianteId;
    if (id == null) return;
    _verificando = true;
    notifyListeners();
    try {
      _participo = await _datos.participoEn(
        estudianteId: id,
        deporteId: deporteId,
      );
    } catch (_) {
      _participo = false;
    } finally {
      _verificando = false;
      notifyListeners();
    }
  }

  /// Reglas del formulario. Devuelve el primer error o `null` si es válido.
  static String? validar(int rating, String comment) {
    if (rating < Resena.ratingMinimo || rating > Resena.ratingMaximo) {
      return 'Elige de 1 a 5 estrellas.';
    }
    final texto = comment.trim();
    if (texto.isEmpty) return 'Escribe un comentario.';
    if (texto.length > Resena.largoMaximo) {
      return 'El comentario no puede pasar de ${Resena.largoMaximo} caracteres.';
    }
    return null;
  }

  /// Publica la reseña del estudiante o actualiza la que ya tenía.
  /// Devuelve el mensaje de error o `null` si se guardó.
  Future<String?> publicar({
    required int rating,
    required String comment,
  }) async {
    final id = estudianteId;
    if (id == null)
      return 'Inicia sesión como estudiante para dejar una reseña.';
    if (!_participo) {
      return 'Solo pueden opinar los estudiantes inscritos en esta disciplina.';
    }
    final error = validar(rating, comment);
    if (error != null) return error;
    if (_enviando) return null;

    _enviando = true;
    notifyListeners();
    try {
      await _datos.guardar(
        estudianteId: id,
        deporteId: deporteId,
        rating: rating,
        comment: comment.trim(),
        esNueva: miResena == null,
      );
      return null;
    } on ResenaException catch (e) {
      return e.mensaje;
    } catch (_) {
      return 'No se pudo guardar la reseña. Intenta de nuevo.';
    } finally {
      _enviando = false;
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
