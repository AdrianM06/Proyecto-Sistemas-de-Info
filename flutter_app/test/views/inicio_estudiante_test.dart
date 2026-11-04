import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/controllers/inicio_estudiante_controller.dart';
import 'package:flutter_app/models/deporte.dart';
import 'package:flutter_app/services/inicio_estudiante_service.dart';
import 'package:flutter_app/views/student_view.dart';
import 'package:flutter_app/views/theme/saman_colors.dart';
import 'package:flutter_test/flutter_test.dart';

/// Flujos que el test controla a mano, como si fueran los `snapshots()` de
/// Firestore.
class _Datos implements InicioEstudianteDataSource {
  final _inscritos = StreamController<Set<String>>.broadcast();
  final _deportes = StreamController<List<Deporte>>.broadcast();

  @override
  Stream<Set<String>> deportesInscritos(String estudianteId) =>
      _inscritos.stream;

  @override
  Stream<List<Deporte>> deportes() => _deportes.stream;

  void inscritos(Set<String> ids) => _inscritos.add(ids);
  void deportes_(List<Deporte> lista) => _deportes.add(lista);
  void fallar() => _inscritos.addError(StateError('sin red'));
}

const _futbol = Deporte(
  id: 'fut',
  nombre: 'Futbol Campo Masculino',
  disciplina: 'Futbol Campo',
  cupos: 30,
  entrenadorId: 'e1',
  horarios: ['Lun y Mié 12:15 PM - 1:45 PM'],
  lugar: 'Cancha Futbol Campo',
);

const _ajedrez = Deporte(
  id: 'aje',
  nombre: 'Ajedrez',
  disciplina: 'Ajedrez',
  cupos: 20,
  entrenadorId: 'e2',
  horarios: ['Martes y Jueves 3:00 PM - 5:00 PM'],
);

