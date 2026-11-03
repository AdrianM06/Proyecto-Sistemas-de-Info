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
    expect(find.byKey(const Key('landing-boton-login')), findsOneWidget);
    expect(find.byKey(const Key('landing-boton-acceder')), findsOneWidget);
    expect(find.text('Misión'), findsOneWidget);
    expect(find.text('Visión'), findsOneWidget);
    expect(find.text('INICIAR SESIÓN'), findsNothing);
  });

  testWidgets('el botón Acceder de la barra lleva al login', (tester) async {
    await abrirApp(tester);

    await tester.tap(find.byKey(const Key('landing-boton-acceder')));
    await tester.pumpAndSettle();

    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
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

  testWidgets('iniciar sesión sin datos marca los campos obligatorios', (
    tester,
  ) async {
    await abrirApp(tester);
    await irAlLogin(tester);

    await tester.tap(find.byKey(const Key('boton-iniciar-sesion')));
    await tester.pumpAndSettle();

    expect(find.text('Escribe tu correo o tu carnet'), findsOneWidget);
    expect(find.text('Escribe tu contraseña'), findsOneWidget);
  });

  testWidgets('el login no acepta correos de otro dominio ni carnets cortos', (
    tester,
  ) async {
    await abrirApp(tester);
    await irAlLogin(tester);

    await tester.enterText(
      find.byKey(const Key('login-identificador')),
      'ana@gmail.com',
    );
    await tester.enterText(find.byKey(const Key('login-clave')), 'Clave1234');
    await tester.tap(find.byKey(const Key('boton-iniciar-sesion')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Debe ser un correo institucional (@unimet.edu.ve o @correo.unimet.edu.ve)',
      ),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('login-identificador')),
      '2022111',
    );
    await tester.tap(find.byKey(const Key('boton-iniciar-sesion')));
    await tester.pumpAndSettle();
    expect(find.text('El carnet debe tener 11 dígitos'), findsOneWidget);
  });

  testWidgets('el login tiene la opción de iniciar sesión como administrador', (
    tester,
  ) async {
    await abrirApp(tester);
    await irAlLogin(tester);

    expect(find.text('Iniciar sesión como Administrador'), findsOneWidget);
    await tester.tap(find.byKey(const Key('boton-modo-admin')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('aviso-modo-admin')), findsOneWidget);
    expect(find.text('Acceso de administrador'), findsOneWidget);
    expect(find.text('Entrar al panel'), findsOneWidget);
    // En modo administrador no se ofrece crear cuenta.
    expect(find.byKey(const Key('boton-crear-cuenta')), findsNothing);

    await tester.tap(find.byKey(const Key('boton-modo-admin')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aviso-modo-admin')), findsNothing);
    expect(find.byKey(const Key('boton-crear-cuenta')), findsOneWidget);
  });

  testWidgets('el ojo del login muestra y oculta la contraseña', (tester) async {
    await abrirApp(tester);
    await irAlLogin(tester);

    TextField campoClave() => tester.widget<TextField>(
          find.descendant(
            of: find.byKey(const Key('login-clave')),
            matching: find.byType(TextField),
          ),
        );

    expect(campoClave().obscureText, isTrue);
    await tester.tap(find.byKey(const Key('login-ver-clave')));
    await tester.pump();
    expect(campoClave().obscureText, isFalse);
  });

  testWidgets('desde el login se vuelve a la Landing Page', (tester) async {
    await abrirApp(tester);
    await irAlLogin(tester);

    await tester.tap(find.byKey(const Key('boton-volver-inicio')));
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido a Samán Deportivo'), findsOneWidget);
    expect(find.text('INICIAR SESIÓN'), findsNothing);
  });

  testWidgets('desde el registro se vuelve a la Landing Page', (tester) async {
    await abrirApp(tester);
    await irAlLogin(tester);
    await tester.tap(find.byKey(const Key('boton-crear-cuenta')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('boton-volver-inicio')));
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido a Samán Deportivo'), findsOneWidget);
    expect(find.text('REGISTRACIÓN'), findsNothing);
  });

  testWidgets('la Landing muestra los módulos principales con enlaces', (
    tester,
  ) async {
    await abrirApp(tester);

    expect(find.text('Nuestros módulos principales'), findsOneWidget);
    for (final clave in [
      'catalogo',
      'inscripciones',
      'perfil',
      'asistencia',
      'admin',
      'registro',
    ]) {
      expect(find.byKey(Key('modulo-$clave')), findsOneWidget);
    }

    // Sin sesión, un módulo privado lleva al inicio de sesión.
    await tester.ensureVisible(find.byKey(const Key('modulo-inscripciones')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('modulo-inscripciones')));
    await tester.pumpAndSettle();
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    expect(find.text('Inicia sesión para entrar a Inscripciones.'), findsOneWidget);

    // Deja que el aviso termine antes de cerrar la prueba.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('el módulo "Crea tu cuenta" abre el registro', (tester) async {
    await abrirApp(tester);

    await tester.ensureVisible(find.byKey(const Key('modulo-registro')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('modulo-registro')));
    await tester.pumpAndSettle();

    expect(find.text('REGISTRACIÓN'), findsOneWidget);
  });

  testWidgets('en el teléfono la barra de la Landing usa el menú hamburguesa', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const UnimetSportsApp());
    await tester.pumpAndSettle();

    // Los botones de la barra no quedan sueltos: van dentro del menú.
    expect(find.byKey(const Key('landing-boton-acceder')), findsNothing);
    expect(find.byKey(const Key('landing-boton-menu')), findsOneWidget);

    await tester.tap(find.byKey(const Key('landing-boton-menu')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('landing-menu')), findsOneWidget);
    expect(find.text('Misión y Visión'), findsOneWidget);

    await tester.tap(find.byKey(const Key('landing-menu-acceder')));
    await tester.pumpAndSettle();
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
  });

  testWidgets('crear cuenta abre el registro solo de estudiantes', (
    tester,
  ) async {
    await abrirApp(tester);
    await irAlLogin(tester);

    await tester.tap(find.byKey(const Key('boton-crear-cuenta')));
    await tester.pumpAndSettle();

    expect(find.text('REGISTRACIÓN'), findsOneWidget);
    expect(find.byKey(const Key('boton-registrar')), findsOneWidget);
    expect(find.byKey(const Key('registro-nota-entrenadores')), findsOneWidget);
    expect(find.byKey(const Key('registro-rol-entrenador')), findsNothing);
    for (final campo in [
      'registro-nombre',
      'registro-apellido',
      'registro-correo',
      'registro-cedula',
      'registro-carnet',
      'registro-clave',
      'registro-confirmar-clave',
    ]) {
      expect(find.byKey(Key(campo)), findsOneWidget);
    }
  });

  testWidgets('un entrenador no puede crear su cuenta desde el login', (
    tester,
  ) async {
    await abrirApp(tester);
    await irAlLogin(tester);

    await tester.tap(find.text('Entrenador'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('boton-crear-cuenta')));
    await tester.pump();

    expect(find.text('REGISTRACIÓN'), findsNothing);
    expect(
      find.textContaining('Las cuentas de entrenador las crea el administrador'),
      findsOneWidget,
    );

    // Deja que el aviso termine antes de cerrar la prueba.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
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
