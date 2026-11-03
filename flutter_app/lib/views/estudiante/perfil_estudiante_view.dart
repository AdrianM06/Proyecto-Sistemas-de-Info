import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/perfil_estudiante_controller.dart';
import '../../services/foto_perfil_service.dart';
import '../../services/perfil_estudiante_service.dart';
import '../../utils/formato_moneda.dart';
import '../widgets/avatar_usuario.dart';
import 'editar_datos_estudiante_dialog.dart';
import 'estudiante_scaffold.dart';

// Colores del diseño "Perfil Estudiante".
const _azul = Color(0xFF003087);
const _naranja = Color(0xFFFF8C2A);
const _grisCaja = Color(0xFFF2F2F7);
const _grisTexto = Color(0xFF6B6B78);

/// Página de perfil del estudiante (ruta `/estudiante/perfil`).
///
/// Usa la misma barra y el mismo menú hamburguesa que el Inicio
/// ([EstudianteScaffold]) y muestra tres tarjetas blancas: "Perfil" (foto,
/// datos, Editar datos y Cambiar clave), "Saldo en cuenta" (Bs. 00,00) y
/// "Retirar disciplina".
class PerfilEstudianteView extends StatefulWidget {
  const PerfilEstudianteView({
    super.key,
    required this.controller,
    this.onCerrarSesion,
    this.onIrAInicio,
    this.onIrACatalogo,
    this.onIrALanding,
  });

  /// Página conectada a Firebase.
  factory PerfilEstudianteView.conFirebase({
    Key? key,
    VoidCallback? onCerrarSesion,
    VoidCallback? onIrAInicio,
    VoidCallback? onIrACatalogo,
    VoidCallback? onIrALanding,
  }) {
    return PerfilEstudianteView(
      key: key,
      controller: PerfilEstudianteController(datos: PerfilEstudianteService()),
      onCerrarSesion: onCerrarSesion,
      onIrAInicio: onIrAInicio,
      onIrACatalogo: onIrACatalogo,
      onIrALanding: onIrALanding,
    );
  }

  /// La página libera este controlador al cerrarse.
  final PerfilEstudianteController controller;
  final VoidCallback? onCerrarSesion;
  final VoidCallback? onIrAInicio;
  final VoidCallback? onIrACatalogo;
  final VoidCallback? onIrALanding;

  @override
  State<PerfilEstudianteView> createState() => _PerfilEstudianteViewState();
}

