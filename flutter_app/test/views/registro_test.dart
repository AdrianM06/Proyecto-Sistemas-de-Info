import 'package:flutter/material.dart';
import 'package:flutter_app/navigation/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pruebas del formulario de registro. Solo revisan las validaciones del
/// frontend: con datos inválidos no se envía nada a Firebase.
void main() {
  Future<void> abrirRegistro(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        initialRoute: AppRoutes.registro,
        onGenerateRoute: AppRoutes.generarRuta,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> escribir(WidgetTester tester, String campo, String texto) {
    return tester.enterText(find.byKey(Key('registro-$campo')), texto);
  }

  Future<void> enviar(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('boton-registrar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('boton-registrar')));
    await tester.pumpAndSettle();
  }

  testWidgets('todos los campos son obligatorios', (tester) async {
    await abrirRegistro(tester);
    await enviar(tester);

    expect(find.text('El nombre es obligatorio'), findsOneWidget);
    expect(find.text('El apellido es obligatorio'), findsOneWidget);
    expect(find.text('El correo es obligatorio'), findsOneWidget);
    expect(find.text('La cédula es obligatoria'), findsOneWidget);
    expect(find.text('El carnet es obligatorio'), findsOneWidget);
    expect(find.text('La contraseña es obligatoria'), findsOneWidget);
    expect(find.text('Repite la contraseña'), findsOneWidget);
  });

  testWidgets('solo acepta el correo estudiantil de la Unimet', (tester) async {
    await abrirRegistro(tester);
    await escribir(tester, 'correo', 'ana@gmail.com');
    await enviar(tester);

    expect(
      find.text('Usa tu correo estudiantil (@correo.unimet.edu.ve)'),
      findsOneWidget,
    );
  });

  testWidgets('valida el formato del carnet y de la cédula', (tester) async {
    await abrirRegistro(tester);
    await escribir(tester, 'carnet', '2022111');
    await escribir(tester, 'cedula', 'X-12');
    await enviar(tester);

    expect(find.text('El carnet debe tener 11 dígitos'), findsOneWidget);
    expect(find.text('Escribe una cédula válida (ej. V-12345678)'), findsOneWidget);
  });

  testWidgets('las contraseñas deben coincidir', (tester) async {
    await abrirRegistro(tester);
    await escribir(tester, 'clave', 'Clave1234');
    await escribir(tester, 'confirmar-clave', 'Clave12345');
    await enviar(tester);

    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
  });

  testWidgets('con datos válidos no quedan errores en el formulario', (
    tester,
  ) async {
    await abrirRegistro(tester);
    await escribir(tester, 'nombre', 'Ana');
    await escribir(tester, 'apellido', 'Pérez');
    await escribir(tester, 'correo', 'ana.perez@correo.unimet.edu.ve');
    await escribir(tester, 'cedula', 'V-27123456');
    await escribir(tester, 'carnet', '20221110045');
    await escribir(tester, 'clave', 'Clave1234');
    await escribir(tester, 'confirmar-clave', 'Clave1234');
    await tester.pumpAndSettle();

    final formulario = tester.state<FormState>(find.byType(Form));
    expect(formulario.validate(), isTrue);
  });
}
