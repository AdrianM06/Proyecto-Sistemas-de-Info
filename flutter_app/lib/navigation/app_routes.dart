import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../views/buscador/buscador_screen.dart';
import '../views/landing_view.dart';
import '../views/login_screen.dart';
import '../views/password_recovery_screen.dart';
import '../views/profile_view.dart';
import '../views/registration_screen.dart';
import 'vistas_por_rol.dart';

/// Enrutador de la app: nombres de las rutas y qué pantalla abre cada una.
///
/// - `/` es la Landing Page (punto de entrada).
/// - `/login` y `/registro` son públicas.
/// - `/entrenador` y `/estudiante` exigen una sesión con ese rol; si no la
///   hay, se manda al usuario al inicio de sesión.
/// - Todas las rutas `/admin/...` exigen una sesión con `rol: "admin"`.
class AppRoutes {
  AppRoutes._();

  static const String landing = '/';
  static const String login = '/login';
  static const String registro = '/registro';
  static const String recuperarContrasena = '/recuperar-contrasena';
  static const String entrenador = '/entrenador';
  static const String estudiante = '/estudiante';
  static const String perfilEstudiante = '/estudiante/perfil';
  static const String catalogoEstudiante = '/estudiante/catalogo';
  static const String perfilEntrenador = '/entrenador/perfil';
  static const String perfilAdmin = '/admin/perfil';
  static const String buscador = '/buscador';
  static const String perfil = '/perfil';
  static const String adminDashboard = '/admin/dashboard';
  static const String gestionEstudiantes = '/admin/estudiantes';
  static const String crearDeporte = '/admin/crear-deporte';
  static const String registrarEntrenador = '/admin/entrenadores/nuevo';

  /// Ruta de inicio según el rol guardado en la base de datos.
  static String rutaParaRol(String rol) {
    switch (rol) {
      case RolesUsuario.admin:
        return adminDashboard;
      case RolesUsuario.entrenador:
        return entrenador;
      default:
        return estudiante;
    }
  }

  /// Envía al usuario a su vista y borra el historial (no puede volver al
  /// login con el botón atrás).
  static Future<void> irAVistaDelRol(
    BuildContext context,
    SesionUsuario sesion,
  ) {
    return Navigator.of(context).pushNamedAndRemoveUntil(
      rutaParaRol(sesion.rol),
      (route) => false,
      arguments: sesion,
    );
  }

  /// Vuelve a la Landing Page (`/`) desde cualquier pantalla. Borra el
  /// historial, así funciona igual si se entró directo por la URL o si se
  /// recargó la página. Si hay sesión abierta, se mantiene.
  static Future<void> irALanding(BuildContext context) {
    return Navigator.of(context)
        .pushNamedAndRemoveUntil(landing, (route) => false);
  }

  /// Cierra la sesión y lleva de inmediato al inicio de sesión. Lo usan
  /// la vista del entrenador y la del estudiante.
  static Future<void> cerrarSesion(BuildContext context) async {
    Navigator.of(context).pushNamedAndRemoveUntil(login, (route) => false);
    await AuthService.instance.signOut();
  }

  /// Abre la página de perfil del estudiante.
  static Future<void> abrirPerfilEstudiante(
    BuildContext context,
    SesionUsuario sesion,
  ) {
    return Navigator.of(context).pushNamed(perfilEstudiante, arguments: sesion);
  }

