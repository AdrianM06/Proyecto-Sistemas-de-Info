import 'dart:async';

import 'package:flutter_app/models/resena.dart';
import 'package:flutter_app/services/resena_service.dart';

/// Reseñas en memoria. [emitir] simula la llegada de un `snapshots()`.
class ResenasFalsas implements ResenasDataSource {
  ResenasFalsas({this.participa = true, List<Resena> iniciales = const []})
    : lista = [...iniciales];

  final _flujo = StreamController<List<Resena>>.broadcast();
  final List<Resena> lista;
  bool participa;
  String? fallo;
  int guardados = 0;
  bool? ultimaEsNueva;

  void emitir() => _flujo.add(List.of(lista));
  void fallarCarga() => _flujo.addError(StateError('sin red'));

  @override
  Stream<List<Resena>> resenasDe(String deporteId) => _flujo.stream;

  @override
  Future<bool> participoEn({
    required String estudianteId,
    required String deporteId,
  }) async => participa;

  @override
  Future<void> guardar({
    required String estudianteId,
    required String deporteId,
    required int rating,
    required String comment,
    required bool esNueva,
  }) async {
    if (fallo != null) throw ResenaException(fallo!);
    guardados++;
    ultimaEsNueva = esNueva;
    lista.removeWhere((r) => r.estudianteId == estudianteId);
    lista.insert(
      0,
      Resena(
        estudianteId: estudianteId,
        deporteId: deporteId,
        autor: 'Andrea Pérez',
        rating: rating,
        comment: comment,
        createdAt: DateTime(2026, 11, 8),
      ),
    );
    emitir();
  }
}

Resena resena(String estudianteId, int rating, {String comment = 'Muy bien'}) {
  return Resena(
    estudianteId: estudianteId,
    deporteId: 'AJE-01',
    autor: 'Autor $estudianteId',
    rating: rating,
    comment: comment,
    createdAt: DateTime(2026, 11, 1),
  );
}
