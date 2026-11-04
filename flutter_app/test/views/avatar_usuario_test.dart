import 'package:flutter/material.dart';
import 'package:flutter_app/views/widgets/avatar_usuario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> abrir(WidgetTester tester, {String? fotoUrl}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AvatarUsuario(fotoUrl: fotoUrl, iniciales: 'AP', radio: 40),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sin foto muestra las iniciales', (tester) async {
    await abrir(tester);

    expect(find.text('AP'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('con foto usa un widget Image y no un backgroundImage', (
    tester,
  ) async {
    await abrir(tester, fotoUrl: 'https://example.com/foto.jpg');

    expect(find.byType(Image), findsOneWidget);
    expect(
      tester.widget<CircleAvatar>(find.byType(CircleAvatar)).backgroundImage,
      isNull,
    );
  });

  testWidgets('si la foto no carga vuelve a mostrar las iniciales', (
    tester,
  ) async {
    await abrir(tester, fotoUrl: 'https://example.com/foto.jpg');

    expect(find.text('AP'), findsOneWidget);
  });
}
