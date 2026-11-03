import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../views/admin/admin_dashboard_view.dart';
import '../views/admin/crear_deporte_view.dart';
import '../views/admin/gestion_estudiantes_view.dart';
import '../views/admin/registrar_entrenador_view.dart';
import '../views/entrenador/entrenador_home_screen.dart';
import '../views/estudiante/perfil_estudiante_view.dart';
import '../views/student_view.dart';
import '../views/widgets/avatar_usuario.dart';
import 'app_routes.dart';

/// Punto único donde la navegación se conecta con las vistas de cada rol.
///
/// - Vista del entrenador: `lib/views/entrenador/entrenador_home_screen.dart`.
/// - Vista del estudiante: `lib/views/student_view.dart`.
/// - Perfil del estudiante: `lib/views/estudiante/perfil_estudiante_view.dart`.
/// - Panel del administrador: `lib/views/admin/`.
///
/// Si alguna de esas vistas cambia de nombre, solo hay que tocar este
/// archivo.
Widget construirVistaEntrenador(BuildContext context, SesionUsuario sesion) {
  return EntrenadorHomeScreen.conFirestore(
    entrenadorId: sesion.uid,
    nombreEntrenador: sesion.nombre,
    onCerrarSesion: () => AppRoutes.cerrarSesion(context),
    onIrALanding: () => AppRoutes.irALanding(context),
  );
}

Widget construirVistaEstudiante(BuildContext context, SesionUsuario sesion) {
  return StudentView(
    avatar: AvatarUsuarioEnVivo(uid: sesion.uid),
    onCerrarSesion: () => AppRoutes.cerrarSesion(context),
    onAbrirPerfil: () => AppRoutes.abrirPerfilEstudiante(context, sesion),
    onIrACatalogo: () => Navigator.of(context).pushNamed(AppRoutes.buscador),
    onIrALanding: () => AppRoutes.irALanding(context),
  );
}

Widget construirPerfilEstudiante(BuildContext context, SesionUsuario sesion) {
  return PerfilEstudianteView.conFirebase(
    onCerrarSesion: () => AppRoutes.cerrarSesion(context),
    onIrAInicio: () {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      } else {
        navigator.pushReplacementNamed(AppRoutes.estudiante, arguments: sesion);
      }
    },
    onIrACatalogo: () => Navigator.of(context).pushNamed(AppRoutes.buscador),
    onIrALanding: () => AppRoutes.irALanding(context),
  );
}

Widget construirVistaAdmin(BuildContext context, SesionUsuario sesion) {
  final navigator = Navigator.of(context);
  return AdminDashboardView(
    nombreAdmin: sesion.nombre,
    onCerrarSesion: () => AppRoutes.cerrarSesion(context),
    onIrALanding: () => AppRoutes.irALanding(context),
    onRegistrarEntrenador: () =>
        navigator.pushNamed(AppRoutes.registrarEntrenador, arguments: sesion),
    onCrearDeporte: () =>
        navigator.pushNamed(AppRoutes.crearDeporte, arguments: sesion),
    onGestionarEstudiantes: () =>
        navigator.pushNamed(AppRoutes.gestionEstudiantes, arguments: sesion),
  );
}

Widget construirGestionEstudiantes(BuildContext context, SesionUsuario sesion) {
  return const GestionEstudiantesView();
}

Widget construirCrearDeporte(BuildContext context, SesionUsuario sesion) {
  return const CrearDeporteView();
}

Widget construirRegistroEntrenador(BuildContext context, SesionUsuario sesion) {
  return const RegistrarEntrenadorView();
}