  /// Se usa en `MaterialApp.onGenerateRoute`.
  static Route<dynamic> generarRuta(RouteSettings settings) {
    final argumentos = settings.arguments;
    switch (settings.name) {
      case landing:
        return _ruta(settings, (_) => const LandingView());
      case login:
        return _ruta(settings, (_) => const LoginScreen());
      case registro:
        return _ruta(settings, (_) => const RegistrationScreen());
      case recuperarContrasena:
        return _ruta(settings, (_) => const PasswordRecoveryScreen());
      case entrenador:
        return _ruta(
          settings,
          (_) => RutaProtegida(
            rolRequerido: RolesUsuario.entrenador,
            sesionInicial: argumentos is SesionUsuario ? argumentos : null,
            constructor: construirVistaEntrenador,
          ),
        );
      case estudiante:
        return _ruta(
          settings,
          (_) => RutaProtegida(
            rolRequerido: RolesUsuario.estudiante,
            sesionInicial: argumentos is SesionUsuario ? argumentos : null,
            constructor: construirVistaEstudiante,
          ),
        );
      case perfilEstudiante:
        return _ruta(
          settings,
          (_) => RutaProtegida(
            rolRequerido: RolesUsuario.estudiante,
            sesionInicial: argumentos is SesionUsuario ? argumentos : null,
            constructor: construirPerfilEstudiante,
          ),
        );
      case catalogoEstudiante:
        return _ruta(
          settings,
          (_) => RutaProtegida(
            rolRequerido: RolesUsuario.estudiante,
            sesionInicial: argumentos is SesionUsuario ? argumentos : null,
            constructor: construirCatalogoEstudiante,
          ),
        );
      case perfilEntrenador:
        return _ruta(
          settings,
          (_) => RutaProtegida(
            rolRequerido: RolesUsuario.entrenador,
            sesionInicial: argumentos is SesionUsuario ? argumentos : null,
            constructor: construirPerfilCuenta,
          ),
        );
      case perfilAdmin:
        return _rutaAdmin(settings, construirPerfilCuenta);
      case buscador:
        return _ruta(settings, (_) => BuscadorScreen.conFirestore());
      case perfil:
        return _ruta(settings, (_) => ProfileView());
      case adminDashboard:
        return _rutaAdmin(settings, construirVistaAdmin);
      case gestionEstudiantes:
        return _rutaAdmin(settings, construirGestionEstudiantes);
      case crearDeporte:
        return _rutaAdmin(settings, construirCrearDeporte);
      case registrarEntrenador:
        return _rutaAdmin(settings, construirRegistroEntrenador);
      default:
        return _ruta(
          const RouteSettings(name: landing),
          (_) => const LandingView(),
        );
    }
  }

  /// Ruta del panel del administrador: solo entra una sesión con rol admin.
  static MaterialPageRoute<dynamic> _rutaAdmin(
    RouteSettings settings,
    Widget Function(BuildContext context, SesionUsuario sesion) constructor,
  ) {
    final argumentos = settings.arguments;
    return _ruta(
      settings,
      (_) => RutaProtegida(
        rolRequerido: RolesUsuario.admin,
        sesionInicial: argumentos is SesionUsuario ? argumentos : null,
        constructor: constructor,
      ),
    );
  }

  static MaterialPageRoute<dynamic> _ruta(
    RouteSettings settings,
    WidgetBuilder builder,
  ) {
    return MaterialPageRoute<dynamic>(settings: settings, builder: builder);
  }
}

/// Protege una vista por rol.
///
/// Usa la sesión que manda el login; si se entra directo por la URL (o se
/// recarga la página), la consulta a Firebase. Si no hay sesión vuelve al
/// login, y si el rol no coincide envía al usuario a la vista de su rol.
class RutaProtegida extends StatefulWidget {
  const RutaProtegida({
    super.key,
    required this.rolRequerido,
    required this.constructor,
    this.sesionInicial,
  });

  final String rolRequerido;
  final SesionUsuario? sesionInicial;
  final Widget Function(BuildContext context, SesionUsuario sesion) constructor;

  @override
  State<RutaProtegida> createState() => _RutaProtegidaState();
}

class _RutaProtegidaState extends State<RutaProtegida> {
  /// Solo se consulta a Firebase cuando no llegó la sesión por argumentos.
  Future<SesionUsuario?>? _sesion;

  @override
  void initState() {
    super.initState();
    if (widget.sesionInicial == null) {
      _sesion = AuthService.instance.sesionActual();
    }
  }

  void _redirigir(String ruta, {SesionUsuario? sesion}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(ruta, (route) => false, arguments: sesion);
    });
  }

  Widget _vistaPara(SesionUsuario? sesion) {
    if (sesion == null) {
      _redirigir(AppRoutes.login);
      return const Scaffold(body: SizedBox.shrink());
    }
    if (sesion.rol != widget.rolRequerido) {
      _redirigir(AppRoutes.rutaParaRol(sesion.rol), sesion: sesion);
      return const Scaffold(body: SizedBox.shrink());
    }
    return widget.constructor(context, sesion);
  }

  @override
  Widget build(BuildContext context) {
    // Con la sesión ya conocida (navegación dentro de la app) la vista se
    // dibuja en el primer cuadro: sin pantalla de carga ni saltos.
    final inicial = widget.sesionInicial;
    if (inicial != null) return _vistaPara(inicial);

    return FutureBuilder<SesionUsuario?>(
      future: _sesion,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _vistaPara(snapshot.hasError ? null : snapshot.data);
      },
    );
  }
}
