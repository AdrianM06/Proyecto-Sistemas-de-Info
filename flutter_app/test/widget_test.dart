import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/views/main.dart';

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
}
