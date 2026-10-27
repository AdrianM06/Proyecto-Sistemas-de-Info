import 'package:flutter/material.dart';

import '../../controllers/perfil_estudiante_controller.dart';
import '../../services/perfil_estudiante_service.dart';
import '../../utils/formato_moneda.dart';

/// Página de perfil del estudiante (ruta `/estudiante/perfil`).
///
/// Mantiene el diseño de la vista del estudiante: barra superior blanca con
/// "UNIMET SPORTS", menú lateral con los botones azules (Inicio, Catálogo,
/// Pagos) y, al centro, tres tarjetas blancas: "Perfil", "Saldo en cuenta"
/// y "Retirar disciplina".
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
  static final Color _azul = Colors.blue[900]!;

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

  Future<void> _abrirCambioDeClave() async {
    _controller.prepararCambioDeClave();
    final cambiada = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DialogoCambiarClave(controller: _controller),
    );
    if (cambiada == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green[700],
          content: Text(
            _controller.mensajeExito ?? '¡Tu contraseña se cambió con éxito!',
          ),
        ),
      );
    }
  }

  Future<void> _confirmarRetiro(DisciplinaInscrita disciplina) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('Retirar disciplina'),
        content: Text(
          '¿Seguro que quieres retirarte de ${disciplina.nombre}? '
          'Perderás tu cupo en la disciplina.',
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
    final retirada = await _controller.retirarDisciplina(disciplina);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: retirada ? Colors.green[700] : Colors.red[700],
        content: Text(
          retirada
              ? 'Te retiraste de ${disciplina.nombre}.'
              : (_controller.error ?? 'No se pudo retirar la disciplina.'),
        ),
      ),
    );
  }

  void _proximamente(String seccion) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$seccion estará disponible pronto.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: const Icon(Icons.menu, color: Colors.black),
        title: const Text(
          'UNIMET SPORTS',
          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            key: const Key('avatar-perfil'),
            tooltip: 'Mi perfil',
            onPressed: null,
            icon: Icon(Icons.person, color: _azul, size: 30),
          ),
          if (widget.onCerrarSesion != null)
            IconButton(
              key: const Key('boton-cerrar-sesion'),
              tooltip: 'Cerrar sesión',
              onPressed: widget.onCerrarSesion,
              icon: const Icon(Icons.logout, color: Colors.black),
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 150,
            padding: const EdgeInsets.only(top: 20),
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
                  widget.onIrACatalogo ?? () => _proximamente('El catálogo'),
                ),
                _botonLateral('Pagos', () => _proximamente('Pagos')),
              ],
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) => _contenido(),
            ),
          ),
        ],
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
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const separacion = 20.0;
          final columnas = constraints.maxWidth >= 900 ? 3 : 1;
          final ancho =
              (constraints.maxWidth - separacion * (columnas - 1)) / columnas;
          return Wrap(
            spacing: separacion,
            runSpacing: separacion,
            children: [
              SizedBox(width: ancho, child: _tarjetaPerfil(perfil)),
              SizedBox(width: ancho, child: _tarjetaSaldo(perfil)),
              SizedBox(width: ancho, child: _tarjetaRetirar(perfil)),
            ],
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------------- tarjetas

  Widget _tarjetaPerfil(PerfilEstudiante perfil) {
    final usuario = perfil.usuario;
    final exito = _controller.mensajeExito;
    return _Tarjeta(
      key: const Key('tarjeta-perfil'),
      titulo: 'Perfil',
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: _azul,
              child: Text(
                usuario.iniciales,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usuario.nombreCompleto,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _azul,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Estudiante',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Dato(etiqueta: 'Correo', valor: usuario.email),
        _Dato(etiqueta: 'Carnet', valor: usuario.carnet ?? 'No registrado'),
        if ((usuario.carrera ?? '').isNotEmpty)
          _Dato(etiqueta: 'Carrera', valor: usuario.carrera!),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            key: const Key('boton-cambiar-clave'),
            onPressed: _abrirCambioDeClave,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Cambiar clave',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
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
        const SizedBox(height: 8),
        Text(
          formatoBolivares(perfil.saldo),
          key: const Key('saldo-cuenta'),
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: _azul,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Saldo disponible para el pago de disciplinas.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _tarjetaRetirar(PerfilEstudiante perfil) {
    return _Tarjeta(
      key: const Key('tarjeta-retirar'),
      titulo: 'Retirar disciplina',
      children: [
        if (perfil.disciplinas.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No estás inscrito en ninguna disciplina.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          for (final disciplina in perfil.disciplinas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: _azul),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      disciplina.nombre,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  OutlinedButton(
                    key: Key('retirar-${disciplina.inscripcionId}'),
                    onPressed: _controller.retirando == null
                        ? () => _confirmarRetiro(disciplina)
                        : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                      side: BorderSide(color: Colors.red[700]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _controller.retirando == disciplina.inscripcionId
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Retirar'),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Widget _botonLateral(String titulo, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
      child: ElevatedButton(
        key: Key('menu-$titulo'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _azul,
          minimumSize: const Size(double.infinity, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: onPressed,
        child: Text(titulo, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

/// Tarjeta blanca con título, como las de la vista del estudiante.
class _Tarjeta extends StatelessWidget {
  const _Tarjeta({super.key, required this.titulo, required this.children});

  final String titulo;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              etiqueta,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(child: Text(valor, style: const TextStyle(fontSize: 13))),
        ],
      ),
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
              style: FilledButton.styleFrom(backgroundColor: Colors.orange),
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
