import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/perfil_estudiante_controller.dart';
import '../services/auth_service.dart';
import '../services/foto_perfil_service.dart';
import '../services/perfil_estudiante_service.dart';
import 'estudiante/perfil_estudiante_view.dart' show DialogoCambiarClave;
import 'theme/saman_colors.dart';
import 'widgets/avatar_usuario.dart';

/// Perfil de una cuenta del personal: entrenador (ruta `/entrenador/perfil`)
/// o administrador (ruta `/admin/perfil`).
///
/// Reutiliza [PerfilEstudianteController], así la subida de la foto y el
/// cambio de contraseña funcionan igual que en el perfil del estudiante.
///
/// El botón "Cambiar clave" solo aparece si la cuenta **no** es de
/// administrador. El rol sale de `users/{uid}.rol` (el que cargó el
/// controlador), no de un parámetro de la pantalla.
class PerfilCuentaView extends StatefulWidget {
  const PerfilCuentaView({
    super.key,
    required this.controller,
    this.onCerrarSesion,
    this.onIrALanding,
  });

  /// Pantalla conectada a Firebase.
  factory PerfilCuentaView.conFirebase({
    Key? key,
    VoidCallback? onCerrarSesion,
    VoidCallback? onIrALanding,
  }) {
    return PerfilCuentaView(
      key: key,
      controller: PerfilEstudianteController(datos: PerfilEstudianteService()),
      onCerrarSesion: onCerrarSesion,
      onIrALanding: onIrALanding,
    );
  }

  /// La pantalla libera este controlador al cerrarse.
  final PerfilEstudianteController controller;
  final VoidCallback? onCerrarSesion;
  final VoidCallback? onIrALanding;

  @override
  State<PerfilCuentaView> createState() => _PerfilCuentaViewState();
}

class _PerfilCuentaViewState extends State<PerfilCuentaView> {
  PerfilEstudianteController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.iniciar();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _avisar(String texto, {Color? color}) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(backgroundColor: color, content: Text(texto)));
  }

  Future<void> _cambiarFoto() async {
    XFile? archivo;
    try {
      archivo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
    } catch (e) {
      _avisar(
        'No se pudo abrir el selector de imágenes.',
        color: Colors.red[700],
      );
      return;
    }
    if (archivo == null || !mounted) return;

    String? error;
    try {
      final bytes = await archivo.readAsBytes();
      final tipo =
          archivo.mimeType ?? FotoPerfilService.tipoDesdeNombre(archivo.name);
      error = await _controller.cambiarFoto(bytes, tipo: tipo);
    } catch (e) {
      error = 'No se pudo leer la imagen. Elige otra e intenta de nuevo.';
    }
    if (!mounted) return;
    _avisar(
      error ?? '¡Tu foto de perfil se actualizó!',
      color: error == null ? Colors.green[700] : Colors.red[700],
    );
  }

  Future<void> _abrirCambioDeClave() async {
    if (_controller.esAdmin) return;
    _controller.prepararCambioDeClave();
    final cambiada = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DialogoCambiarClave(controller: _controller),
    );
    if (cambiada == true && mounted) {
      _avisar(
        _controller.mensajeExito ?? '¡Tu contraseña se cambió con éxito!',
        color: Colors.green[700],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SamanColors.niebla,
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          if (widget.onIrALanding != null)
            IconButton(
              key: const Key('boton-ir-landing'),
              tooltip: 'Página principal',
              onPressed: widget.onIrALanding,
              icon: const Icon(Icons.home_outlined),
            ),
          if (widget.onCerrarSesion != null)
            IconButton(
              key: const Key('boton-cerrar-sesion'),
              tooltip: 'Cerrar sesión',
              onPressed: widget.onCerrarSesion,
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => _contenido(),
      ),
    );
  }

  Widget _contenido() {
    final perfil = _controller.perfil;
    if (_controller.cargando && perfil == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (perfil == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _controller.error ?? 'No se pudo cargar tu perfil.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _controller.recargar,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final usuario = perfil.usuario;
    final previa = _controller.vistaPreviaFoto;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            key: const Key('tarjeta-perfil-cuenta'),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        if (previa != null)
                          CircleAvatar(
                            key: const Key('foto-perfil'),
                            radius: 40,
                            backgroundImage: MemoryImage(previa),
                          )
                        else
                          AvatarUsuario(
                            key: const Key('foto-perfil'),
                            fotoUrl: usuario.fotoUrl,
                            iniciales: usuario.iniciales,
                            radio: 40,
                          ),
                        if (_controller.subiendoFoto)
                          const SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                      ],
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            usuario.nombreCompleto,
                            key: const Key('perfil-nombre'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            usuario.email,
                            style: const TextStyle(
                              color: SamanColors.neutro500,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            key: const Key('perfil-rol'),
                            RolesUsuario.nombreVisible(usuario.rol.name),
                            style: const TextStyle(
                              color: SamanColors.azul,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            key: const Key('boton-cambiar-foto'),
                            onPressed: _controller.subiendoFoto
                                ? null
                                : _cambiarFoto,
                            icon: const Icon(
                              Icons.photo_camera_outlined,
                              size: 18,
                            ),
                            label: const Text('Cambiar foto'),
                            style: TextButton.styleFrom(
                              foregroundColor: SamanColors.azul,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!_controller.esAdmin) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      SizedBox(
                        height: 30,
                        child: ElevatedButton(
                          key: const Key('boton-cambiar-clave'),
                          onPressed: _abrirCambioDeClave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SamanColors.naranja,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text(
                            'Cambiar clave',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 22),
                      const Expanded(
                        child: Text(
                          'Cambia la contraseña de usuario',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