void main() {
  // Miércoles 21 de octubre de 2026.
  final hoy = DateTime(2026, 10, 21);

  late _Datos datos;
  late InicioEstudianteController controlador;

  setUp(() {
    datos = _Datos();
    controlador = InicioEstudianteController(
      datos: datos,
      estudianteId: 'est-01',
      reloj: () => hoy,
    );
  });

  Future<void> emitir() => Future<void>.delayed(Duration.zero);

  group('controlador', () {
    test('espera los dos flujos antes de dejar de cargar', () async {
      controlador.iniciar();
      expect(controlador.cargando, isTrue);

      datos.deportes_([_futbol, _ajedrez]);
      await emitir();
      expect(controlador.cargando, isTrue);

      datos.inscritos({'fut'});
      await emitir();
      expect(controlador.cargando, isFalse);
      expect(controlador.disciplinas.map((d) => d.id), ['fut']);
      controlador.dispose();
    });

    test('al inscribirse o retirarse se actualiza sin recargar', () async {
      controlador.iniciar();
      datos.deportes_([_futbol, _ajedrez]);
      datos.inscritos({'fut'});
      await emitir();

      datos.inscritos({'fut', 'aje'});
      await emitir();
      expect(controlador.disciplinas.map((d) => d.id), ['aje', 'fut']);

      datos.inscritos({'aje'});
      await emitir();
      expect(controlador.disciplinas.map((d) => d.id), ['aje']);
      controlador.dispose();
    });

    test(
      'si el administrador cambia un horario, el calendario lo refleja',
      () async {
        controlador.iniciar();
        datos.deportes_([_futbol]);
        datos.inscritos({'fut'});
        await emitir();
        expect(controlador.entrenamientosDe(DateTime(2026, 10, 23)), isEmpty);

        datos.deportes_([
          const Deporte(
            id: 'fut',
            nombre: 'Futbol Campo Masculino',
            disciplina: 'Futbol Campo',
            cupos: 30,
            entrenadorId: 'e1',
            horarios: ['Vie 4:00 PM - 6:00 PM'],
          ),
        ]);
        await emitir();
        expect(
          controlador.entrenamientosDe(DateTime(2026, 10, 23)),
          isNotEmpty,
        );
        expect(controlador.entrenamientosDe(DateTime(2026, 10, 21)), isEmpty);
        controlador.dispose();
      },
    );

    test(
      'el próximo entrenamiento es el primer día con clase desde hoy',
      () async {
        controlador.iniciar();
        datos.deportes_([_futbol, _ajedrez]);
        datos.inscritos({'fut'});
        await emitir();
        expect(controlador.proximoEntrenamiento, DateTime(2026, 10, 21));

        datos.inscritos({'aje'});
        await emitir();
        expect(controlador.proximoEntrenamiento, DateTime(2026, 10, 22));

        datos.inscritos({});
        await emitir();
        expect(controlador.proximoEntrenamiento, isNull);
        controlador.dispose();
      },
    );

    test('un error deja un mensaje y se puede reintentar', () async {
      controlador.iniciar();
      datos.fallar();
      await emitir();
      expect(controlador.error, isNotNull);
      expect(controlador.cargando, isFalse);

      controlador.iniciar();
      expect(controlador.error, isNull);
      controlador.dispose();
    });

    test('si se cierra la pantalla, los datos que llegan no fallan', () async {
      controlador.iniciar();
      controlador.dispose();
      datos.inscritos({'fut'});
      await emitir();
    });
  });

  group('pantalla', () {
    Future<void> abrir(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: SamanColors.tema(),
          home: StudentView(controller: controlador, onIrACatalogo: () {}),
        ),
      );
    }

    testWidgets('sin inscripciones invita a inscribirse', (tester) async {
      await abrir(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      datos.deportes_([_futbol, _ajedrez]);
      datos.inscritos({});
      await tester.pump();

      expect(find.byKey(const Key('sin-disciplinas')), findsOneWidget);
      expect(find.byKey(const Key('titulo-mes')), findsOneWidget);
      expect(find.text('Octubre 2026'), findsOneWidget);
    });

    testWidgets('al inscribirse aparecen la disciplina y los días marcados', (
      tester,
    ) async {
      await abrir(tester);
      datos.deportes_([_futbol, _ajedrez]);
      datos.inscritos({});
      await tester.pump();
      expect(find.byKey(const Key('disciplina-fut')), findsNothing);

      // El estudiante se inscribe en otra pantalla: llega por el flujo.
      datos.inscritos({'fut'});
      await tester.pump();

      expect(find.byKey(const Key('disciplina-fut')), findsOneWidget);
      expect(find.byKey(const Key('sin-disciplinas')), findsNothing);
      // Lunes 19 y miércoles 21 entrenan; el martes 20 no.
      expect(find.byKey(const Key('entrena-2026-10-19')), findsOneWidget);
      expect(find.byKey(const Key('entrena-2026-10-21')), findsOneWidget);
      expect(find.byKey(const Key('entrena-2026-10-20')), findsNothing);
      expect(find.textContaining('Próximo entrenamiento'), findsOneWidget);

      // Se retira: todo desaparece sin recargar.
      datos.inscritos({});
      await tester.pump();
      expect(find.byKey(const Key('disciplina-fut')), findsNothing);
      expect(find.byKey(const Key('entrena-2026-10-19')), findsNothing);
      expect(find.byKey(const Key('sin-disciplinas')), findsOneWidget);
    });

    testWidgets('tocar un día muestra qué entrena ese día', (tester) async {
      await abrir(tester);
      datos.deportes_([_futbol, _ajedrez]);
      datos.inscritos({'fut', 'aje'});
      await tester.pump();

      // Hoy (miércoles) entrena Futbol.
      expect(find.byKey(const Key('entrenamiento-fut')), findsOneWidget);
      expect(find.byKey(const Key('entrenamiento-aje')), findsNothing);

      await tester.tap(find.byKey(const Key('dia-2026-10-22')));
      await tester.pump();
      expect(find.byKey(const Key('entrenamiento-aje')), findsOneWidget);
      expect(find.byKey(const Key('entrenamiento-fut')), findsNothing);

      await tester.tap(find.byKey(const Key('dia-2026-10-24')));
      await tester.pump();
      expect(find.byKey(const Key('sin-entrenamientos-dia')), findsOneWidget);
    });

    testWidgets('se puede cambiar de mes', (tester) async {
      await abrir(tester);
      datos.deportes_([_futbol]);
      datos.inscritos({'fut'});
      await tester.pump();

      await tester.tap(find.byKey(const Key('mes-siguiente')));
      await tester.pump();
      expect(find.text('Noviembre 2026'), findsOneWidget);
      // Lunes 2 de noviembre entrena Futbol.
      expect(find.byKey(const Key('entrena-2026-11-02')), findsOneWidget);

      await tester.tap(find.byKey(const Key('mes-anterior')));
      await tester.tap(find.byKey(const Key('mes-anterior')));
      await tester.pump();
      expect(find.text('Septiembre 2026'), findsOneWidget);
    });

    testWidgets('si falla la carga muestra el error y permite reintentar', (
      tester,
    ) async {
      await abrir(tester);
      datos.fallar();
      await tester.pump();

      expect(find.byKey(const Key('error-disciplinas')), findsOneWidget);
      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      expect(find.byKey(const Key('error-disciplinas')), findsNothing);
    });
  });
}
