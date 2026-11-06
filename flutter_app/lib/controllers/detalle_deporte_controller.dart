import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/resena.dart';
import '../services/resena_service.dart';
import '../services/firestore_service.dart';

class DetalleDeporteController extends ChangeNotifier {
  DetalleDeporteController({
    required this.deporteId,
    required this.estudianteId,
    required ResenasDataSource datos,
  }) : _datos = datos;

  final String deporteId;
  final String estudianteId; // El uid del usuario logueado[cite: 2]
  final ResenasDataSource _datos;

  StreamSubscription<List<Resena>>? _suscripcionResenas;
  List<Resena>? _resenas;
  
  bool _enviando = false;
  String? _error;
  bool _liberado = false;

  List<Resena>? get resenas => _resenas;
  bool get cargando => _resenas == null && _error == null;
  bool get enviando => _enviando;
  String? get error => _error;

  /// Inicia la escucha en tiempo real de las reseñas.
  void iniciar() {
    _suscripcionResenas?.cancel();
    _error = null;
    notifyListeners();

    _suscripcionResenas = _datos.reseñasDe(deporteId).listen(
      (lista) {
        _resenas = lista;
        notifyListeners();
      },
      onError: (e) {
        _error = 'No se pudieron cargar las reseñas.';
        notifyListeners();
      },
    );
  }

  /// Lógica de negocio: Verifica inscripción y publica la reseña.
  Future<bool> publicarResena(int calificacion, String comentario) async {
    if (comentario.trim().isEmpty) {
      _error = 'El comentario no puede estar vacío.';
      notifyListeners();
      return false;
    }

    _enviando = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Validar regla de negocio: ¿Está inscrito?
      // Consultamos la colección 'enrollments' usando FirestoreService.instance[cite: 6]
      final inscripciones = await FirestoreService.instance.enrollments
          .where('estudianteId', isEqualTo: estudianteId)
          .where('deporteId', isEqualTo: deporteId)
          .where('estadoActivo', isEqualTo: true)
          .get();

      if (inscripciones.docs.isEmpty) {
        _error = 'Debes estar inscrito en esta disciplina para dejar una reseña.';
        return false;
      }

      // 2. Si está inscrito, crear el modelo y guardar
      final nuevaResena = Resena(
        id: '', // Firestore lo generará al usar add() en el Service
        estudianteId: estudianteId,
        calificacion: calificacion,
        comentario: comentario.trim(),
        fecha: DateTime.now(),
      );

      await _datos.agregarResena(deporteId, nuevaResena);
      return true;

    } catch (e) {
      _error = 'Error al publicar la reseña. Intenta de nuevo.';
      return false;
    } finally {
      _enviando = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _liberado = true;
    _suscripcionResenas?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_liberado) super.notifyListeners();
  }
}
