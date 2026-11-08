import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/models/deporte.dart';
import 'package:flutter_app/models/usuario.dart';
import 'package:flutter_app/services/baja_disciplina_service.dart';
import 'package:flutter_app/services/gestion_entrenadores_service.dart';
import 'package:flutter_app/views/admin/gestion_disciplinas_view.dart';
import 'package:flutter_test/flutter_test.dart';

class _Datos implements GestionEntrenadoresDataSource {
  final deportesFlujo = StreamController<List<Deporte>>.broadcast();

  @override
  Stream<List<Usuario>> entrenadores() => const Stream.empty();

  @override
  Stream<List<Deporte>> deportes() => deportesFlujo.stream;

  @override
  Future<void> asignar({
    required String entrenadorId,
    required String entrenadorNombre,
    required String deporteId,
  }) async {}

  @override
  Future<void> revocar({
    required String entrenadorId,
    required String deporteId,
  }) async {}

  @override
  Future<void> guardarDisciplina(Deporte deporte) async {}
}

class _Baja implements BajaDisciplinaDataSource {
  _Baja({this.inscritos = 0, this.error});

  final int inscritos;
  final BajaDisciplinaException? error;
  final eliminadas = <String>[];

  @override
  Future<int> inscripcionesActivas(String deporteId) async => inscritos;

  @override
  Future<void> eliminar(String deporteId) async {
    final falla = error;
    if (falla != null) throw falla;
    eliminadas.add(deporteId);
  }
}

const _futbol = Deporte(
  id: 'fut',
  nombre: 'Fútbol Campo',
  disciplina: 'Fútbol',
  cupos: 30,
  horarios: ['Lun y Mié 4:00 pm - 6:00 pm'],
);

void main() {
  late _Datos datos;

  Future<void> abrir(WidgetTester tester, {BajaDisciplinaDataSource? baja}) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    datos = _Datos();
    await tester.pumpWidget(
      MaterialApp(
        home: GestionDisciplinasView(
          datos: datos,
          onEditar: (context, deporte) {},
          baja: baja,
        ),
      ),
    );
    datos.deportesFlujo.add([_futbol]);
    await tester.pump();
  }

  testWidgets('sin servicio de baja no aparece el botón Eliminar', (
    tester,
  ) async {
    await abrir(tester);
    expect(find.byKey(const Key('eliminar-disciplina-fut')), findsNothing);
  });

  testWidgets('advierte cuántos inscritos pierden el cupo y elimina', (
    tester,
  ) async {
    final baja = _Baja(inscritos: 3);
    await abrir(tester, baja: baja);

    await tester.tap(find.byKey(const Key('eliminar-disciplina-fut')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dialogo-eliminar-disciplina')), findsOneWidget);
    expect(find.text('¿Eliminar Fútbol Campo?'), findsOneWidget);
    expect(
      find.text('3 estudiantes inscritos perderán su cupo.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('confirmar-eliminar-disciplina')));
    await tester.pumpAndSettle();

    expect(baja.eliminadas, ['fut']);
    expect(find.text('Se eliminó Fútbol Campo.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('Cancelar no elimina nada', (tester) async {
    final baja = _Baja();
    await abrir(tester, baja: baja);

    await tester.tap(find.byKey(const Key('eliminar-disciplina-fut')));
    await tester.pumpAndSettle();
    expect(find.text('No tiene estudiantes inscritos.'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(baja.eliminadas, isEmpty);
    expect(find.byKey(const Key('dialogo-eliminar-disciplina')), findsNothing);
  });

  testWidgets('si falla, muestra el error', (tester) async {
    final baja = _Baja(
      error: const BajaDisciplinaException('La disciplina ya no existe.'),
    );
    await abrir(tester, baja: baja);

    await tester.tap(find.byKey(const Key('eliminar-disciplina-fut')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmar-eliminar-disciplina')));
    await tester.pumpAndSettle();

    expect(find.text('La disciplina ya no existe.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
