import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/main.dart';

void main() {
  testWidgets('shows the UNIMET Sports sign-in screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UnimetSportsApp());

    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    expect(find.text('UNIMET'), findsOneWidget);
    expect(find.text('Correo/Carnet Universitario'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Estudiante'), findsOneWidget);
    expect(find.text('Entrenador'), findsOneWidget);
  });

  testWidgets('opens recovery and validates the email and student ID', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UnimetSportsApp());

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
