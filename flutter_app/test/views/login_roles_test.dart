import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/navigation/app_routes.dart';
import 'package:flutter_app/services/auth_service.dart';
import 'package:flutter_app/views/login_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// Datos que recibió el inicio de sesión de prueba.
class _Intento {
  _Intento(this.identificador, this.password, this.rolEsperado);

  final String identificador;
  final String password;
  final String? rolEsperado;
}

/// Pruebas del manejo de credenciales y roles del login (Tarea 2).
void main() {
  late List<_Intento> intentos;

  Future<SesionUsuario> iniciarSesionFalso({
    required String identificador,
    required String password,
    String? rolEsperado,
  }) async {
    intentos.add(_Intento(identificador, password, rolEsperado));
    // Siempre falla: así la prueba se queda en el login y no abre las vistas
    // que necesitan Firebase.
    throw FirebaseAuthException(code: 'wrong-password');
  }

  Future<void> abrirLogin(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    intentos = [];
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(iniciarSesion: iniciarSesionFalso),
        onGenerateRoute: AppRoutes.generarRuta,
      ),
    );
    await tester.pumpAndSettle();
  }

  String textoDe(WidgetTester tester, String clave) {
    final campo = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(Key(clave)),
        matching: find.byType(TextField),
      ),
    );
    return campo.controller!.text;
  }

  String textoBoton(WidgetTester tester) => tester
      .widget<Text>(find.byKey(const Key('texto-boton-iniciar-sesion')))
      .data!;

  Future<void> escribirCredenciales(
    WidgetTester tester,
    String identificador,
    String clave,
  ) async {
    await tester.enterText(
      find.byKey(const Key('login-identificador')),
      identificador,
    );
    await tester.enterText(find.byKey(const Key('login-clave')), clave);
    await tester.pump();
  }

  Future<void> esperarAviso(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  testWidgets('se envía el rol que está elegido al tocar el botón', (
    tester,
  ) async {
    await abrirLogin(tester);

    // Escribe datos con "Estudiante", cambia a "Entrenador" y escribe otros.
    await escribirCredenciales(tester, 'ana@correo.unimet.edu.ve', 'Clave1234');
    await tester.tap(find.text('Entrenador'));
    await tester.pumpAndSettle();
    await escribirCredenciales(tester, 'luis@unimet.edu.ve', 'Entrena99');

    await tester.tap(find.byKey(const Key('boton-iniciar-sesion')));
    await tester.pumpAndSettle();

    expect(intentos, hasLength(1));
    expect(intentos.single.rolEsperado, RolesUsuario.entrenador);
    expect(intentos.single.identificador, 'luis@unimet.edu.ve');
    expect(intentos.single.password, 'Entrena99');
    await esperarAviso(tester);
  });

  testWidgets('cambiar de rol vacía el formulario', (tester) async {
    await abrirLogin(tester);
    await escribirCredenciales(tester, 'ana@correo.unimet.edu.ve', 'Clave1234');

    await tester.tap(find.text('Entrenador'));
    await tester.pumpAndSettle();
    expect(textoDe(tester, 'login-identificador'), isEmpty);
    expect(textoDe(tester, 'login-clave'), isEmpty);
    expect(textoBoton(tester), 'Iniciar sesión como Entrenador');

    // También al pasar al acceso de administrador.
    await escribirCredenciales(tester, 'luis@unimet.edu.ve', 'Entrena99');
    await tester.tap(find.byKey(const Key('boton-modo-admin')));
    await tester.pumpAndSettle();
    expect(textoDe(tester, 'login-identificador'), isEmpty);
    expect(textoDe(tester, 'login-clave'), isEmpty);
  });

  testWidgets('los campos se pueden editar después de cambiar de rol', (
    tester,
  ) async {
    await abrirLogin(tester);
    await tester.tap(find.text('Entrenador'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('boton-modo-admin')));
    await tester.pumpAndSettle();

    await escribirCredenciales(tester, 'admin@unimet.edu.ve', 'Admin1234');
    expect(textoDe(tester, 'login-identificador'), 'admin@unimet.edu.ve');
    expect(textoDe(tester, 'login-clave'), 'Admin1234');

    await tester.tap(find.byKey(const Key('boton-iniciar-sesion')));
    await tester.pumpAndSettle();
    expect(intentos.single.rolEsperado, RolesUsuario.admin);
    await esperarAviso(tester);
  });

  testWidgets('al salir del modo administrador vuelve al rol que estaba', (
    tester,
  ) async {
    await abrirLogin(tester);
    await tester.tap(find.text('Entrenador'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('boton-modo-admin')));
    await tester.pumpAndSettle();
    expect(textoBoton(tester), 'Entrar al panel');

    await tester.tap(find.byKey(const Key('boton-modo-admin')));
    await tester.pumpAndSettle();
    expect(textoBoton(tester), 'Iniciar sesión como Entrenador');
  });

  testWidgets('si la contraseña falla se borra, y el correo se conserva', (
    tester,
  ) async {
    await abrirLogin(tester);
    await escribirCredenciales(tester, 'ana@correo.unimet.edu.ve', 'Clave1234');

    await tester.tap(find.byKey(const Key('boton-iniciar-sesion')));
    await tester.pumpAndSettle();

    expect(find.text('Correo, carnet o contraseña incorrectos.'), findsOneWidget);
    expect(textoDe(tester, 'login-identificador'), 'ana@correo.unimet.edu.ve');
    expect(textoDe(tester, 'login-clave'), isEmpty);
    await esperarAviso(tester);
  });

  testWidgets('al volver de "Crear cuenta" el login está vacío', (
    tester,
  ) async {
    await abrirLogin(tester);
    await escribirCredenciales(tester, 'ana@correo.unimet.edu.ve', 'Clave1234');

    await tester.tap(find.byKey(const Key('boton-crear-cuenta')));
    await tester.pumpAndSettle();
    expect(find.text('REGISTRACIÓN'), findsOneWidget);
    // El registro empieza vacío: no trae las credenciales del login.
    final correoRegistro = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('registro-correo')),
        matching: find.byType(TextField),
      ),
    );
    expect(correoRegistro.controller!.text, isEmpty);

    Navigator.of(tester.element(find.text('REGISTRACIÓN'))).pop();
    await tester.pumpAndSettle();

    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    expect(textoDe(tester, 'login-identificador'), isEmpty);
    expect(textoDe(tester, 'login-clave'), isEmpty);
  });
}
