import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_app/controllers/perfil_estudiante_controller.dart';
import 'package:flutter_app/models/usuario.dart';
import 'package:flutter_app/services/perfil_estudiante_service.dart';
import 'package:flutter_app/views/perfil_cuenta_view.dart';
import 'package:flutter_test/flutter_test.dart';

class _Datos implements PerfilEstudianteDataSource {
  _Datos(this.rol);

  final RolUsuario rol;

  @override
  Future<PerfilEstudiante> cargarPerfil() async => PerfilEstudiante(
    usuario: Usuario(
      uid: 'u1',
      email: 'persona@unimet.edu.ve',
      nombre: 'Persona',
      apellido: 'Prueba',
      rol: rol,
    ),
  );

  @override
  Future<void> cambiarContrasena({
    required String actual,
    required String nueva,
  }) async {}

  @override
  Future<void> retirarDisciplina(String inscripcionId) async {}

  @override
  Future<void> actualizarDatos({
    required String nombre,
    required String apellido,
  }) async {}

  @override
  Future<String> subirFotoPerfil(
    Uint8List bytes, {
    required String tipo,
  }) async => 'https://firebasestorage.googleapis.com/f.jpg';
}

void main() {
  Future<void> abrir(WidgetTester tester, RolUsuario rol) async {
    tester.view.physicalSize = const Size(1400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: PerfilCuentaView(
          controller: PerfilEstudianteController(datos: _Datos(rol)),
          onCerrarSesion: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('el entrenador puede cambiar la foto y la clave', (tester) async {
    await abrir(tester, RolUsuario.entrenador);

    expect(find.byKey(const Key('perfil-nombre')), findsOneWidget);
    expect(find.text('Persona Prueba'), findsOneWidget);
    expect(find.text('entrenador'), findsOneWidget);
    expect(find.byKey(const Key('boton-cambiar-foto')), findsOneWidget);
    expect(find.byKey(const Key('boton-cambiar-clave')), findsOneWidget);

    await tester.tap(find.byKey(const Key('boton-cambiar-clave')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dialogo-cambiar-clave')), findsOneWidget);
  });

  testWidgets('el administrador no ve la opción de cambiar la clave', (
    tester,
  ) async {
    await abrir(tester, RolUsuario.admin);

    expect(find.text('administrador'), findsOneWidget);
    expect(find.byKey(const Key('boton-cambiar-foto')), findsOneWidget);
    expect(find.byKey(const Key('boton-cambiar-clave')), findsNothing);
    expect(find.text('Cambiar clave'), findsNothing);
  });
}
