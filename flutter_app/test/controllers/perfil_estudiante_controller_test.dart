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
}
