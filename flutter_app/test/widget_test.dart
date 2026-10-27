import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/main.dart';

void main() {
  Future<void> abrirApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const UnimetSportsApp());
    await tester.pumpAndSettle();
  }

  Future<void> irAlLogin(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('landing-boton-login')));
    await tester.pumpAndSettle();
  }

  testWidgets('la app abre en la Landing Page', (tester) async {
    await abrirApp(tester);

    expect(find.text('Bienvenido a Samán Deportivo'), findsOneWidget);
    expect(find.text('UNIMET'), findsOneWidget);
    expect(find.byKey(const Key('landing-boton-login')), findsOneWidget);
    expect(find.text('INICIAR SESIÓN'), findsNothing);
  });

  testWidgets('el botón principal de la Landing lleva al login', (tester) async {
    await abrirApp(tester);
    await irAlLogin(tester);

    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    expect(find.text('Correo/Carnet Universitario'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Estudiante'), findsOneWidget);
    expect(find.text('Entrenador'), findsOneWidget);
    expect(find.byKey(const Key('boton-iniciar-sesion')), findsOneWidget);
    expect(find.byKey(const Key('boton-crear-cuenta')), findsOneWidget);
  });

  testWidgets('iniciar sesión sin datos muestra un aviso', (tester) async {
    await abrirApp(tester);
    await irAlLogin(tester);

    await tester.tap(find.byKey(const Key('boton-iniciar-sesion')));
    await tester.pump();

    expect(find.text('Por favor, complete todos los campos.'), findsOneWidget);

    // Deja que el aviso termine antes de cerrar la prueba.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('crear cuenta abre el registro con el rol elegido', (tester) async {
    await abrirApp(tester);
    await irAlLogin(tester);

    await tester.tap(find.text('Entrenador'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('boton-crear-cuenta')));
    await tester.pumpAndSettle();

    expect(find.text('REGISTRACIÓN'), findsOneWidget);
    expect(find.byKey(const Key('registro-rol-entrenador')), findsOneWidget);
    expect(find.byKey(const Key('registro-rol-estudiante')), findsOneWidget);
    expect(find.byKey(const Key('boton-registrar')), findsOneWidget);
  });

  testWidgets('abre la recuperación y valida el correo y el carnet', (
    tester,
  ) async {
    await abrirApp(tester);
    await irAlLogin(tester);

    await tester.tap(find.text('aquí').at(1));
    await tester.pumpAndSettle();

    expect(find.text('RECUPERAR CONTRASEÑA'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));

    await tester.enterText(find.byType(TextFormField).at(0), 'not-an-email');
    await tester.enterText(find.byType(TextFormField).at(1), 'abc');
    await tester.tap(find.text('Mandar Código'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Debe ser un correo institucional (@unimet.edu.ve o @correo.unimet.edu.ve)',
      ),
      findsOneWidget,
    );
    expect(find.text('El carnet solo debe contener números'), findsOneWidget);
  });
}
