import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/controllers/formulario_disciplina_controller.dart';
import 'package:flutter_app/models/deporte.dart';
import 'package:flutter_app/models/usuario.dart';
import 'package:flutter_app/services/gestion_entrenadores_service.dart';
import 'package:flutter_app/views/admin/crear_deporte_view.dart';
import 'package:flutter_test/flutter_test.dart';

class _Datos implements GestionEntrenadoresDataSource {
  final entrenadoresFlujo = StreamController<List<Usuario>>.broadcast();
  final deportesFlujo = StreamController<List<Deporte>>.broadcast();
  Deporte? guardada;

  @override
  Stream<List<Usuario>> entrenadores() => entrenadoresFlujo.stream;

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
  Future<void> guardarDisciplina(Deporte deporte) async => guardada = deporte;
}

const _ana = Usuario(
  uid: 'ana',
  email: 'ana@unimet.edu.ve',
  nombre: 'Ana',
  apellido: 'Rojas',
  rol: RolUsuario.entrenador,
);

const _luis = Usuario(
  uid: 'luis',
  email: 'luis@unimet.edu.ve',
  nombre: 'Luis',
  apellido: 'Pérez',
  rol: RolUsuario.entrenador,
);

const _futbol = Deporte(
  id: 'fut',
  nombre: 'Fútbol',
  disciplina: 'Fútbol',
  cupos: 30,
  entrenadoresIds: ['ana'],
  horarios: ['Lun y Mié 4:00 pm - 6:00 pm'],
);

void main() {
  late _Datos datos;

  Future<void> abrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    datos = _Datos();
    await tester.pumpWidget(
      MaterialApp(
        home: CrearDeporteView(
          controller: FormularioDisciplinaController(datos: datos),
        ),
      ),
    );
    datos.entrenadoresFlujo.add([_ana, _luis]);
    datos.deportesFlujo.add([_futbol]);
    await tester.pump();
  }

  Future<void> agregarHorario(WidgetTester tester, String texto) async {
    await tester.enterText(find.byKey(const Key('campo-horario')), texto);
    await tester.tap(find.byKey(const Key('agregar-horario')));
    await tester.pump();
  }

  testWidgets('interpreta el horario y muestra la duración', (tester) async {
    await abrir(tester);

    await agregarHorario(tester, 'Martes 5 pm');
    expect(find.textContaining('Indica la hora de inicio'), findsOneWidget);

    await agregarHorario(tester, 'Mar y Jue 5:00 pm - 6:30 pm');
    expect(
      find.text(
        'Mar 5:00 pm – 6:30 pm (1 h 30 min)\n'
        'Jue 5:00 pm – 6:30 pm (1 h 30 min)',
      ),
      findsOneWidget,
    );
  });

  testWidgets('un entrenador con choque muestra el diálogo y no se marca', (
    tester,
  ) async {
    await abrir(tester);
    await tester.enterText(
      find.byKey(const Key('campo-nombre-disciplina')),
      'Voleibol',
    );
    await agregarHorario(tester, 'Lun 5:00 pm - 7:00 pm');

    await tester.tap(find.byKey(const Key('elegir-entrenador-ana')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dialogo-choque-horario')), findsOneWidget);
    expect(find.textContaining('Fútbol'), findsWidgets);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();

    final chip = tester.widget<FilterChip>(
      find.byKey(const Key('elegir-entrenador-ana')),
    );
    expect(chip.selected, isFalse);
  });

  testWidgets('guarda con varios entrenadores', (tester) async {
    await abrir(tester);
    await tester.enterText(
      find.byKey(const Key('campo-nombre-disciplina')),
      'Voleibol',
    );
    await tester.enterText(find.byKey(const Key('campo-cupos')), '16');
    await agregarHorario(tester, 'Vie 5:00 pm - 7:00 pm');
    await tester.tap(find.byKey(const Key('elegir-entrenador-ana')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('elegir-entrenador-luis')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('boton-guardar-disciplina')));
    await tester.pumpAndSettle();

    expect(datos.guardada?.nombre, 'Voleibol');
    expect(datos.guardada?.entrenadoresIds, ['ana', 'luis']);
    expect(datos.guardada?.cupos, 16);
  });
}
