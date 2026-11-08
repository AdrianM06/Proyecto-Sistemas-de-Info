import 'package:flutter/material.dart';
import 'package:flutter_app/controllers/buscador_controller.dart';
import 'package:flutter_app/models/deporte.dart';
import 'package:flutter_app/services/buscador_demo_service.dart';
import 'package:flutter_app/services/inscripcion_service.dart';
import 'package:flutter_app/views/buscador/buscador_screen.dart';
import 'package:flutter_app/views/theme/saman_colors.dart';
import 'package:flutter_test/flutter_test.dart';

class _Inscripciones implements InscripcionesDataSource {
  _Inscripciones({Set<String> iniciales = const {}, this.fallo})
    : _inscrito = {...iniciales};

  final Set<String> _inscrito;
  final String? fallo;
  int llamadas = 0;

  @override
  Future<Set<String>> deportesInscritos(String estudianteId) async => {
    ..._inscrito,
  };

  @override
  Future<void> inscribir({
    required String estudianteId,
    required Deporte deporte,
  }) async {
    llamadas++;
    if (fallo != null) throw InscripcionException(fallo!);
    _inscrito.add(deporte.id);
  }

  @override
  Future<void> cancelar({
    required String estudianteId,
    required String deporteId,
  }) async {
    if (fallo != null) throw InscripcionException(fallo!);
    _inscrito.remove(deporteId);
  }
}

void main() {
  late _Inscripciones inscripciones;

  BuscadorController controlador() => BuscadorController(
    datos: BuscadorDemoService(latencia: Duration.zero),
    inscripciones: inscripciones,
    estudianteId: 'est-01',
  );

  Future<void> abrirDetalle(WidgetTester tester, String deporteId) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: SamanColors.tema(),
        home: BuscadorScreen(controller: controlador()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('tarjeta-$deporteId')));
    await tester.pumpAndSettle();
  }

  String? textoDelBoton(WidgetTester tester) {
    final texto = find.descendant(
      of: find.byKey(const Key('boton-inscribirme')),
      matching: find.byType(Text),
    );
    return tester.widget<Text>(texto).data;
  }

  group('controlador', () {
    test(
      'inscribirse marca el deporte como inscrito y suma un cupo usado',
      () async {
        inscripciones = _Inscripciones();
        final c = controlador();
        await c.iniciar();
        final futbol = c.todos.firstWhere((d) => d.id == 'FUT-M01');
        final antes = c.inscritosDe(futbol);

        expect(c.permiteInscribir, isTrue);
        expect(c.estaInscrito(futbol), isFalse);
        expect(await c.inscribirse(futbol), isNull);

        expect(c.estaInscrito(futbol), isTrue);
        expect(c.inscritosDe(futbol), antes + 1);
        expect(inscripciones.llamadas, 1);
        c.dispose();
      },
    );

    test('no inscribe dos veces en el mismo deporte', () async {
      inscripciones = _Inscripciones(iniciales: {'FUT-M01'});
      final c = controlador();
      await c.iniciar();
      final futbol = c.todos.firstWhere((d) => d.id == 'FUT-M01');

      expect(c.estaInscrito(futbol), isTrue);
      expect(await c.inscribirse(futbol), contains('Ya estás inscrito'));
      expect(inscripciones.llamadas, 0);
      c.dispose();
    });

    test('devuelve el error del servicio y no marca la inscripción', () async {
      inscripciones = _Inscripciones(fallo: 'Sin cupos.');
      final c = controlador();
      await c.iniciar();
      final futbol = c.todos.firstWhere((d) => d.id == 'FUT-M01');

      expect(await c.inscribirse(futbol), 'Sin cupos.');
      expect(c.estaInscrito(futbol), isFalse);
      expect(c.inscribiendo, isNull);
      c.dispose();
    });

    test('sin servicio de inscripción el buscador solo consulta', () async {
      final c = BuscadorController(
        datos: BuscadorDemoService(latencia: Duration.zero),
      );
      await c.iniciar();

      expect(c.permiteInscribir, isFalse);
      expect(await c.inscribirse(c.todos.first), isNotNull);
      c.dispose();
    });
  });

  group('pantalla', () {
    testWidgets('al inscribirse el botón pasa a "Inscrito" y se deshabilita', (
      tester,
    ) async {
      inscripciones = _Inscripciones();
      await abrirDetalle(tester, 'AJE-01');

      expect(textoDelBoton(tester), 'Inscribirme');

      await tester.tap(find.byKey(const Key('boton-inscribirme')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dialogo-inscripcion')), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirmar-inscripcion')));
      await tester.pumpAndSettle();

      expect(inscripciones.llamadas, 1);
      expect(textoDelBoton(tester), 'Inscrito');
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('boton-inscribirme')))
            .onPressed,
        isNull,
      );
      expect(find.byKey(const Key('aviso-inscripcion')), findsOneWidget);
    });

    testWidgets('cancelar la confirmación no inscribe', (tester) async {
      inscripciones = _Inscripciones();
      await abrirDetalle(tester, 'AJE-01');

      await tester.tap(find.byKey(const Key('boton-inscribirme')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(inscripciones.llamadas, 0);
      expect(textoDelBoton(tester), 'Inscribirme');
    });

    testWidgets('un deporte donde ya está inscrito abre con "Inscrito"', (
      tester,
    ) async {
      inscripciones = _Inscripciones(iniciales: {'AJE-01'});
      await abrirDetalle(tester, 'AJE-01');

      expect(textoDelBoton(tester), 'Inscrito');
    });

    testWidgets('si falla la inscripción muestra el motivo y deja el botón', (
      tester,
    ) async {
      inscripciones = _Inscripciones(fallo: 'Ese deporte ya no tiene cupos.');
      await abrirDetalle(tester, 'AJE-01');

      await tester.tap(find.byKey(const Key('boton-inscribirme')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmar-inscripcion')));
      await tester.pumpAndSettle();

      expect(find.text('Ese deporte ya no tiene cupos.'), findsOneWidget);
      expect(textoDelBoton(tester), 'Inscribirme');
    });
  });
}
