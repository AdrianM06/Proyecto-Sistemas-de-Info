import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_app/controllers/perfil_estudiante_controller.dart';
import 'package:flutter_app/models/usuario.dart';
import 'package:flutter_app/services/perfil_estudiante_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _Datos implements PerfilEstudianteDataSource {
  _Datos(this.rol);

  final RolUsuario rol;
  Completer<String>? subida;
  int cambiosDeClave = 0;

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
  }) async {
    cambiosDeClave++;
  }

  @override
  Future<void> retirarDisciplina(String inscripcionId) async {}

  @override
  Future<void> actualizarDatos({
    required String nombre,
    required String apellido,
  }) async {}

  @override
  Future<String> subirFotoPerfil(Uint8List bytes, {required String tipo}) {
    subida = Completer<String>();
    return subida!.future;
  }
}

void main() {
  final foto = Uint8List.fromList([1, 2, 3, 4]);

  test(
    'muestra la foto elegida mientras se sube y luego deja la URL',
    () async {
      final datos = _Datos(RolUsuario.entrenador);
      final controller = PerfilEstudianteController(datos: datos);
      await controller.iniciar();

      final resultado = controller.cambiarFoto(foto, tipo: 'image/jpeg');
      await Future<void>.delayed(Duration.zero);

      expect(controller.subiendoFoto, isTrue);
      expect(controller.vistaPreviaFoto, foto);

      datos.subida!.complete('https://firebasestorage.googleapis.com/f.jpg');
      expect(await resultado, isNull);

      expect(controller.subiendoFoto, isFalse);
      expect(controller.vistaPreviaFoto, isNull);
      expect(
        controller.perfil!.usuario.fotoUrl,
        'https://firebasestorage.googleapis.com/f.jpg',
      );
      controller.dispose();
    },
  );

  test('un error al subir la foto libera el estado de carga', () async {
    final datos = _Datos(RolUsuario.entrenador);
    final controller = PerfilEstudianteController(datos: datos);
    await controller.iniciar();

    final resultado = controller.cambiarFoto(foto, tipo: 'image/jpeg');
    await Future<void>.delayed(Duration.zero);
    datos.subida!.completeError(StateError('sin red'));

    expect(await resultado, isNotNull);
    expect(controller.subiendoFoto, isFalse);
    expect(controller.vistaPreviaFoto, isNull);
    controller.dispose();
  });

  test('si la pantalla se cierra durante la subida no lanza errores', () async {
    final datos = _Datos(RolUsuario.estudiante);
    final controller = PerfilEstudianteController(datos: datos);
    await controller.iniciar();

    final resultado = controller.cambiarFoto(foto, tipo: 'image/jpeg');
    await Future<void>.delayed(Duration.zero);
    controller.dispose();
    datos.subida!.complete('https://firebasestorage.googleapis.com/f.jpg');

    expect(await resultado, isNull);
  });

  test('el administrador no puede cambiar la contraseña', () async {
    final datos = _Datos(RolUsuario.admin);
    final controller = PerfilEstudianteController(datos: datos);
    await controller.iniciar();

    expect(controller.esAdmin, isTrue);
    final cambiada = await controller.cambiarContrasena(
      actual: 'Actual123',
      nueva: 'Nueva1234',
      confirmacion: 'Nueva1234',
    );

    expect(cambiada, isFalse);
    expect(controller.errorClave, isNotNull);
    expect(datos.cambiosDeClave, 0);
    controller.dispose();
  });

  test('el entrenador sí puede cambiar la contraseña', () async {
    final datos = _Datos(RolUsuario.entrenador);
    final controller = PerfilEstudianteController(datos: datos);
    await controller.iniciar();

    expect(controller.esAdmin, isFalse);
    final cambiada = await controller.cambiarContrasena(
      actual: 'Actual123',
      nueva: 'Nueva1234',
      confirmacion: 'Nueva1234',
    );

    expect(cambiada, isTrue);
    expect(datos.cambiosDeClave, 1);
    controller.dispose();
  });
}
