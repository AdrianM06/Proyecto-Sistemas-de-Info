import 'package:flutter/material.dart';
import 'package:flutter_app/models/resumen_admin.dart';
import 'package:flutter_app/services/resumen_admin_service.dart';
import 'package:flutter_app/views/admin/panel_resumen_admin.dart';
import 'package:flutter_test/flutter_test.dart';

class _Datos implements ResumenAdminDataSource {
  _Datos(this.respuestas);

  /// Cada llamada a [cargar] usa la siguiente respuesta; `null` = error.
  final List<ResumenAdmin?> respuestas;
  int llamadas = 0;

  @override
  Future<ResumenAdmin> cargar() async {
    final respuesta =
        respuestas[llamadas < respuestas.length ? llamadas : respuestas.length - 1];
    llamadas++;
    if (respuesta == null) throw Exception('sin conexión');
    return respuesta;
  }
}

const _resumen = ResumenAdmin(
  estudiantes: 120,
  estudiantesDeshabilitados: 5,
  entrenadores: 8,
  disciplinas: 10,
  disciplinasSinEntrenador: 2,
  inscripcionesActivas: 90,
  cuposTotales: 200,
);

void main() {
  Future<void> abrir(WidgetTester tester, _Datos datos, {double ancho = 1200}) async {
    tester.view.physicalSize = Size(ancho, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: PanelResumenAdmin(datos: datos),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String valorDe(WidgetTester tester, String clave) {
    final texto = tester.widget<Text>(
      find.descendant(
        of: find.byKey(Key(clave)),
        matching: find.byKey(const Key('resumen-valor')),
      ),
    );
    return texto.data!;
  }

  testWidgets('muestra las cuatro cifras del resumen', (tester) async {
    await abrir(tester, _Datos([_resumen]));

    expect(valorDe(tester, 'resumen-estudiantes'), '120');
    expect(valorDe(tester, 'resumen-entrenadores'), '8');
    expect(valorDe(tester, 'resumen-disciplinas'), '10');
    expect(valorDe(tester, 'resumen-inscripciones'), '90');

    expect(find.text('115 activos · 5 deshabilitados'), findsOneWidget);
    expect(find.text('2 disciplinas sin entrenador'), findsOneWidget);
    expect(find.text('Ocupación: 45 % de 200 cupos'), findsOneWidget);
    expect(find.byKey(const Key('resumen-hora')), findsOneWidget);
  });

  testWidgets('las cuatro tarjetas van en una fila en pantallas anchas', (
    tester,
  ) async {
    await abrir(tester, _Datos([_resumen]));

    final estudiantes = tester.getRect(find.byKey(const Key('resumen-estudiantes')));
    final inscripciones = tester.getRect(
      find.byKey(const Key('resumen-inscripciones')),
    );
    expect(inscripciones.top, estudiantes.top);
  });

  testWidgets('en el teléfono las tarjetas se apilan sin desbordes', (
    tester,
  ) async {
    await abrir(tester, _Datos([_resumen]), ancho: 380);

    final estudiantes = tester.getRect(find.byKey(const Key('resumen-estudiantes')));
    final entrenadores = tester.getRect(find.byKey(const Key('resumen-entrenadores')));
    expect(entrenadores.top, greaterThan(estudiantes.bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('si falla muestra Reintentar y vuelve a cargar', (tester) async {
    final datos = _Datos([null, _resumen]);
    await abrir(tester, datos);

    expect(find.byKey(const Key('resumen-error')), findsOneWidget);
    await tester.tap(find.byKey(const Key('resumen-reintentar')));
    await tester.pumpAndSettle();

    expect(datos.llamadas, 2);
    expect(find.byKey(const Key('resumen-error')), findsNothing);
    expect(valorDe(tester, 'resumen-estudiantes'), '120');
  });

  testWidgets('el botón actualizar vuelve a pedir las cifras', (tester) async {
    final datos = _Datos([_resumen]);
    await abrir(tester, datos);

    await tester.tap(find.byKey(const Key('resumen-actualizar')));
    await tester.pumpAndSettle();
    expect(datos.llamadas, 2);
  });

  test('ocupación y activos del modelo', () {
    expect(_resumen.estudiantesActivos, 115);
    expect(_resumen.ocupacion, closeTo(0.45, 0.0001));
    const sinCupos = ResumenAdmin(
      estudiantes: 0,
      estudiantesDeshabilitados: 0,
      entrenadores: 0,
      disciplinas: 0,
      disciplinasSinEntrenador: 0,
      inscripcionesActivas: 0,
      cuposTotales: 0,
    );
    expect(sinCupos.ocupacion, isNull);
    expect(sinCupos.ocupacionTexto, 'Sin cupos definidos');
  });
}
