import 'package:flutter/material.dart';
import 'package:flutter_app/controllers/entrenador_controller.dart';
import 'package:flutter_app/services/entrenador_demo_service.dart';
import 'package:flutter_app/views/entrenador/entrenador_home_screen.dart';
import 'package:flutter_app/views/theme/saman_colors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app() {
    return MaterialApp(
      theme: SamanColors.tema(),
      home: EntrenadorHomeScreen(
        controller: EntrenadorController(
          datos: EntrenadorDemoService(latencia: Duration.zero),
          entrenadorId: EntrenadorDemoService.entrenadorDemoId,
        ),
        nombreEntrenador: 'Carlos Gutiérrez',
      ),
    );
  }

  testWidgets('el panel muestra la disciplina y sus indicadores', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Hola, Carlos Gutiérrez'), findsOneWidget);
    expect(find.text('Fútbol Masculino'), findsWidgets);
    expect(find.text('Inscritos'), findsOneWidget);
    expect(find.byKey(const Key('boton-tomar-asistencia')), findsOneWidget);
  });

  testWidgets('la pestaña Nómina lista a los estudiantes', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nómina').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('buscador-nomina')), findsOneWidget);
    expect(find.text('Andrea Pérez'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('buscador-nomina')), 'rojas');
    await tester.pumpAndSettle();

    expect(find.text('Valentina Rojas'), findsOneWidget);
    expect(find.text('Andrea Pérez'), findsNothing);
  });

  testWidgets('tomar asistencia marca y guarda', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('boton-tomar-asistencia')));
    await tester.pumpAndSettle();

    expect(find.text('Tomar asistencia'), findsOneWidget);

    await tester.tap(find.text('Marcar todos presentes'));
    await tester.pumpAndSettle();
    expect(find.text('Guardar asistencia (8/8)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('guardar-asistencia')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Asistencia guardada'), findsOneWidget);

    // Deja que el aviso (SnackBar) termine antes de cerrar la prueba.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