class _PerfilEstudianteViewState extends State<PerfilEstudianteView> {
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: color, content: Text(texto)),
    );
  }

  Future<void> _abrirCambioDeClave() async {
    _controller.prepararCambioDeClave();
    final cambiada = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DialogoCambiarClave(controller: _controller),
    );
    if (cambiada == true && mounted) {
      _avisar(
        _controller.mensajeExito ?? '¡Tu contraseña se cambió con éxito!',
        color: Colors.green[700],
      );
    }
  }

  Future<void> _abrirRetiro() async {
    final disciplinas = _controller.perfil?.disciplinas ?? const [];
    if (disciplinas.isEmpty) {
      _avisar('No estás inscrito en ninguna disciplina.');
      return;
    }

    final elegida = await showDialog<DisciplinaInscrita>(
      context: context,
      builder: (contextoDialogo) => SimpleDialog(
        key: const Key('dialogo-retirar'),
        title: const Text('¿De qué disciplina te quieres retirar?'),
        children: [
          for (final disciplina in disciplinas)
            SimpleDialogOption(
              key: Key('opcion-${disciplina.inscripcionId}'),
              onPressed: () => Navigator.of(contextoDialogo).pop(disciplina),
              child: Row(
                children: [
                  const Icon(Icons.sports, color: _azul),
                  const SizedBox(width: 10),
                  Expanded(child: Text(disciplina.nombre)),
                ],
              ),
            ),
        ],
      ),
    );
    if (elegida == null || !mounted) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('Retirar disciplina'),
        content: Text(
          '¿Seguro que quieres cancelar tu inscripción en ${elegida.nombre}? '
          'Perderás tu cupo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contextoDialogo).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirmar-retiro'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () => Navigator.of(contextoDialogo).pop(true),
            child: const Text('Retirarme'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final retirada = await _controller.retirarDisciplina(elegida);
    if (!mounted) return;
    _avisar(
      retirada
          ? 'Te retiraste de ${elegida.nombre}.'
          : (_controller.error ?? 'No se pudo retirar la disciplina.'),
      color: retirada ? Colors.green[700] : Colors.red[700],
    );
  }

  Future<void> _abrirEdicion() async {
    final usuario = _controller.perfil?.usuario;
    if (usuario == null) return;
    final guardado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditarDatosEstudianteDialog(
        nombreActual: usuario.nombre,
        apellidoActual: usuario.apellido,
        cedulaActual: usuario.cedula ?? '',
        carnetActual: usuario.carnet ?? '',
        onGuardar: (nombre, apellido) =>
            _controller.actualizarDatos(nombre: nombre, apellido: apellido),
      ),
    );
    if (guardado == true && mounted) {
      _avisar('Tus datos se guardaron.', color: Colors.green[700]);
    }
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
      _avisar('No se pudo abrir el selector de imágenes.', color: Colors.red[700]);
      return;
    }
    if (archivo == null || !mounted) return;
    final bytes = await archivo.readAsBytes();
    final tipo = archivo.mimeType ?? FotoPerfilService.tipoDesdeNombre(archivo.name);
    final error = await _controller.cambiarFoto(bytes, tipo: tipo);
    if (!mounted) return;
    _avisar(
      error ?? '¡Tu foto de perfil se actualizó!',
      color: error == null ? Colors.green[700] : Colors.red[700],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final usuario = _controller.perfil?.usuario;
        return EstudianteScaffold(
          seccion: SeccionEstudiante.perfil,
          avatar: AvatarUsuario(
            fotoUrl: usuario?.fotoUrl,
            iniciales: usuario?.iniciales ?? '',
          ),
          onInicio: widget.onIrAInicio ?? () => Navigator.of(context).maybePop(),
          onCatalogo: widget.onIrACatalogo ??
              () => _avisar('El catálogo estará disponible pronto.'),
          onPagos: () => _avisar(
            'Tu saldo está en "Saldo en cuenta". Los pagos en línea '
            'estarán disponibles pronto.',
          ),
          onPaginaPrincipal: widget.onIrALanding,
          onCerrarSesion: widget.onCerrarSesion,
          body: _contenido(),
        );
      },
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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _tarjetaPerfil(perfil),
              const SizedBox(height: 32),
              _tarjetaSaldo(perfil),
              const SizedBox(height: 32),
              _tarjetaRetirar(),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- tarjetas

  Widget _tarjetaPerfil(PerfilEstudiante perfil) {
    final exito = _controller.mensajeExito;
    final usuario = perfil.usuario;
    return _Tarjeta(
      key: const Key('tarjeta-perfil'),
      titulo: 'Perfil',
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Stack(
              children: [
                AvatarUsuario(
                  key: const Key('foto-perfil'),
                  fotoUrl: usuario.fotoUrl,
                  iniciales: usuario.iniciales,
                  radio: 40,
                ),
                if (_controller.subiendoFoto)
                  const Positioned.fill(
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
                    style: const TextStyle(color: _grisTexto, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    key: const Key('boton-cambiar-foto'),
                    onPressed: _controller.subiendoFoto ? null : _cambiarFoto,
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: const Text('Cambiar foto'),
                    style: TextButton.styleFrom(
                      foregroundColor: _azul,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 24,
          runSpacing: 8,
          children: [
            _DatoBloqueado(
              key: const Key('perfil-carnet'),
              etiqueta: 'Carnet',
              valor: usuario.carnet ?? 'Sin registrar',
            ),
            _DatoBloqueado(
              key: const Key('perfil-cedula'),
              etiqueta: 'Cédula',
              valor: usuario.cedula ?? 'Sin registrar',
            ),
          ],
        ),
        const SizedBox(height: 18),
        _AccionConDescripcion(
          botonKey: const Key('boton-editar-datos'),
          textoBoton: 'Editar datos',
          descripcion: 'Cambia tu nombre y apellido',
          cargando: _controller.guardandoDatos,
          onPressed: _abrirEdicion,
        ),
        const SizedBox(height: 14),
        _AccionConDescripcion(
          botonKey: const Key('boton-cambiar-clave'),
          textoBoton: 'Cambiar clave',
          descripcion: 'Cambia la contraseña de usuario',
          onPressed: _abrirCambioDeClave,
        ),
        if (exito != null) ...[
          const SizedBox(height: 10),
          Row(
            key: const Key('mensaje-clave-cambiada'),
            children: [
              Icon(Icons.check_circle, color: Colors.green[700], size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(exito, style: TextStyle(color: Colors.green[700])),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _tarjetaSaldo(PerfilEstudiante perfil) {
    return _Tarjeta(
      key: const Key('tarjeta-saldo'),
      titulo: 'Saldo en cuenta',
      children: [
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: _grisCaja,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo adeudado',
                      style: TextStyle(color: _grisTexto, fontSize: 12),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Moneda: Bs.',
                      style: TextStyle(color: _grisTexto, fontSize: 8),
                    ),
                  ],
                ),
              ),
              Text(
                formatoBolivares(perfil.saldo),
                key: const Key('saldo-cuenta'),
                style: const TextStyle(
                  color: _azul,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tarjetaRetirar() {
    return _Tarjeta(
      key: const Key('tarjeta-retirar'),
      titulo: 'Retirar disciplina',
      children: [
        const SizedBox(height: 10),
        _AccionConDescripcion(
          botonKey: const Key('boton-retirar-disciplina'),
          textoBoton: 'Retirar disciplina',
          descripcion: 'Cancela la inscripción a una disciplina deportiva',
          cargando: _controller.retirando != null,
          onPressed: _abrirRetiro,
        ),
      ],
    );
  }
}

/// Dato que no se puede editar (carnet o cédula), con un candado.
class _DatoBloqueado extends StatelessWidget {
  const _DatoBloqueado({super.key, required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.lock_outline, size: 14, color: _grisTexto),
        const SizedBox(width: 4),
        Text(
          '$etiqueta: ',
          style: const TextStyle(color: _grisTexto, fontSize: 12),
        ),
        Flexible(
          child: Text(
            valor,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// Tarjeta blanca con título del diseño "Perfil Estudiante".
class _Tarjeta extends StatelessWidget {
  const _Tarjeta({super.key, required this.titulo, required this.children});

  final String titulo;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          ...children,
        ],
      ),
    );
  }
}

/// Botón naranja redondeado con su descripción al lado.
class _AccionConDescripcion extends StatelessWidget {
  const _AccionConDescripcion({
    required this.botonKey,
    required this.textoBoton,
    required this.descripcion,
    required this.onPressed,
    this.cargando = false,
  });

  final Key botonKey;
  final String textoBoton;
  final String descripcion;
  final VoidCallback onPressed;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          height: 30,
          child: ElevatedButton(
            key: botonKey,
            onPressed: cargando ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: _naranja,
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: const StadiumBorder(),
            ),
            child: cargando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(textoBoton, style: const TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(width: 22),
        Expanded(
          child: Text(descripcion, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}

/// Formulario para cambiar la contraseña.
class _DialogoCambiarClave extends StatefulWidget {
  const _DialogoCambiarClave({required this.controller});

  final PerfilEstudianteController controller;

  @override
  State<_DialogoCambiarClave> createState() => _DialogoCambiarClaveState();
}

class _DialogoCambiarClaveState extends State<_DialogoCambiarClave> {
  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _confirmacion = TextEditingController();
  bool _mostrar = false;

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final navigator = Navigator.of(context);
    final cambiada = await widget.controller.cambiarContrasena(
      actual: _actual.text,
      nueva: _nueva.text,
      confirmacion: _confirmacion.text,
    );
    if (cambiada && mounted) navigator.pop(true);
  }

  InputDecoration _decoracion(String etiqueta) {
    return InputDecoration(
      labelText: etiqueta,
      border: const OutlineInputBorder(),
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final ocupado = widget.controller.cambiandoClave;
        final error = widget.controller.errorClave;
        return AlertDialog(
          key: const Key('dialogo-cambiar-clave'),
          title: const Text('Cambiar clave'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const Key('clave-actual'),
                  controller: _actual,
                  enabled: !ocupado,
                  obscureText: !_mostrar,
                  decoration: _decoracion('Contraseña actual'),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('clave-nueva'),
                  controller: _nueva,
                  enabled: !ocupado,
                  obscureText: !_mostrar,
                  decoration: _decoracion('Nueva contraseña'),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('clave-confirmar'),
                  controller: _confirmacion,
                  enabled: !ocupado,
                  obscureText: !_mostrar,
                  decoration: _decoracion('Confirmar nueva contraseña'),
                  onSubmitted: (_) => ocupado ? null : _guardar(),
                ),
                const SizedBox(height: 4),
                CheckboxListTile(
                  value: _mostrar,
                  onChanged: ocupado
                      ? null
                      : (valor) => setState(() => _mostrar = valor ?? false),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Mostrar contraseñas'),
                ),
                const Text(
                  'Mínimo 8 caracteres, con al menos una mayúscula y un número.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    error,
                    key: const Key('error-clave'),
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: ocupado ? null : () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: const Key('guardar-clave'),
              style: FilledButton.styleFrom(backgroundColor: _naranja),
              onPressed: ocupado ? null : _guardar,
              child: ocupado
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }
}
