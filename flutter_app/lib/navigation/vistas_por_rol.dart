import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../views/entrenador/entrenador_home_screen.dart';
import '../views/estudiante/perfil_estudiante_view.dart';
import '../views/student_view.dart';
import 'app_routes.dart';

/// Punto único donde la navegación se conecta con las vistas de cada rol.
///
/// - Vista del entrenador: `lib/views/entrenador/entrenador_home_screen.dart`.
/// - Vista del estudiante: `lib/views/student_view.dart`.
/// - Perfil del estudiante: `lib/views/estudiante/perfil_estudiante_view.dart`.
///
/// Si alguna de esas vistas cambia de nombre, solo hay que tocar este
/// archivo.
Widget construirVistaEntrenador(BuildContext context, SesionUsuario sesion) {
  return EntrenadorHomeScreen.conFirestore(
    entrenadorId: sesion.uid,
    nombreEntrenador: sesion.nombre,
    onCerrarSesion: () => AppRoutes.cerrarSesion(context),
  );
}

Widget construirVistaEstudiante(BuildContext context, SesionUsuario sesion) {
  return StudentView(
    onCerrarSesion: () => AppRoutes.cerrarSesion(context),
    onAbrirPerfil: () => AppRoutes.abrirPerfilEstudiante(context, sesion),
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
  );
}

Widget construirVistaAdmin(BuildContext context, SesionUsuario sesion) {
  return const AdminDashboardView();
}
