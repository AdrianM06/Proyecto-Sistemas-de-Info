import 'package:flutter/material.dart';
import 'package:flutter_app/controllers/buscador_controller.dart';
import 'package:flutter_app/services/buscador_demo_service.dart';
import 'package:flutter_app/views/buscador/buscador_screen.dart';
import 'package:flutter_app/views/theme/saman_colors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app() {
    return MaterialApp(
      theme: SamanColors.tema(),
      home: BuscadorScreen(
        controller: BuscadorController(
          datos: BuscadorDemoService(latencia: Duration.zero),
        ),
        onSeleccionar: (_) {},
      ),
    );
  }

  Future<void> abrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
  }

  String? contador(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('contador-resultados'))).data;

  testWidgets('muestra la oferta deportiva', (tester) async {
    await abrir(tester);

    expect(contador(tester), '8 deportes');
    expect(find.byKey(const Key('tarjeta-AJE-01')), findsOneWidget);
    expect(find.byKey(const Key('buscador-deportes')), findsOneWidget);
  });

  testWidgets('el buscador filtra por nombre sin acentos', (tester) async {
    await abrir(tester);

    await tester.enterText(find.byKey(const Key('buscador-deportes')), 'futbol');
    await tester.pumpAndSettle();

    expect(contador(tester), '2 deportes');
    expect(find.byKey(const Key('tarjeta-FUT-M01')), findsOneWidget);
    expect(find.byKey(const Key('tarjeta-AJE-01')), findsNothing);
  });

  testWidgets('solo con cupos quita los deportes llenos', (tester) async {
    await abrir(tester);

    await tester.tap(find.byKey(const Key('filtro-cupos')));
    await tester.pumpAndSettle();

    expect(contador(tester), '7 deportes');
  });

  testWidgets('sin resultados se pueden limpiar los filtros', (tester) async {
    await abrir(tester);

    await tester.enterText(find.byKey(const Key('buscador-deportes')), 'xyz');
    await tester.pumpAndSettle();

    expect(find.text('No encontramos deportes'), findsOneWidget);

    await tester.tap(find.byKey(const Key('limpiar-filtros')));
    await tester.pumpAndSettle();

    expect(contador(tester), '8 deportes');
  });

  testWidgets('al tocar un deporte se abre su detalle', (tester) async {
    await abrir(tester);

    await tester.tap(find.byKey(const Key('tarjeta-AJE-01')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('detalle-deporte')), findsOneWidget);
    expect(find.byKey(const Key('boton-inscribirme')), findsOneWidget);
  });
}
