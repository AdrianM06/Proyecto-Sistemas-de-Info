import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';
import '../services/auth_service.dart';

// Paleta universitaria (la misma del login).
const _azul = Color(0xFF003B82);
const _azulOscuro = Color(0xFF0B1F44);
const _naranja = Color(0xFFF58220);
const _fondo = Color(0xFFF5F7FB);
const _texto = Color(0xFF1F2937);
const _gris = Color(0xFF5E6B84);

/// Landing Page (ruta `/`): presenta Samán Deportivo como la plataforma de
/// deportes de la Universidad Metropolitana. "Acceder" y "Comenzar Ahora"
/// llevan al inicio de sesión; si ya hay una sesión abierta, "Ir a mi panel"
/// lleva a la vista del rol. En pantallas angostas los enlaces de la barra
/// se agrupan en un menú hamburguesa.
class LandingView extends StatefulWidget {
  const LandingView({super.key});

  @override
  State<LandingView> createState() => _LandingViewState();
}

class _LandingViewState extends State<LandingView> {
  final _claveMision = GlobalKey();
  final _claveModulos = GlobalKey();
  final _clavePasos = GlobalKey();

  /// Sesión abierta, si el usuario ya inició sesión antes.
  SesionUsuario? _sesion;

  @override
  void initState() {
    super.initState();
    _buscarSesion();
  }

  Future<void> _buscarSesion() async {
    try {
      if (Firebase.apps.isEmpty) return;
      final sesion = await AuthService.instance.sesionActual();
      if (mounted && sesion != null) setState(() => _sesion = sesion);
    } catch (_) {
      // Sin sesión o sin conexión: la Landing funciona igual.
    }
  }

  void _irA(GlobalKey clave) {
    final contexto = clave.currentContext;
    if (contexto == null) return;
    Scrollable.ensureVisible(
      contexto,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  /// "Acceder": al login, o a la vista del rol si ya hay sesión.
  void _acceder() {
    final sesion = _sesion;
    if (sesion != null) {
      AppRoutes.irAVistaDelRol(context, sesion);
    } else {
      Navigator.of(context).pushNamed(AppRoutes.login);
    }
  }

  void _avisar(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  /// Abre un módulo de "Nuestros módulos principales".
  void _abrirModulo(_Modulo modulo) {
    final navigator = Navigator.of(context);
    if (modulo.rol == null) {
      navigator.pushNamed(modulo.ruta);
      return;
    }
    final sesion = _sesion;
    if (sesion == null) {
      _avisar('Inicia sesión para entrar a ${modulo.titulo}.');
      navigator.pushNamed(AppRoutes.login);
      return;
    }
    if (sesion.rol != modulo.rol) {
      _avisar(
        '${modulo.titulo} es solo para cuentas de '
        '${RolesUsuario.nombreVisible(modulo.rol!)}. Te llevamos a tu panel.',
      );
      AppRoutes.irAVistaDelRol(context, sesion);
      return;
    }
    navigator.pushNamed(modulo.ruta, arguments: sesion);
  }

  @override
  Widget build(BuildContext context) {
    final escritorio = MediaQuery.sizeOf(context).width >= 900;
    final textoAcceder = _sesion == null ? 'Acceder' : 'Ir a mi panel';
    return Scaffold(
      backgroundColor: _fondo,
      endDrawer: escritorio
          ? null
          : _MenuLanding(
              textoAcceder: textoAcceder,
              onAcceder: _acceder,
              onMision: () => _irA(_claveMision),
              onModulos: () => _irA(_claveModulos),
              onPasos: () => _irA(_clavePasos),
            ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BarraNavegacion(
              escritorio: escritorio,
              textoAcceder: textoAcceder,
              onAcceder: _acceder,
              onMision: () => _irA(_claveMision),
              onModulos: () => _irA(_claveModulos),
              onPasos: () => _irA(_clavePasos),
            ),
            _Portada(
              escritorio: escritorio,
              onComenzar: _acceder,
              onConocerMas: () => _irA(_claveMision),
            ),
            _SeccionMisionVision(key: _claveMision, escritorio: escritorio),
            _SeccionModulos(
              key: _claveModulos,
              escritorio: escritorio,
              onAbrir: _abrirModulo,
            ),
            _SeccionPasos(key: _clavePasos, escritorio: escritorio),
            _BandaLlamado(textoAcceder: textoAcceder, onAcceder: _acceder),
            const _PiePagina(),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- utilidades

/// Centra el contenido con un ancho máximo, como un sitio web.
class _Contenido extends StatelessWidget {
  const _Contenido({required this.child, this.vertical = 72});

  final Widget child;
  final double vertical;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: vertical),
          child: child,
        ),
      ),
    );
  }
}

class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion({
    required this.etiqueta,
    required this.titulo,
    this.descripcion,
  });

  final String etiqueta;
  final String titulo;
  final String? descripcion;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          etiqueta.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _naranja,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _azulOscuro,
            fontSize: 32,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (descripcion != null) ...[
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(
              descripcion!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _gris, fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ],
    );
  }
}

