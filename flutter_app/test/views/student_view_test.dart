import 'package:flutter/material.dart';
import 'package:flutter_app/controllers/inicio_estudiante_controller.dart';
import 'package:flutter_app/models/deporte.dart';
import 'package:flutter_app/services/inicio_estudiante_service.dart';
import 'package:flutter_app/views/student_view.dart';
import 'package:flutter_test/flutter_test.dart';

class _Vacio implements InicioEstudianteDataSource {
  @override
  Stream<Set<String>> deportesInscritos(String id) => Stream.value({});

  @override
  Stream<List<Deporte>> deportes() => Stream.value(const []);
}

InicioEstudianteController _vacio() =>
    InicioEstudianteController(datos: _Vacio(), estudianteId: 'e1');

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
          controller: _vacio(),
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

  testWidgets('el menú hamburguesa agrupa los botones y funcionan', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    var catalogo = false;
    var landing = false;
    await tester.pumpWidget(
      MaterialApp(
        home: StudentView(
          controller: _vacio(),
          onAbrirPerfil: () {},
          onCerrarSesion: () {},
          onIrACatalogo: () => catalogo = true,
          onIrALanding: () => landing = true,
        ),
      ),
    );

    // Con el menú cerrado los botones no aparecen debajo de la barra.
    expect(find.byKey(const Key('menu-Catálogo')), findsNothing);

    await tester.tap(find.byKey(const Key('boton-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('menu-Catálogo')));
    await tester.pumpAndSettle();
    expect(catalogo, isTrue);
    // Al elegir una opción el menú se cierra.
    expect(find.byKey(const Key('menu-estudiante')), findsNothing);

    await tester.tap(find.byKey(const Key('boton-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('menu-Página principal')));
    await tester.pumpAndSettle();
    expect(landing, isTrue);
  });
}

