import 'package:flutter_app/navigation/app_routes.dart';
import 'package:flutter_app/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RolesUsuario.desdeTexto', () {
    test('reconoce el rol admin', () {
      expect(RolesUsuario.desdeTexto('admin'), RolesUsuario.admin);
      expect(RolesUsuario.desdeTexto(' Admin '), RolesUsuario.admin);
      expect(RolesUsuario.desdeTexto('administrador'), RolesUsuario.admin);
    });

    test('reconoce entrenador y estudiante', () {
      expect(RolesUsuario.desdeTexto('entrenador'), RolesUsuario.entrenador);
      expect(RolesUsuario.desdeTexto('estudiante'), RolesUsuario.estudiante);
    });

    test('un rol desconocido o vacío nunca da permisos de admin', () {
      expect(RolesUsuario.desdeTexto(null), RolesUsuario.estudiante);
      expect(RolesUsuario.desdeTexto(''), RolesUsuario.estudiante);
      expect(RolesUsuario.desdeTexto('superusuario'), RolesUsuario.estudiante);
    });
  });

  group('AppRoutes.rutaParaRol', () {
    test('cada rol va a su vista', () {
      expect(AppRoutes.rutaParaRol(RolesUsuario.admin), AppRoutes.adminDashboard);
      expect(
        AppRoutes.rutaParaRol(RolesUsuario.entrenador),
        AppRoutes.entrenador,
      );
      expect(
        AppRoutes.rutaParaRol(RolesUsuario.estudiante),
        AppRoutes.estudiante,
      );
    });

    test('las rutas del panel están bajo /admin', () {
      for (final ruta in [
        AppRoutes.adminDashboard,
        AppRoutes.gestionEstudiantes,
        AppRoutes.crearDeporte,
        AppRoutes.registrarEntrenador,
      ]) {
        expect(ruta.startsWith('/admin/'), isTrue);
      }
    });
  });

  test('SesionUsuario sabe si es admin', () {
    const sesion = SesionUsuario(
      uid: 'u1',
      email: 'admin@unimet.edu.ve',
      nombre: 'Admin',
      rol: RolesUsuario.admin,
    );
    expect(sesion.esAdmin, isTrue);
    expect(sesion.esEntrenador, isFalse);
  });
}
