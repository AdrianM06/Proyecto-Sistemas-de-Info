import 'package:flutter/material.dart';

import 'estudiante/estudiante_scaffold.dart';

/// Inicio del estudiante (ruta `/estudiante`).
///
/// Usa [EstudianteScaffold]: el menú hamburguesa abre el menú lateral con
/// Inicio, Catálogo, Pagos, Mi perfil, Página principal y Cerrar sesión.
class StudentView extends StatelessWidget {
  const StudentView({
    super.key,
    this.onCerrarSesion,
    this.onAbrirPerfil,
    this.onIrACatalogo,
    this.onIrALanding,
    this.avatar,
  });

  /// Botón "Cerrar sesión" (barra superior y menú). Si es `null`, no aparece.
  final VoidCallback? onCerrarSesion;

  /// Foto de perfil de la barra superior y "Mi perfil" del menú.
  final VoidCallback? onAbrirPerfil;

  /// "Catálogo" del menú: abre el buscador de deportes.
  final VoidCallback? onIrACatalogo;

  /// "Página principal" del menú: vuelve a la Landing Page.
  final VoidCallback? onIrALanding;

  /// Foto de perfil que se muestra arriba a la derecha.
  final Widget? avatar;

  @override
  Widget build(BuildContext context) {
    return EstudianteScaffold(
      seccion: SeccionEstudiante.inicio,
      avatar: avatar,
      onCatalogo: onIrACatalogo,
      // El saldo y los pagos se consultan en el perfil.
      onPagos: onAbrirPerfil,
      onPerfil: onAbrirPerfil,
      onPaginaPrincipal: onIrALanding,
      onCerrarSesion: onCerrarSesion,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fecha de entrenamiento próximo',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Card(
                  color: Colors.white,
                  child: Container(
                    height: 250,
                    alignment: Alignment.center,
                    child: const Text('Calendario interactivo: Octubre 2026'),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Disciplinas',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Card(
                  color: Colors.white,
                  child: ListTile(
                    leading: Icon(
                      Icons.check_circle,
                      color: Colors.blue[900],
                      size: 40,
                    ),
                    title: const Text(
                      'Estás inscrito en',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    subtitle: Text(
                      'Fútbol campo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (onIrACatalogo != null)
                  OutlinedButton.icon(
                    key: const Key('inicio-ver-catalogo'),
                    onPressed: onIrACatalogo,
                    icon: const Icon(Icons.search),
                    label: const Text('Explorar el catálogo de disciplinas'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
