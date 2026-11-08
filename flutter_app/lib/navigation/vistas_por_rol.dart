import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../views/entrenador/entrenador_home_screen.dart';
import '../views/estudiante/perfil_estudiante_view.dart';
import '../views/student_view.dart';
import 'app_routes.dart';

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
    onIrACatalogo: () => Navigator.of(context).pushNamed(AppRoutes.buscador, arguments: sesion),
    onIrALanding: () => Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.landing, (_) => false),
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
    onIrACatalogo: () => Navigator.of(context).pushNamed(AppRoutes.buscador, arguments: sesion),
  );
}