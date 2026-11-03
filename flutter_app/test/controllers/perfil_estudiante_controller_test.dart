import 'dart:typed_data';

import 'package:flutter_app/controllers/perfil_estudiante_controller.dart';
import 'package:flutter_app/services/perfil_estudiante_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PerfilEstudianteDemoService datos;
  late PerfilEstudianteController controller;

  setUp(() async {
    datos = PerfilEstudianteDemoService(latencia: Duration.zero);
    controller = PerfilEstudianteController(datos: datos);
    await controller.iniciar();
  });

  tearDown(() => controller.dispose());

  test('carga el perfil del estudiante', () {
    expect(controller.error, isNull);
    expect(controller.perfil?.usuario.nombreCompleto, 'Andrea Pérez');
    expect(controller.perfil?.disciplinas, hasLength(2));
  });

  test('valida el formulario antes de cambiar la clave', () async {
    expect(
      await controller.cambiarContrasena(
        actual: '',
        nueva: 'NuevaClave1',
        confirmacion: 'NuevaClave1',
      ),
      isFalse,
    );
    expect(controller.errorClave, 'Escribe tu contraseña actual.');

    await controller.cambiarContrasena(
      actual: PerfilEstudianteDemoService.contrasenaDemo,
      nueva: 'NuevaClave1',
      confirmacion: 'OtraClave1',
    );
    expect(controller.errorClave, 'Las contraseñas nuevas no coinciden.');

    await controller.cambiarContrasena(
      actual: PerfilEstudianteDemoService.contrasenaDemo,
      nueva: 'corta',
      confirmacion: 'corta',
    );
    expect(controller.errorClave, isNotNull);
    expect(datos.contrasenaActual, PerfilEstudianteDemoService.contrasenaDemo);
  });

  test('muestra el error si la clave actual es incorrecta', () async {
    final cambiada = await controller.cambiarContrasena(
      actual: 'Equivocada1',
      nueva: 'NuevaClave1',
      confirmacion: 'NuevaClave1',
    );

    expect(cambiada, isFalse);
    expect(controller.errorClave, 'La contraseña actual no es correcta.');
    expect(controller.cambiandoClave, isFalse);
  });

  test('cambia la clave y deja un mensaje de éxito', () async {
    final cambiada = await controller.cambiarContrasena(
      actual: PerfilEstudianteDemoService.contrasenaDemo,
      nueva: 'NuevaClave1',
      confirmacion: 'NuevaClave1',
    );

    expect(cambiada, isTrue);
    expect(controller.errorClave, isNull);
    expect(controller.mensajeExito, isNotNull);
    expect(datos.contrasenaActual, 'NuevaClave1');
  });

  test('retirar una disciplina la quita de la lista', () async {
    final natacion = controller.perfil!.disciplinas
        .firstWhere((d) => d.deporteId == 'NAT-01');

    final retirada = await controller.retirarDisciplina(natacion);

    expect(retirada, isTrue);
    expect(controller.perfil!.disciplinas.map((d) => d.deporteId), ['FUT-M01']);
  });

  test('actualizar datos cambia solo el nombre y el apellido', () async {
    final error = await controller.actualizarDatos(
      nombre: '  maría   josé ',
      apellido: 'Gómez',
    );

    expect(error, isNull);
    expect(controller.perfil!.usuario.nombreCompleto, 'maría josé Gómez');
    expect(controller.perfil!.usuario.carnet, '20221110342');
    expect(datos.usuario.apellido, 'Gómez');
  });

  test('actualizar datos rechaza nombres vacíos o con números', () async {
    expect(
      await controller.actualizarDatos(nombre: '', apellido: 'Gómez'),
      'El nombre es obligatorio',
    );
    expect(
      await controller.actualizarDatos(nombre: 'Ana', apellido: 'G0mez'),
      'El apellido solo puede tener letras',
    );
    expect(datos.usuario.nombre, 'Andrea');
  });

  test('cambiar la foto guarda la URL nueva', () async {
    final error = await controller.cambiarFoto(
      Uint8List.fromList([1, 2, 3]),
      tipo: 'image/png',
    );

    expect(error, isNull);
    expect(controller.perfil!.usuario.fotoUrl, isNotEmpty);
  });

  test('cambiar la foto rechaza archivos que no son imágenes', () async {
    final error = await controller.cambiarFoto(
      Uint8List.fromList([1, 2, 3]),
      tipo: 'application/pdf',
    );

    expect(error, 'Usa una imagen JPG, PNG o WEBP.');
    expect(controller.perfil!.usuario.fotoUrl, isNull);
  });

  test('cambiar la foto rechaza imágenes de más de 2 MB', () async {
    final error = await controller.cambiarFoto(
      Uint8List(3 * 1024 * 1024),
      tipo: 'image/jpeg',
    );

    expect(error, 'La imagen pesa más de 2 MB.');
  });
}
