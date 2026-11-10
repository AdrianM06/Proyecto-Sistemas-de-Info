import 'package:flutter/material.dart';

import '../../controllers/gestion_entrenadores_controller.dart';
import '../../models/deporte.dart';
import '../../models/usuario.dart';
import '../../services/gestion_entrenadores_service.dart';
import '../widgets/avatar_usuario.dart';

const _azul = Color(0xFF003B82);
const _naranja = Color(0xFFF58220);

/// Gestión de entrenadores del panel del administrador
/// (ruta `/admin/entrenadores`, solo para el rol admin).
///
/// Lista a todos los entrenadores con las disciplinas que tienen asignadas, en
/// tiempo real, y permite asignar o revocar disciplinas.
class GestionEntrenadoresView extends StatefulWidget {
  const GestionEntrenadoresView({
    super.key,
    required this.controller,
    this.onRegistrarEntrenador,
  });

  /// Vista conectada a Firestore.
  factory GestionEntrenadoresView.conFirebase({
    Key? key,
    VoidCallback? onRegistrarEntrenador,
  }) {
    return GestionEntrenadoresView(
      key: key,
      controller: GestionEntrenadoresController(
        datos: GestionEntrenadoresService(),
      ),
      onRegistrarEntrenador: onRegistrarEntrenador,
    );
  }

  /// La vista libera este controlador al cerrarse.
  final GestionEntrenadoresController controller;

  /// Atajo al formulario de registro. Si es `null`, el botón no aparece.
  final VoidCallback? onRegistrarEntrenador;

  @override
  State<GestionEntrenadoresView> createState() =>
      _GestionEntrenadoresViewState();
}

class _GestionEntrenadoresViewState extends State<GestionEntrenadoresView> {
  GestionEntrenadoresController get _controller => widget.controller;

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

