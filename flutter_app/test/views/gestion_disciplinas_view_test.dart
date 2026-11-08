import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/models/deporte.dart';
import 'package:flutter_app/models/usuario.dart';
import 'package:flutter_app/services/gestion_entrenadores_service.dart';
import 'package:flutter_app/views/admin/admin_dashboard_view.dart';
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

const _futbol = Deporte(
  id: 'fut',
  nombre: 'Fútbol Campo',
  disciplina: 'Fútbol',
  cupos: 30,
  entrenadoresIds: ['ana'],
  entrenadoresNombres: {'ana': 'Ana Rojas'},
  horarios: ['Lun y Mié 4:00 pm - 6:00 pm'],
  lugar: 'Cancha principal',
  etiquetas: ['Torneos'],
);

const _ajedrez = Deporte(
  id: 'aje',
  nombre: 'Ajedrez',
  disciplina: 'Ajedrez',
  cupos: 20,
  horarios: ['Vie 1:00 pm - 3:00 pm'],
);

const _vacio = Deporte(id: 'x', nombre: 'Sin nombre', disciplina: '', cupos: 0);

void main() {
  late _Datos datos;
  Deporte? editada;

  Future<void> abrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    datos = _Datos();
    editada = null;
    await tester.pumpWidget(
      MaterialApp(
        home: GestionDisciplinasView(
          datos: datos,
          onEditar: (context, deporte) => editada = deporte,
        ),
      ),
    );
    datos.deportesFlujo.add([_futbol, _ajedrez, _vacio]);
    await tester.pump();
  }

  testWidgets('lista las disciplinas con sus datos, ordenadas', (tester) async {
    await abrir(tester);

    expect(find.byKey(const Key('disciplina-admin-x')), findsNothing);
    final ajedrez = tester.getTopLeft(
      find.byKey(const Key('disciplina-admin-aje')),
    );
    final futbol = tester.getTopLeft(
      find.byKey(const Key('disciplina-admin-fut')),
    );
    expect(ajedrez.dy, lessThan(futbol.dy));
    expect(find.text('Entrenadores: Ana Rojas'), findsOneWidget);
    expect(find.text('Entrenadores: Por asignar'), findsOneWidget);
    expect(find.text('Cancha principal'), findsOneWidget);
    expect(find.text('#Torneos'), findsOneWidget);
  });

  testWidgets('el buscador filtra por nombre, entrenador o etiqueta', (
    tester,
  ) async {
    await abrir(tester);

    await tester.enterText(find.byKey(const Key('buscar-disciplina')), 'ana');
    await tester.pump();
    expect(find.byKey(const Key('disciplina-admin-fut')), findsOneWidget);
    expect(find.byKey(const Key('disciplina-admin-aje')), findsNothing);

    await tester.enterText(find.byKey(const Key('buscar-disciplina')), 'zzz');
    await tester.pump();
    expect(find.byKey(const Key('sin-resultados-disciplinas')), findsOneWidget);
  });

  testWidgets('Editar abre el formulario de esa disciplina', (tester) async {
    await abrir(tester);

    await tester.tap(find.byKey(const Key('editar-disciplina-fut')));
    await tester.pump();
    expect(editada?.id, 'fut');
  });

  testWidgets('los cambios llegan en tiempo real', (tester) async {
    await abrir(tester);

    datos.deportesFlujo.add([
      _futbol.conEntrenadores(
        ['ana', 'luis'],
        {'ana': 'Ana Rojas', 'luis': 'Luis Pérez'},
      ),
      _ajedrez,
    ]);
    await tester.pump();
    expect(find.text('Entrenadores: Ana Rojas, Luis Pérez'), findsOneWidget);
  });

  testWidgets(
    'el panel muestra "Gestionar disciplinas" a la derecha de "Crear disciplina"',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      var abierta = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboardView(
            onGestionarDisciplinas: () => abierta = true,
            listaDeportes: const SizedBox.shrink(),
            resumen: const SizedBox.shrink(),
          ),
        ),
      );

      final crear = tester.getRect(
        find.byKey(const Key('admin-crear-deporte')),
      );
      final gestionar = tester.getRect(
        find.byKey(const Key('admin-gestionar-disciplinas')),
      );
      expect(gestionar.left, greaterThan(crear.right));
      expect(gestionar.top, crear.top);

      await tester.tap(find.byKey(const Key('admin-gestionar-disciplinas')));
      expect(abierta, isTrue);
    },
  );
}
