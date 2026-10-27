import 'package:flutter/material.dart';

import '../../controllers/perfil_estudiante_controller.dart';
import '../../services/perfil_estudiante_service.dart';
import '../../utils/formato_moneda.dart';

// Colores del diseño "Perfil Estudiante".
const _fondo = Color(0xFFF0F0F5);
const _azul = Color(0xFF003087);
const _naranja = Color(0xFFFF8C2A);
const _grisCaja = Color(0xFFF2F2F7);
const _grisTexto = Color(0xFF6B6B78);

/// Página de perfil del estudiante (ruta `/estudiante/perfil`).
///
/// Sigue el diseño "Perfil Estudiante": barra superior con el menú, el logo
/// de UNIMET Sports y la foto de perfil; menú lateral con los botones azules
/// (Inicio, Catálogo, Pagos) y tres tarjetas blancas: "Perfil" (Cambiar
/// clave), "Saldo en cuenta" (Bs. 00,00) y "Retirar disciplina".
class PerfilEstudianteView extends StatefulWidget {
  const PerfilEstudianteView({
    super.key,
    required this.controller,
    this.onCerrarSesion,
    this.onIrAInicio,
    this.onIrACatalogo,
  });

  /// Página conectada a Firebase.
  factory PerfilEstudianteView.conFirebase({
    Key? key,
    VoidCallback? onCerrarSesion,
    VoidCallback? onIrAInicio,
    VoidCallback? onIrACatalogo,
  }) {
    return PerfilEstudianteView(
      key: key,
      controller: PerfilEstudianteController(datos: PerfilEstudianteService()),
      onCerrarSesion: onCerrarSesion,
      onIrAInicio: onIrAInicio,
      onIrACatalogo: onIrACatalogo,
    );
  }

  /// La página libera este controlador al cerrarse.
  final PerfilEstudianteController controller;
  final VoidCallback? onCerrarSesion;
  final VoidCallback? onIrAInicio;
  final VoidCallback? onIrACatalogo;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondo,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _barraSuperior(),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _menuLateral(),
                  Expanded(
                    child: ListenableBuilder(
                      listenable: _controller,
                      builder: (context, _) => _contenido(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------- estructura

  Widget _barraSuperior() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            color: Colors.white,
            child: const Icon(Icons.menu, color: Colors.black54, size: 28),
          ),
          const SizedBox(width: 18),
          Image.asset(
            'assets/images/unimet_sports_logo.png',
            height: 46,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Text(
              'UNIMET SPORTS',
              style: TextStyle(color: _naranja, fontWeight: FontWeight.bold),
            ),
          ),
          const Spacer(),
          Tooltip(
            message: 'Mi perfil',
            child: Container(
              key: const Key('avatar-perfil'),
              width: 38,
              height: 38,
              color: const Color(0xFFE0E0E0),
              child: const Icon(Icons.person, color: Colors.grey, size: 32),
            ),
          ),
          if (widget.onCerrarSesion != null) ...[
            const SizedBox(width: 6),
            IconButton(
              key: const Key('boton-cerrar-sesion'),
              tooltip: 'Cerrar sesión',
              onPressed: widget.onCerrarSesion,
              icon: const Icon(Icons.logout, color: Colors.black),
            ),
          ],
        ],
      ),
    );
  }

  Widget _menuLateral() {
    return SizedBox(
      width: 150,
      child: Padding(
        padding: const EdgeInsets.only(left: 18, right: 14),
        child: Column(
          children: [
            _botonLateral(
              'Inicio',
              widget.onIrAInicio ??
                  () {
                    Navigator.of(context).maybePop();
                  },
            ),
            _botonLateral(
              'Catálogo',
              widget.onIrACatalogo ??
                  () => _avisar('El catálogo estará disponible pronto.'),
            ),
            _botonLateral(
              'Pagos',
              () => _avisar('Pagos estará disponible pronto.'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botonLateral(String titulo, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        height: 30,
        child: ElevatedButton(
          key: Key('menu-$titulo'),
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _azul,
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: const StadiumBorder(),
          ),
          child: Text(
            titulo,
            style: const TextStyle(color: Colors.white, fontSize: 17),
          ),
        ),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 0, 20, 24),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _tarjetaPerfil(),
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

  Widget _tarjetaPerfil() {
    final exito = _controller.mensajeExito;
    return _Tarjeta(
      key: const Key('tarjeta-perfil'),
      titulo: 'Perfil',
      children: [
        const SizedBox(height: 22),
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