  void _avisar(String texto, {required bool exito}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: exito ? Colors.green[700] : Colors.red[700],
        content: Text(texto),
      ),
    );
  }

  Future<void> _asignar(Usuario entrenador) async {
    final disponibles = _controller.deportes;
    final elegida = await showDialog<Deporte>(
      context: context,
      builder: (contextoDialogo) => SimpleDialog(
        key: const Key('dialogo-asignar'),
        title: Text('Asignar disciplina a ${entrenador.nombreCompleto}'),
        children: [
          if (disponibles.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No hay disciplinas creadas.'),
            ),
          for (final deporte in disponibles)
            _OpcionDisciplina(
              deporte: deporte,
              yaEsSuya: deporte.tieneEntrenador(entrenador.uid),
              actuales: _controller.entrenadoresDe(deporte),
              choca: _controller
                  .choquesAlAsignar(entrenador, deporte)
                  .isNotEmpty,
              onElegir: () => Navigator.of(contextoDialogo).pop(deporte),
            ),
        ],
      ),
    );
    if (elegida == null || !mounted) return;

    final error = await _controller.asignar(entrenador, elegida);
    if (!mounted) return;
    if (error != null && _controller.ultimoErrorFueChoque) {
      await _mostrarChoque(error);
      return;
    }
    _avisar(
      error ?? '${elegida.nombre} asignada a ${entrenador.nombreCompleto}.',
      exito: error == null,
    );
  }

  /// Diálogo que bloquea la asignación y explica con qué disciplina choca.
  Future<void> _mostrarChoque(String mensaje) {
    return showDialog<void>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        key: const Key('dialogo-choque-horario'),
        icon: Icon(Icons.event_busy, color: Colors.red[700], size: 36),
        title: const Text('Choque de horario'),
        content: Text(mensaje),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(contextoDialogo).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _revocar(Usuario entrenador, Deporte deporte) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('Revocar disciplina'),
        content: Text(
          '¿Quitar ${deporte.nombre} a ${entrenador.nombreCompleto}? '
          '${deporte.entrenadoresIds.length > 1 ? 'Los demás entrenadores la seguirán dictando.' : 'La disciplina quedará sin entrenador.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contextoDialogo).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirmar-revocar'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () => Navigator.of(contextoDialogo).pop(true),
            child: const Text('Revocar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final error = await _controller.revocar(entrenador, deporte);
    if (!mounted) return;
    _avisar(
      error ??
          '${deporte.nombre} ya no está asignada a '
              '${entrenador.nombreCompleto}.',
      exito: error == null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de entrenadores'),
        backgroundColor: _azul,
        foregroundColor: Colors.white,
        actions: [
          if (widget.onRegistrarEntrenador != null)
            IconButton(
              key: const Key('registrar-desde-gestion'),
              tooltip: 'Registrar entrenador',
              onPressed: widget.onRegistrarEntrenador,
              icon: const Icon(Icons.person_add_alt_1),
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
    final entrenadores = _controller.entrenadores;
    if (entrenadores.isEmpty) {
      return const Center(
        key: Key('sin-entrenadores'),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aún no hay entrenadores registrados.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: entrenadores.length,
          separatorBuilder: (context, indice) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _tarjeta(entrenadores[i]),
        ),
      ),
    );
  }

  Widget _tarjeta(EntrenadorConDisciplinas fila) {
    final entrenador = fila.entrenador;
    final ocupado = _controller.ocupado != null;
    return Card(
      key: Key('entrenador-${entrenador.uid}'),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AvatarUsuario(
                  fotoUrl: entrenador.fotoUrl,
                  iniciales: entrenador.iniciales,
                  radio: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entrenador.nombreCompleto,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        entrenador.email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        (entrenador.carnet ?? '').isEmpty
                            ? 'Sin carnet'
                            : 'Carnet: ${entrenador.carnet}',
                        key: Key('carnet-${entrenador.uid}'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              fila.disciplinas.isEmpty
                  ? 'Sin disciplinas asignadas'
                  : 'Disciplinas asignadas (${fila.disciplinas.length})',
              key: Key('resumen-${entrenador.uid}'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            for (final deporte in fila.disciplinas)
              ListTile(
                key: Key('asignada-${entrenador.uid}-${deporte.id}'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.sports, color: _azul),
                title: Text(deporte.nombre),
                subtitle: Text(deporte.horariosTexto),
                trailing: TextButton(
                  key: Key('revocar-${entrenador.uid}-${deporte.id}'),
                  onPressed: ocupado
                      ? null
                      : () => _revocar(entrenador, deporte),
                  style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
                  child: const Text('Revocar'),
                ),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                key: Key('asignar-${entrenador.uid}'),
                onPressed: ocupado ? null : () => _asignar(entrenador),
                style: FilledButton.styleFrom(backgroundColor: _naranja),
                icon: ocupado
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add),
                label: const Text('Asignar disciplina'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpcionDisciplina extends StatelessWidget {
  const _OpcionDisciplina({
    required this.deporte,
    required this.yaEsSuya,
    required this.actuales,
    required this.choca,
    required this.onElegir,
  });

  final Deporte deporte;
  final bool yaEsSuya;

  /// Nombres de los entrenadores que ya la dictan.
  final List<String> actuales;

  /// `true` si se cruza con el horario del entrenador. Se puede tocar igual,
  /// para ver el detalle del choque.
  final bool choca;
  final VoidCallback onElegir;

  @override
  Widget build(BuildContext context) {
    final detalle = yaEsSuya
        ? 'Ya la tiene asignada'
        : choca
        ? 'Choca con su horario'
        : actuales.isEmpty
        ? 'Sin entrenador'
        : 'Entrenadores: ${actuales.join(', ')}';
    return ListTile(
      key: Key('opcion-${deporte.id}'),
      enabled: !yaEsSuya,
      leading: Icon(
        yaEsSuya
            ? Icons.check_circle
            : choca
            ? Icons.event_busy
            : Icons.sports,
        color: yaEsSuya
            ? Colors.green[700]
            : choca
            ? Colors.red[700]
            : _azul,
      ),
      title: Text(deporte.nombre),
      subtitle: Text('${deporte.horariosTexto} · $detalle'),
      onTap: yaEsSuya ? null : onElegir,
    );
  }
}
