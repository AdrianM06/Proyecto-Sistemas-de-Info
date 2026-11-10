import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/controllers/entrenador_controller.dart';
import 'package:flutter_app/models/asistencia.dart';
import 'package:flutter_app/services/entrenador_demo_service.dart';
import 'package:flutter_app/views/entrenador/detalle_asistencia_estudiante_view.dart';
import 'package:flutter_app/views/entrenador/nomina_view.dart';
import 'package:flutter_app/views/theme/saman_colors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Miércoles 21 de octubre de 2026. El servicio demo trae 4 sesiones viejas
  // (14 y 7 de octubre, 30 y 23 de septiembre) sin hora registrada.
  final hoy = DateTime(2026, 10, 21);
  late DateTime ahora;
  late EntrenadorDemoService datos;
  late EntrenadorController controller;

  setUp(() async {
    ahora = DateTime(2026, 10, 21, 16, 5);
    datos = EntrenadorDemoService(latencia: Duration.zero, hoy: hoy);
    controller = EntrenadorController(
      datos: datos,
      entrenadorId: EntrenadorDemoService.entrenadorDemoId,
      reloj: () => ahora,
    );
    await controller.iniciar();
  });

  tearDown(() => controller.dispose());

  group('modelo Asistencia', () {
    test('guarda y lee la fecha y hora de cada presente', () {
      final asistencia = Asistencia(
        deporteId: 'fut',
        fecha: DateTime(2026, 10, 21, 18),
        entrenadorId: 'e1',
        presentes: const ['a', 'b'],
        registradaEn: DateTime(2026, 10, 21, 16, 30),
        horasPresentes: {
          'a': DateTime(2026, 10, 21, 16, 5),
          'c': DateTime(2026, 10, 21, 16, 6),
        },
      );
      final json = asistencia.toJson();
      expect(json['fecha'], Timestamp.fromDate(DateTime(2026, 10, 21)));
      expect(
        json['registradaEn'],
        Timestamp.fromDate(DateTime(2026, 10, 21, 16, 30)),
      );
      // Solo se guardan horas de estudiantes presentes.
      expect((json['horasPresentes'] as Map).keys, ['a']);

      final leida = Asistencia.fromJson(json, id: 'x');
      expect(leida.horaDe('a'), DateTime(2026, 10, 21, 16, 5));
      expect(leida.horaDe('b'), isNull);
      expect(leida.horaDe('c'), isNull);
    });

    test('un registro viejo sin horas se sigue leyendo', () {
      final vieja = Asistencia.fromJson({
        'deporteId': 'fut',
        'fecha': Timestamp.fromDate(DateTime(2026, 9, 2)),
        'entrenadorId': 'e1',
        'presentes': ['a'],
      }, id: 'fut_2026-09-02');
      expect(vieja.estaPresente('a'), isTrue);
      expect(vieja.registradaEn, isNull);
      expect(vieja.horaDe('a'), isNull);
    });
  });

  group('controlador', () {
    test('guarda la hora exacta en que se marcó a cada presente', () async {
      controller.marcarTodos(presentes: false);
      controller.marcar('est-01', presente: true);
      ahora = DateTime(2026, 10, 21, 16, 12);
      controller.marcar('est-02', presente: true);
      // Volver a marcar presente no cambia la hora original.
      ahora = DateTime(2026, 10, 21, 16, 40);
      controller.marcar('est-01', presente: true);

      expect(await controller.guardarAsistencia(), isTrue);
      final guardada = (await datos.asistenciaDelDia('FUT-M01', hoy))!;
      expect(guardada.horaDe('est-01'), DateTime(2026, 10, 21, 16, 5));
      expect(guardada.horaDe('est-02'), DateTime(2026, 10, 21, 16, 12));
      expect(guardada.horaDe('est-03'), isNull);
      expect(guardada.registradaEn, DateTime(2026, 10, 21, 16, 40));
    });

    test('al editar una sesión vieja no inventa horas', () async {
      await controller.cambiarFecha(DateTime(2026, 10, 14));
      expect(controller.marcaDe('est-01'), isTrue);

      // Se cambia solo a un estudiante: el resto conserva "sin hora".
      controller.marcar('est-06', presente: true);
      expect(await controller.guardarAsistencia(), isTrue);

      final guardada = (await datos.asistenciaDelDia(
        'FUT-M01',
        DateTime(2026, 10, 14),
      ))!;
      expect(guardada.horaDe('est-01'), isNull);
      expect(guardada.horaDe('est-06'), ahora);
    });

    test('resume la asistencia de un estudiante por mes', () async {
      controller.marcarTodos(presentes: true);
      await controller.guardarAsistencia();

      expect(controller.mesesConSesiones, [
        DateTime(2026, 10),
        DateTime(2026, 9),
      ]);

      final octubre = controller.asistenciaMensualDe(
        'est-06',
        DateTime(2026, 10),
      );
      expect(octubre.registros.map((r) => r.fecha.day), [7, 14, 21]);
      expect(octubre.registros.last.hora, DateTime(2026, 10, 21, 16, 5));
      expect(octubre.registros.first.hora, isNull);

      final septiembre = controller.asistenciaMensualDe(
        'est-01',
        DateTime(2026, 9),
      );
      expect(septiembre.sesiones, 2);
      expect(septiembre.porcentaje, 1.0);
      expect(
        controller.asistenciaMensualDe('est-01', DateTime(2026, 8)).porcentaje,
        isNull,
      );
    });
  });

  group('pantalla de detalle', () {
    Future<void> abrir(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: SamanColors.tema(),
          home: Scaffold(body: NominaView(controller: controller)),
        ),
      );
      await tester.pump();
    }

    testWidgets('tocar un estudiante muestra su historial con horas', (
      tester,
    ) async {
      controller.marcarTodos(presentes: true);
      controller.marcar('est-06', presente: false);
      await tester.runAsync(controller.guardarAsistencia);
      await abrir(tester);

      await tester.tap(find.byKey(const Key('nomina-est-01')));
      await tester.pumpAndSettle();

      expect(find.byType(DetalleAsistenciaEstudianteView), findsOneWidget);
      expect(find.text('Octubre 2026'), findsOneWidget);
      expect(find.text('Registrada a las 4:05 pm'), findsOneWidget);
      // Las sesiones del 7 y 14 de octubre son viejas.
      expect(find.text('Hora no registrada'), findsNWidgets(2));
      expect(
        tester.widget<Text>(find.byKey(const Key('resumen-mes'))).data,
        'Asistió a 3 de 3 sesiones · 0 faltas',
      );

      await tester.tap(find.byKey(const Key('mes-anterior')));
      await tester.pump();
      expect(find.text('Septiembre 2026'), findsOneWidget);
      expect(find.byKey(const Key('registro-2026-09-30')), findsOneWidget);
      // No hay meses más antiguos con sesiones.
      final anterior = tester.widget<IconButton>(
        find.byKey(const Key('mes-anterior')),
      );
      expect(anterior.onPressed, isNull);
    });

    testWidgets('un ausente se ve como "No asistió"', (tester) async {
      controller.marcarTodos(presentes: true);
      controller.marcar('est-06', presente: false);
      await tester.runAsync(controller.guardarAsistencia);
      await abrir(tester);

      await tester.tap(find.byKey(const Key('nomina-est-06')));
      await tester.pumpAndSettle();

      final hoyFila = find.byKey(const Key('registro-2026-10-21'));
      expect(
        find.descendant(of: hoyFila, matching: find.text('No asistió')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: hoyFila, matching: find.text('Ausente')),
        findsOneWidget,
      );
    });
  });
}
