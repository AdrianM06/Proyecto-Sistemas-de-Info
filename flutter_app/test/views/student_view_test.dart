import 'package:flutter/material.dart';
import 'package:flutter_app/views/student_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('el avatar abre el perfil y el botón de salir cierra sesión', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    var perfilAbierto = false;
    var sesionCerrada = false;
    await tester.pumpWidget(
      MaterialApp(
        home: StudentView(
          onAbrirPerfil: () => perfilAbierto = true,
          onCerrarSesion: () => sesionCerrada = true,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('avatar-perfil')));
    await tester.pump();
    expect(perfilAbierto, isTrue);

    await tester.tap(find.byKey(const Key('boton-cerrar-sesion')));
    await tester.pump();
    expect(sesionCerrada, isTrue);
  });
}
