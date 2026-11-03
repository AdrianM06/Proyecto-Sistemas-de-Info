import 'package:flutter/material.dart';
import 'package:flutter_app/controllers/perfil_estudiante_controller.dart';
import 'package:flutter_app/services/perfil_estudiante_service.dart';
import 'package:flutter_app/views/estudiante/perfil_estudiante_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PerfilEstudianteDemoService datos;
  var sesionCerrada = false;

  Future<void> abrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1600);
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

  testWidgets('el menú hamburguesa abre el menú lateral', (tester) async {
    await abrir(tester);

    // El menú está cerrado: los botones no quedan expuestos en la página.
    expect(find.byKey(const Key('menu-Inicio')), findsNothing);

    await tester.tap(find.byKey(const Key('boton-menu')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('menu-Inicio')), findsOneWidget);
    expect(find.byKey(const Key('menu-Catálogo')), findsOneWidget);
    expect(find.byKey(const Key('menu-Pagos')), findsOneWidget);
    expect(find.byKey(const Key('menu-Mi perfil')), findsOneWidget);
    expect(find.byKey(const Key('menu-Página principal')), findsOneWidget);
    expect(find.byKey(const Key('menu-Cerrar sesión')), findsOneWidget);
  });

  testWidgets('muestra las tres tarjetas del perfil', (tester) async {
    await abrir(tester);

    expect(find.text('Perfil'), findsOneWidget);
    expect(find.byKey(const Key('perfil-nombre')), findsOneWidget);
    expect(find.text('Andrea Pérez'), findsOneWidget);
    expect(find.text('20221110342'), findsOneWidget);
    expect(find.text('V-27123456'), findsOneWidget);
    expect(find.byKey(const Key('boton-cambiar-foto')), findsOneWidget);
    expect(find.byKey(const Key('boton-editar-datos')), findsOneWidget);
    expect(find.text('Cambia la contraseña de usuario'), findsOneWidget);
    expect(find.text('Saldo en cuenta'), findsOneWidget);
    expect(find.text('Saldo adeudado'), findsOneWidget);
    expect(find.text('Bs. 00,00'), findsOneWidget);
    // Título de la tarjeta y texto del botón.
    expect(find.text('Retirar disciplina'), findsNWidgets(2));
    expect(
      find.text('Cancela la inscripción a una disciplina deportiva'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('boton-cambiar-clave')), findsOneWidget);
    expect(find.byKey(const Key('boton-retirar-disciplina')), findsOneWidget);
  });

  testWidgets('retirar disciplina pide elegirla y confirmar', (tester) async {
    await abrir(tester);

    await tester.tap(find.byKey(const Key('boton-retirar-disciplina')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dialogo-retirar')), findsOneWidget);

    await tester.tap(find.byKey(const Key('opcion-insc-02')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmar-retiro')));
    await tester.pumpAndSettle();

    expect(find.text('Te retiraste de Natación.'), findsOneWidget);

    // Deja que el aviso termine antes de cerrar la prueba.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
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

  testWidgets('editar datos: nombre y apellido editables, carnet y cédula bloqueados', (
    tester,
  ) async {
    await abrir(tester);

    await tester.tap(find.byKey(const Key('boton-editar-datos')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dialogo-editar-datos')), findsOneWidget);

    final carnet = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('editar-carnet')),
        matching: find.byType(TextField),
      ),
    );
    final cedula = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('editar-cedula')),
        matching: find.byType(TextField),
      ),
    );
    expect(carnet.readOnly, isTrue);
    expect(carnet.enabled, isFalse);
    expect(cedula.readOnly, isTrue);
    expect(cedula.enabled, isFalse);

    await tester.enterText(find.byKey(const Key('editar-nombre')), 'María');
    await tester.enterText(find.byKey(const Key('editar-apellido')), 'Gómez');
    await tester.tap(find.byKey(const Key('guardar-datos')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dialogo-editar-datos')), findsNothing);
    expect(find.text('María Gómez'), findsOneWidget);
    expect(datos.usuario.nombre, 'María');
    expect(datos.usuario.carnet, '20221110342');
    expect(datos.usuario.cedula, 'V-27123456');

    // Deja que el aviso termine antes de cerrar la prueba.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('editar datos no guarda un nombre inválido', (tester) async {
    await abrir(tester);

    await tester.tap(find.byKey(const Key('boton-editar-datos')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('editar-nombre')), 'A1');
    await tester.tap(find.byKey(const Key('guardar-datos')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dialogo-editar-datos')), findsOneWidget);
    expect(find.text('El nombre solo puede tener letras'), findsOneWidget);
    expect(datos.usuario.nombre, 'Andrea');
  });
}
