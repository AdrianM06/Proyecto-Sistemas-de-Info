import 'package:flutter/material.dart';
import 'package:flutter_app/controllers/perfil_estudiante_controller.dart';
import 'package:flutter_app/services/perfil_estudiante_service.dart';
import 'package:flutter_app/views/estudiante/perfil_estudiante_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PerfilEstudianteDemoService datos;
  var sesionCerrada = false;

  Future<void> abrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    datos = PerfilEstudianteDemoService(latencia: Duration.zero);
    sesionCerrada = false;
    await tester.pumpWidget(
      MaterialApp(
        home: PerfilEstudianteView(
          controller: PerfilEstudianteController(datos: datos),
          onCerrarSesion: () => sesionCerrada = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> llenarClave(
    WidgetTester tester, {
    required String actual,
    required String nueva,
  }) async {
    await tester.tap(find.byKey(const Key('boton-cambiar-clave')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('clave-actual')), actual);
    await tester.enterText(find.byKey(const Key('clave-nueva')), nueva);
    await tester.enterText(find.byKey(const Key('clave-confirmar')), nueva);
    await tester.tap(find.byKey(const Key('guardar-clave')));
    await tester.pumpAndSettle();
  }

  testWidgets('muestra el menú lateral y las tres tarjetas', (tester) async {
    await abrir(tester);

    expect(find.byKey(const Key('menu-Inicio')), findsOneWidget);
    expect(find.byKey(const Key('menu-Catálogo')), findsOneWidget);
    expect(find.byKey(const Key('menu-Pagos')), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Saldo en cuenta'), findsOneWidget);
    expect(find.text('Retirar disciplina'), findsOneWidget);
    expect(find.text('Bs. 00,00'), findsOneWidget);
    expect(find.text('Andrea Pérez'), findsOneWidget);
    expect(find.byKey(const Key('boton-cambiar-clave')), findsOneWidget);
  });

  testWidgets('cambiar clave muestra el mensaje de éxito', (tester) async {
    await abrir(tester);

    await llenarClave(
      tester,
      actual: PerfilEstudianteDemoService.contrasenaDemo,
      nueva: 'NuevaClave1',
    );

    expect(find.byKey(const Key('dialogo-cambiar-clave')), findsNothing);
    expect(find.byKey(const Key('mensaje-clave-cambiada')), findsOneWidget);
    expect(datos.contrasenaActual, 'NuevaClave1');

    // Deja que el aviso termine antes de cerrar la prueba.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('con la clave actual equivocada el formulario muestra el error', (
    tester,
  ) async {
    await abrir(tester);

    await llenarClave(tester, actual: 'Equivocada1', nueva: 'NuevaClave1');

    expect(find.byKey(const Key('dialogo-cambiar-clave')), findsOneWidget);
    expect(find.text('La contraseña actual no es correcta.'), findsOneWidget);
    expect(datos.contrasenaActual, PerfilEstudianteDemoService.contrasenaDemo);
  });

  testWidgets('el botón de salir llama a cerrar sesión', (tester) async {
    await abrir(tester);

    await tester.tap(find.byKey(const Key('boton-cerrar-sesion')));
    await tester.pump();

    expect(sesionCerrada, isTrue);
  });
}
