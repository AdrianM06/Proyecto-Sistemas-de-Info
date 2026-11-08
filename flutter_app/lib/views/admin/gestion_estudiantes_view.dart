import 'package:flutter/material.dart';

import '../../controllers/gestion_estudiantes_controller.dart';
import '../../models/usuario.dart';
import '../../services/gestion_estudiantes_service.dart';
import '../widgets/avatar_usuario.dart';

const _azul = Color(0xFF003B82);
const _naranja = Color(0xFFFF8C2A);

/// Gestión de estudiantes del panel del administrador
/// (ruta `/admin/estudiantes`, solo para el rol admin).
///
/// Lista a los estudiantes en tiempo real, con buscador, y un interruptor
/// para habilitarlos o deshabilitarlos (`users/{uid}.estadoActivo`). Un
/// estudiante deshabilitado puede iniciar sesión, pero no inscribirse.
class GestionEstudiantesView extends StatefulWidget {
  const GestionEstudiantesView({super.key, this.controller});

  /// Controlador para las pruebas. Por defecto se conecta a Firestore. La
  /// vista lo libera al cerrarse.
  final GestionEstudiantesController? controller;

  @override
  State<GestionEstudiantesView> createState() => _GestionEstudiantesViewState();
}

class _GestionEstudiantesViewState extends State<GestionEstudiantesView> {
  late final GestionEstudiantesController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        GestionEstudiantesController(datos: GestionEstudiantesService());
    _controller.iniciar();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _cambiar(Usuario estudiante, bool activo) async {
    final error = await _controller.cambiarEstado(estudiante, activo);
    if (!mounted) return;
    final mensaje =
        error ??
        (activo
            ? '${estudiante.nombreCompleto} quedó habilitado.'
            : '${estudiante.nombreCompleto} quedó deshabilitado. Puede '
                  'iniciar sesión, pero no inscribirse en disciplinas.');
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: error != null ? Colors.red[700] : null,
          content: Text(mensaje),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Estudiantes'),
        backgroundColor: _azul,
        foregroundColor: Colors.white,
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: _contenido(),
          ),
        ),
      ),
    );
  }

  Widget _contenido() {
    if (_controller.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_controller.error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _controller.iniciar,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_controller.cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    final estudiantes = _controller.estudiantes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            key: const Key('buscar-estudiante'),
            onChanged: _controller.buscar,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar por nombre, correo, carnet o cédula',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Habilitados: ${_controller.activos} · '
            'Deshabilitados: ${_controller.inactivos}',
            key: const Key('resumen-estudiantes'),
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Text(
            'Un estudiante deshabilitado puede iniciar sesión, pero no '
            'inscribirse en disciplinas.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
        Expanded(
          child: estudiantes.isEmpty
              ? Center(
                  key: const Key('sin-estudiantes'),
                  child: Text(
                    _controller.busqueda.trim().isEmpty
                        ? 'No hay estudiantes registrados.'
                        : 'Ningún estudiante coincide con la búsqueda.',
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: estudiantes.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _tarjeta(estudiantes[i]),
                ),
        ),
      ],
    );
  }

  Widget _tarjeta(Usuario estudiante) {
    final activo = _controller.estaActivo(estudiante);
    final guardando = _controller.guardando(estudiante.uid);
    return Card(
      key: Key('estudiante-${estudiante.uid}'),
      elevation: 1,
      child: SwitchListTile(
        key: Key('estado-${estudiante.uid}'),
        activeThumbColor: _naranja,
        value: activo,
        onChanged: guardando ? null : (valor) => _cambiar(estudiante, valor),
        secondary: Stack(
          clipBehavior: Clip.none,
          children: [
            AvatarUsuario(
              fotoUrl: estudiante.fotoUrl,
              iniciales: estudiante.iniciales,
              radio: 22,
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: Icon(
                activo ? Icons.check_circle : Icons.block,
                size: 18,
                color: activo ? Colors.green[700] : Colors.red[700],
              ),
            ),
          ],
        ),
        title: Text(
          estudiante.nombreCompleto,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Carnet: ${(estudiante.carnet ?? '').isEmpty ? 'S/C' : estudiante.carnet} · '
          'Cédula: ${(estudiante.cedula ?? '').isEmpty ? 'S/C' : estudiante.cedula}\n'
          '${guardando ? 'Guardando…' : (activo ? 'Habilitado' : 'Deshabilitado')}',
        ),
        isThreeLine: true,
      ),
    );
  }
}