// ------------------------------------------------------- barra superior

class _BarraNavegacion extends StatelessWidget {
  const _BarraNavegacion({
    required this.escritorio,
    required this.textoAcceder,
    required this.onAcceder,
    required this.onMision,
    required this.onModulos,
    required this.onPasos,
  });

  final bool escritorio;
  final String textoAcceder;
  final VoidCallback onAcceder;
  final VoidCallback onMision;
  final VoidCallback onModulos;
  final VoidCallback onPasos;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          Image.asset(
            'assets/images/unimet_sports_logo.png',
            height: 40,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.sports, color: _naranja, size: 36),
          ),
          const SizedBox(width: 12),
          const Flexible(
            child: Text(
              'Samán Deportivo',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _azul,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Spacer(),
          if (escritorio) ...[
            _EnlaceNavegacion(texto: 'Misión y Visión', onTap: onMision),
            _EnlaceNavegacion(texto: 'Módulos', onTap: onModulos),
            _EnlaceNavegacion(texto: 'Cómo funciona', onTap: onPasos),
            const SizedBox(width: 12),
            ElevatedButton(
              key: const Key('landing-boton-acceder'),
              onPressed: onAcceder,
              style: ElevatedButton.styleFrom(
                backgroundColor: _naranja,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                textoAcceder,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ] else
            // En pantallas angostas todo va dentro del menú hamburguesa.
            Builder(
              builder: (context) => IconButton(
                key: const Key('landing-boton-menu'),
                tooltip: 'Menú',
                icon: const Icon(Icons.menu, color: _azul, size: 30),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
        ],
      ),
    );
  }
}

/// Menú desplegable de la Landing en pantallas angostas.
class _MenuLanding extends StatelessWidget {
  const _MenuLanding({
    required this.textoAcceder,
    required this.onAcceder,
    required this.onMision,
    required this.onModulos,
    required this.onPasos,
  });

  final String textoAcceder;
  final VoidCallback onAcceder;
  final VoidCallback onMision;
  final VoidCallback onModulos;
  final VoidCallback onPasos;

  @override
  Widget build(BuildContext context) {
    void elegir(VoidCallback accion) {
      Navigator.of(context).pop(); // Cierra el menú.
      accion();
    }

    return Drawer(
      key: const Key('landing-menu'),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Text(
                'Samán Deportivo',
                style: TextStyle(
                  color: _azul,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: _azul),
              title: const Text('Misión y Visión'),
              onTap: () => elegir(onMision),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined, color: _azul),
              title: const Text('Módulos'),
              onTap: () => elegir(onModulos),
            ),
            ListTile(
              leading: const Icon(Icons.route_outlined, color: _azul),
              title: const Text('Cómo funciona'),
              onTap: () => elegir(onPasos),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: ElevatedButton(
                key: const Key('landing-menu-acceder'),
                onPressed: () => elegir(onAcceder),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _naranja,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  textoAcceder,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnlaceNavegacion extends StatelessWidget {
  const _EnlaceNavegacion({required this.texto, required this.onTap});

  final String texto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(foregroundColor: _texto),
      child: Text(texto, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

// ---------------------------------------------------------------- portada

class _Portada extends StatelessWidget {
  const _Portada({
    required this.escritorio,
    required this.onComenzar,
    required this.onConocerMas,
  });

  final bool escritorio;
  final VoidCallback onComenzar;
  final VoidCallback onConocerMas;

  @override
  Widget build(BuildContext context) {
    // La altura mínima da el aspecto de portada; si el texto necesita más
    // espacio (pantallas angostas o letra grande), la portada crece.
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: escritorio ? 560 : 620),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/tennis_stock_photo.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const ColoredBox(color: _azul),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    _azulOscuro.withValues(alpha: 0.95),
                    _azul.withValues(alpha: 0.75),
                    _azul.withValues(alpha: 0.35),
                  ],
                ),
              ),
            ),
          ),
          _Contenido(
            vertical: 56,
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _naranja,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Deporte universitario · Unimet',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Bienvenido a Samán Deportivo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: escritorio ? 52 : 38,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'La plataforma de deportes de la Universidad Metropolitana: '
                      'descubre las disciplinas, inscríbete, consulta tus '
                      'horarios y lleva tu asistencia desde un solo lugar.',
                      style: TextStyle(
                        color: Color(0xFFDDE5F3),
                        fontSize: 18,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Wrap(
                      spacing: 14,
                      runSpacing: 12,
                      children: [
                        ElevatedButton(
                          key: const Key('landing-boton-login'),
                          onPressed: onComenzar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _naranja,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Comenzar Ahora',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: onConocerMas,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Conocer más',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Wrap(
                      spacing: 22,
                      runSpacing: 10,
                      children: [
                        _Destacado(
                          icono: Icons.how_to_reg_outlined,
                          texto: 'Inscripción en línea',
                        ),
                        _Destacado(
                          icono: Icons.fact_check_outlined,
                          texto: 'Asistencia digital',
                        ),
                        _Destacado(
                          icono: Icons.event_available_outlined,
                          texto: 'Horarios y cupos al día',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Destacado extends StatelessWidget {
  const _Destacado({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, color: _naranja, size: 20),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------ misión y visión

class _SeccionMisionVision extends StatelessWidget {
  const _SeccionMisionVision({super.key, required this.escritorio});

  final bool escritorio;

  static const _valores = [
    'Compromiso',
    'Trabajo en equipo',
    'Excelencia',
    'Inclusión',
    'Vida saludable',
  ];

  @override
  Widget build(BuildContext context) {
    const mision = _TarjetaProposito(
      icono: Icons.flag_outlined,
      titulo: 'Misión',
      color: _naranja,
      texto:
          'Promover la práctica deportiva en la comunidad de la Universidad '
          'Metropolitana, facilitando a estudiantes y entrenadores la '
          'inscripción, la organización de horarios y el seguimiento de la '
          'asistencia en una plataforma digital, accesible y confiable.',
    );
    const vision = _TarjetaProposito(
      icono: Icons.visibility_outlined,
      titulo: 'Visión',
      color: _azul,
      texto:
          'Ser la plataforma de referencia del deporte universitario en '
          'Venezuela, impulsando una comunidad unimetana más activa, '
          'saludable y conectada gracias a la tecnología.',
    );

    return _Contenido(
      child: Column(
        children: [
          const _TituloSeccion(
            etiqueta: 'Quiénes somos',
            titulo: 'Nuestra misión y visión',
            descripcion:
                'Samán Deportivo nace para que hacer deporte en la Unimet sea '
                'tan fácil como entrar a clase.',
          ),
          const SizedBox(height: 40),
          if (escritorio)
            const IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: mision),
                  SizedBox(width: 24),
                  Expanded(child: vision),
                ],
              ),
            )
          else
            const Column(
              children: [mision, SizedBox(height: 20), vision],
            ),
          const SizedBox(height: 36),
          const Text(
            'Nuestros valores',
            style: TextStyle(
              color: _azulOscuro,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final valor in _valores)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFDCE3EF)),
                  ),
                  child: Text(
                    valor,
                    style: const TextStyle(
                      color: _azul,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TarjetaProposito extends StatelessWidget {
  const _TarjetaProposito({
    required this.icono,
    required this.titulo,
    required this.texto,
    required this.color,
  });

  final IconData icono;
  final String titulo;
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 5, color: color),
          Padding(
            padding: const EdgeInsets.all(28),
            child: _ContenidoProposito(
              icono: icono,
              titulo: titulo,
              texto: texto,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContenidoProposito extends StatelessWidget {
  const _ContenidoProposito({
    required this.icono,
    required this.titulo,
    required this.texto,
    required this.color,
  });

  final IconData icono;
  final String titulo;
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icono, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            titulo,
            style: const TextStyle(
              color: _azulOscuro,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            texto,
            style: const TextStyle(color: _texto, fontSize: 16, height: 1.6),
          ),
        ],
    );
  }
}

// --------------------------------------------------------------- módulos

/// Un módulo de la plataforma. Si [rol] es `null` el módulo es público.
class _Modulo {
  const _Modulo({
    required this.clave,
    required this.icono,
    required this.titulo,
    required this.texto,
    required this.ruta,
    this.rol,
  });

  final String clave;
  final IconData icono;
  final String titulo;
  final String texto;
  final String ruta;
  final String? rol;
}

class _SeccionModulos extends StatelessWidget {
  const _SeccionModulos({
    super.key,
    required this.escritorio,
    required this.onAbrir,
  });

  final bool escritorio;
  final ValueChanged<_Modulo> onAbrir;

  static const _modulos = [
    _Modulo(
      clave: 'catalogo',
      icono: Icons.sports_soccer,
      titulo: 'Catálogo de disciplinas',
      texto: 'Busca por nombre, día de entrenamiento o cupos disponibles.',
      ruta: AppRoutes.buscador,
    ),
    _Modulo(
      clave: 'inscripciones',
      icono: Icons.how_to_reg,
      titulo: 'Inscripciones',
      texto: 'Consulta tus disciplinas e inscríbete desde tu panel.',
      ruta: AppRoutes.estudiante,
      rol: RolesUsuario.estudiante,
    ),
    _Modulo(
      clave: 'perfil',
      icono: Icons.person,
      titulo: 'Perfil del estudiante',
      texto: 'Tus datos, tu foto, tu saldo y el cambio de contraseña.',
      ruta: AppRoutes.perfilEstudiante,
      rol: RolesUsuario.estudiante,
    ),
    _Modulo(
      clave: 'asistencia',
      icono: Icons.fact_check,
      titulo: 'Control de asistencia',
      texto: 'Los entrenadores pasan lista y revisan el historial.',
      ruta: AppRoutes.entrenador,
      rol: RolesUsuario.entrenador,
    ),
    _Modulo(
      clave: 'admin',
      icono: Icons.admin_panel_settings,
      titulo: 'Panel administrativo',
      texto: 'Disciplinas, horarios, entrenadores y estudiantes.',
      ruta: AppRoutes.adminDashboard,
      rol: RolesUsuario.admin,
    ),
    _Modulo(
      clave: 'registro',
      icono: Icons.person_add_alt_1,
      titulo: 'Crea tu cuenta',
      texto: 'Regístrate con tu correo estudiantil de la Unimet.',
      ruta: AppRoutes.registro,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: _Contenido(
        child: Column(
          children: [
            const _TituloSeccion(
              etiqueta: 'La plataforma',
              titulo: 'Nuestros módulos principales',
              descripcion:
                  'Toca un módulo para entrar. Los que necesitan cuenta te '
                  'piden iniciar sesión primero.',
            ),
            const SizedBox(height: 40),
            LayoutBuilder(
              builder: (context, constraints) {
                final columnas = escritorio
                    ? 3
                    : (constraints.maxWidth >= 560 ? 2 : 1);
                const espacio = 20.0;
                final ancho =
                    (constraints.maxWidth - espacio * (columnas - 1)) /
                        columnas;
                return Wrap(
                  spacing: espacio,
                  runSpacing: espacio,
                  children: [
                    for (final modulo in _modulos)
                      SizedBox(
                        width: ancho,
                        child: _TarjetaModulo(
                          modulo: modulo,
                          onTap: () => onAbrir(modulo),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaModulo extends StatelessWidget {
  const _TarjetaModulo({required this.modulo, required this.onTap});

  final _Modulo modulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _fondo,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('modulo-${modulo.clave}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(modulo.icono, color: _azul, size: 36),
              const SizedBox(height: 14),
              Text(
                modulo.titulo,
                style: const TextStyle(
                  color: _azulOscuro,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                modulo.texto,
                style: const TextStyle(color: _gris, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    modulo.rol == null ? 'Entrar' : 'Entrar con mi cuenta',
                    style: const TextStyle(
                      color: _naranja,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, color: _naranja, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------- cómo funciona

class _SeccionPasos extends StatelessWidget {
  const _SeccionPasos({super.key, required this.escritorio});

  final bool escritorio;

  static const _pasos = [
    (
      'Crea tu cuenta',
      'Regístrate con tu correo institucional de la Unimet.',
    ),
    (
      'Explora las disciplinas',
      'Revisa horarios, lugares y cupos disponibles.',
    ),
    (
      'Inscríbete y entrena',
      'Asiste a tus entrenamientos y lleva tu asistencia al día.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tarjetas = [
      for (var i = 0; i < _pasos.length; i++)
        _TarjetaPaso(numero: i + 1, titulo: _pasos[i].$1, texto: _pasos[i].$2),
    ];
    return _Contenido(
      child: Column(
        children: [
          const _TituloSeccion(
            etiqueta: 'Cómo funciona',
            titulo: 'Empieza en tres pasos',
          ),
          const SizedBox(height: 40),
          if (escritorio)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < tarjetas.length; i++) ...[
                  if (i > 0) const SizedBox(width: 24),
                  Expanded(child: tarjetas[i]),
                ],
              ],
            )
          else
            Column(
              children: [
                for (var i = 0; i < tarjetas.length; i++) ...[
                  if (i > 0) const SizedBox(height: 16),
                  tarjetas[i],
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _TarjetaPaso extends StatelessWidget {
  const _TarjetaPaso({
    required this.numero,
    required this.titulo,
    required this.texto,
  });

  final int numero;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: _naranja,
          child: Text(
            '$numero',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: _azulOscuro,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                texto,
                style: const TextStyle(color: _gris, fontSize: 15, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------- llamado y pie

class _BandaLlamado extends StatelessWidget {
  const _BandaLlamado({required this.textoAcceder, required this.onAcceder});

  final String textoAcceder;
  final VoidCallback onAcceder;

  @override
  Widget build(BuildContext context) {
    return _Contenido(
      vertical: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_azulOscuro, _azul]),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            const Text(
              '¿Listo para empezar?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Entra con tu cuenta o crea una nueva en menos de un minuto.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFDDE5F3), fontSize: 16),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              key: const Key('landing-boton-acceder-final'),
              onPressed: onAcceder,
              style: ElevatedButton.styleFrom(
                backgroundColor: _naranja,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                textoAcceder,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PiePagina extends StatelessWidget {
  const _PiePagina();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 48),
      color: _azulOscuro,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: const Column(
        children: [
          Text(
            'Samán Deportivo · Universidad Metropolitana',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            '© 2026 · Grupo 5 · Sistemas de Información',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9FB0CC), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
