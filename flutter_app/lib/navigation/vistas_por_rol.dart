import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../views/admin/admin_dashboard_view.dart';
import '../views/admin/crear_deporte_view.dart';
import '../views/admin/gestion_disciplinas_view.dart';
import '../views/admin/gestion_entrenadores_view.dart';
import '../views/admin/gestion_estudiantes_view.dart';
import '../views/admin/registrar_entrenador_view.dart';
import '../views/entrenador/entrenador_home_screen.dart';
import '../views/estudiante/perfil_estudiante_view.dart';
import '../views/buscador/buscador_screen.dart';
import '../views/perfil_cuenta_view.dart';
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
    avatar: AvatarUsuarioEnVivo(uid: sesion.uid),
    onAbrirPerfil: () =>
        Navigator.of(context)
            .pushNamed(AppRoutes.perfilEntrenador, arguments: sesion),
    onCerrarSesion: () => AppRoutes.cerrarSesion(context),
    onIrALanding: () => AppRoutes.irALanding(context),
  );
}

Widget construirVistaEstudiante(BuildContext context, SesionUsuario sesion) {
  return StudentView.conFirebase(
    estudianteId: sesion.uid,
    avatar: AvatarUsuarioEnVivo(uid: sesion.uid),
    onCerrarSesion: () => AppRoutes.cerrarSesion(context),
    onAbrirPerfil: () => AppRoutes.abrirPerfilEstudiante(context, sesion),
    onIrACatalogo: () =>
        Navigator.of(context)
            .pushNamed(AppRoutes.catalogoEstudiante, arguments: sesion),
    onIrALanding: () => AppRoutes.irALanding(context),
  );
}

/// Catálogo del estudiante con sesión: permite inscribirse en una
/// disciplina. El catálogo público (`/buscador`) solo deja consultar.
Widget construirCatalogoEstudiante(BuildContext context, SesionUsuario sesion) {
  return BuscadorScreen.paraEstudiante(estudianteId: sesion.uid);
}

/// Perfil del entrenador y del administrador. El administrador no ve el
/// botón para cambiar la contraseña.
Widget construirPerfilCuenta(BuildContext context, SesionUsuario sesion) {
  return PerfilCuentaView.conFirebase(
    onCerrarSesion: () => AppRoutes.cerrarSesion(context),
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
    onIrACatalogo: () =>
        Navigator.of(context)
            .pushNamed(AppRoutes.catalogoEstudiante, arguments: sesion),
    onIrALanding: () => AppRoutes.irALanding(context),
  );
}

Widget construirVistaAdmin(BuildContext context, SesionUsuario sesion) {
  final navigator = Navigator.of(context);
  return AdminDashboardView(
    nombreAdmin: sesion.nombre,
    avatar: AvatarUsuarioEnVivo(uid: sesion.uid),
    onAbrirPerfil: () =>
        navigator.pushNamed(AppRoutes.perfilAdmin, arguments: sesion),
    onCerrarSesion: () => AppRoutes.cerrarSesion(context),
    onIrALanding: () => AppRoutes.irALanding(context),
    onRegistrarEntrenador: () =>
        navigator.pushNamed(AppRoutes.registrarEntrenador, arguments: sesion),
    onCrearDeporte: () =>
        navigator.pushNamed(AppRoutes.crearDeporte, arguments: sesion),
    onGestionarDisciplinas: () =>
        navigator.pushNamed(AppRoutes.gestionDisciplinas, arguments: sesion),
    onGestionarEstudiantes: () =>
        navigator.pushNamed(AppRoutes.gestionEstudiantes, arguments: sesion),
    onGestionarEntrenadores: () =>
        navigator.pushNamed(AppRoutes.gestionEntrenadores, arguments: sesion),
    // Solo se llega desde el panel del admin, que ya pasó por la guarda de
    // rol de la ruta.
    onEditarDeporte: (deporte) => navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => CrearDeporteView(deporte: deporte),
      ),
    ),
  );
}

Widget construirGestionEntrenadores(BuildContext context, SesionUsuario sesion) {
  final navigator = Navigator.of(context);
  return GestionEntrenadoresView.conFirebase(
    onRegistrarEntrenador: () =>
        navigator.pushNamed(AppRoutes.registrarEntrenador, arguments: sesion),
  );
}

Widget construirGestionEstudiantes(BuildContext context, SesionUsuario sesion) {
  return const GestionEstudiantesView();
}

Widget construirGestionDisciplinas(BuildContext context, SesionUsuario sesion) {
  return GestionDisciplinasView.conFirebase();
}

Widget construirCrearDeporte(BuildContext context, SesionUsuario sesion) {
  return const CrearDeporteView();
}

Widget construirRegistroEntrenador(BuildContext context, SesionUsuario sesion) {
  return const RegistrarEntrenadorView();
}
