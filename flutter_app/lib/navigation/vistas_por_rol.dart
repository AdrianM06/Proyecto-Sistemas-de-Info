import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../views/entrenador/entrenador_home_screen.dart';
import '../views/student_view.dart';
import 'app_routes.dart';

/// Punto único donde la navegación se conecta con las vistas de cada rol.
///
/// - Vista del entrenador: rama `feature/vista-entrenador`
///   (`lib/views/entrenador/entrenador_home_screen.dart`).
/// - Vista del estudiante: rama `feature/vista-estudiante`
///   (`lib/views/student_view.dart`).
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
  return StudentView();
}
