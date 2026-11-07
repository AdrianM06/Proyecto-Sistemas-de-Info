import 'package:flutter/material.dart';

import '../../utils/imagenes.dart';

const _azul = Color(0xFF003087);
const _naranja = Color(0xFFFF8C2A);

/// Secciones del menú del estudiante.
enum SeccionEstudiante { inicio, catalogo, pagos, perfil }

/// Estructura común de las pantallas del estudiante (Inicio y Perfil).
///
/// - Barra superior: botón de menú (hamburguesa), logo, foto de perfil y
///   cerrar sesión.
/// - Menú lateral desplegable (Drawer) con Inicio, Catálogo, Pagos,
///   Mi perfil, Página principal y Cerrar sesión.
///
/// Como el Inicio y el Perfil usan la misma barra y el mismo menú, pasar de
/// una pantalla a la otra no mueve ni rompe el diseño.
class EstudianteScaffold extends StatelessWidget {
  const EstudianteScaffold({
    super.key,
    required this.seccion,
    required this.body,
    this.avatar,
    this.onInicio,
    this.onCatalogo,
    this.onPagos,
    this.onPerfil,
    this.onPaginaPrincipal,
    this.onCerrarSesion,
  });

  /// Sección que se está viendo (queda resaltada en el menú).
  final SeccionEstudiante seccion;
  final Widget body;

  /// Foto de perfil de la barra superior. Si es `null` se ve un ícono.
  final Widget? avatar;

  final VoidCallback? onInicio;
  final VoidCallback? onCatalogo;
  final VoidCallback? onPagos;
  final VoidCallback? onPerfil;

  /// Vuelve a la Landing Page sin cerrar la sesión.
  final VoidCallback? onPaginaPrincipal;
  final VoidCallback? onCerrarSesion;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 4,
        leading: Builder(
          builder: (context) => IconButton(
            key: const Key('boton-menu'),
            tooltip: 'Menú',
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Image.asset(
          'assets/images/unimet_sports_logo.png',
          height: 40,
          cacheHeight: pixelesFisicos(context, 40),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Text(
            'UNIMET SPORTS',
            style: TextStyle(color: _naranja, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          IconButton(
            key: const Key('avatar-perfil'),
            tooltip: 'Mi perfil',
            onPressed: onPerfil,
            icon: avatar ??
                const Icon(Icons.account_circle, color: Colors.grey, size: 32),
          ),
          if (onCerrarSesion != null)
            IconButton(
              key: const Key('boton-cerrar-sesion'),
              tooltip: 'Cerrar sesión',
              onPressed: onCerrarSesion,
              icon: const Icon(Icons.logout, color: Colors.black87),
            ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _MenuEstudiante(
        seccion: seccion,
        onInicio: onInicio,
        onCatalogo: onCatalogo,
        onPagos: onPagos,
        onPerfil: onPerfil,
        onPaginaPrincipal: onPaginaPrincipal,
        onCerrarSesion: onCerrarSesion,
      ),
      body: SafeArea(top: false, child: body),
    );
  }
}

class _MenuEstudiante extends StatelessWidget {
  const _MenuEstudiante({
    required this.seccion,
    this.onInicio,
    this.onCatalogo,
    this.onPagos,
    this.onPerfil,
    this.onPaginaPrincipal,
    this.onCerrarSesion,
  });

  final SeccionEstudiante seccion;
  final VoidCallback? onInicio;
  final VoidCallback? onCatalogo;
  final VoidCallback? onPagos;
  final VoidCallback? onPerfil;
  final VoidCallback? onPaginaPrincipal;
  final VoidCallback? onCerrarSesion;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      key: const Key('menu-estudiante'),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: _azul,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.paddingOf(context).top + 24,
              20,
              20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset(
                    'assets/images/unimet_sports_logo.png',
                    height: 44,
                    cacheHeight: pixelesFisicos(context, 44),
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.sports, color: _naranja),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Samán Deportivo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _item(
                  context,
                  titulo: 'Inicio',
                  icono: Icons.home_outlined,
                  seleccionado: seccion == SeccionEstudiante.inicio,
                  onTap: onInicio,
                ),
                _item(
                  context,
                  titulo: 'Catálogo',
                  icono: Icons.sports_soccer_outlined,
                  seleccionado: seccion == SeccionEstudiante.catalogo,
                  onTap: onCatalogo,
                ),
                _item(
                  context,
                  titulo: 'Pagos',
                  icono: Icons.account_balance_wallet_outlined,
                  seleccionado: seccion == SeccionEstudiante.pagos,
                  onTap: onPagos,
                ),
                _item(
                  context,
                  titulo: 'Mi perfil',
                  icono: Icons.person_outline,
                  seleccionado: seccion == SeccionEstudiante.perfil,
                  onTap: onPerfil,
                ),
                const Divider(),
                _item(
                  context,
                  titulo: 'Página principal',
                  icono: Icons.public,
                  seleccionado: false,
                  onTap: onPaginaPrincipal,
                ),
                if (onCerrarSesion != null)
                  _item(
                    context,
                    titulo: 'Cerrar sesión',
                    icono: Icons.logout,
                    seleccionado: false,
                    onTap: onCerrarSesion,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required String titulo,
    required IconData icono,
    required bool seleccionado,
    VoidCallback? onTap,
  }) {
    return ListTile(
      key: Key('menu-$titulo'),
      leading: Icon(icono, color: seleccionado ? _naranja : _azul),
      title: Text(
        titulo,
        style: TextStyle(
          color: _azul,
          fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: seleccionado,
      selectedTileColor: _naranja.withValues(alpha: 0.12),
      enabled: onTap != null || seleccionado,
      onTap: () {
        Navigator.of(context).pop(); // Cierra el menú.
        if (!seleccionado) onTap?.call();
      },
    );
  }
}
