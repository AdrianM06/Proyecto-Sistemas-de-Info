import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/deporte.dart';
import '../../services/firestore_service.dart';

const _azul = Color(0xFF003B82);
const _naranja = Color(0xFFF58220);

/// Panel del administrador: accesos rápidos (registrar entrenadores, crear
/// disciplinas, gestionar estudiantes) y la lista de deportes con sus
/// horarios y etiquetas.
class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({
    super.key,
    this.nombreAdmin = 'Administrador',
    this.avatar,
    this.onAbrirPerfil,
    this.onCerrarSesion,
    this.onIrALanding,
    this.onRegistrarEntrenador,
    this.onCrearDeporte,
    this.onGestionarEstudiantes,
    this.onGestionarEntrenadores,
  });

  final String nombreAdmin;

  /// Foto de perfil de la barra superior. Si es `null` se ve un ícono.
  final Widget? avatar;

  /// Abre el perfil del administrador (solo foto; sin cambio de contraseña).
  final VoidCallback? onAbrirPerfil;
  final VoidCallback? onCerrarSesion;

  /// Botón "Página principal": vuelve a la Landing sin cerrar la sesión.
  final VoidCallback? onIrALanding;
  final VoidCallback? onRegistrarEntrenador;
  final VoidCallback? onCrearDeporte;
  final VoidCallback? onGestionarEstudiantes;

  /// Abre la lista de entrenadores para asignar o revocar disciplinas.
  final VoidCallback? onGestionarEntrenadores;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de administración'),
        backgroundColor: _azul,
        foregroundColor: Colors.white,
        actions: [
          if (onAbrirPerfil != null)
            IconButton(
              key: const Key('boton-perfil'),
              tooltip: 'Mi perfil',
              onPressed: onAbrirPerfil,
              icon: avatar ?? const Icon(Icons.account_circle),
            ),
          if (onIrALanding != null)
            IconButton(
              key: const Key('boton-ir-landing'),
              tooltip: 'Página principal',
              onPressed: onIrALanding,
              icon: const Icon(Icons.home_outlined),
            ),
          if (onCerrarSesion != null)
            IconButton(
              key: const Key('boton-cerrar-sesion'),
              tooltip: 'Cerrar sesión',
              onPressed: onCerrarSesion,
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
            child: Text(
              'Hola, $nombreAdmin',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _azul,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _AccionAdmin(
                  key: const Key('admin-registrar-entrenador'),
                  icono: Icons.person_add_alt_1,
                  titulo: 'Registrar entrenador',
                  onTap: onRegistrarEntrenador,
                ),
                _AccionAdmin(
                  key: const Key('admin-gestionar-entrenadores'),
                  icono: Icons.manage_accounts_outlined,
                  titulo: 'Gestionar entrenadores',
                  onTap: onGestionarEntrenadores,
                ),
                _AccionAdmin(
                  key: const Key('admin-crear-deporte'),
                  icono: Icons.add_circle_outline,
                  titulo: 'Crear disciplina',
                  onTap: onCrearDeporte,
                ),
                _AccionAdmin(
                  key: const Key('admin-gestionar-estudiantes'),
                  icono: Icons.groups_outlined,
                  titulo: 'Gestionar estudiantes',
                  onTap: onGestionarEstudiantes,
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Deportes y horarios',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: _listaDeportes()),
        ],
      ),
    );
  }

  Widget _listaDeportes() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.instance.sports.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text('No se pudieron cargar los deportes.'),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No hay deportes registrados.'));
        }

        final deportes = snapshot.data!.docs
            .map((doc) => Deporte.fromFirestore(doc))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: deportes.length,
          itemBuilder: (context, index) {
            final deporte = deportes[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            deporte.nombre,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text('${deporte.cupos} Cupos'),
                              backgroundColor: Colors.blue.shade50,
                            ),
                            IconButton(
                              key: Key('editar-deporte-${deporte.id}'),
                              tooltip: 'Editar deporte',
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: _azul,
                              ),
                              onPressed: () => _editarDeporte(context, deporte),
                            ),
                            IconButton(
                              key: Key('eliminar-deporte-${deporte.id}'),
                              tooltip: 'Eliminar deporte',
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () =>
                                  _eliminarDeporte(context, deporte),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (deporte.disciplina.isNotEmpty)
                      Text(
                        deporte.disciplina,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.schedule, color: _azul, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Horarios: ${deporte.horariosTexto}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (deporte.lugar.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            color: Colors.grey,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(deporte.lugar),
                        ],
                      ),
                    ],
                    if (deporte.etiquetas.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: deporte.etiquetas.map((e) {
                          return Chip(
                            label: Text(
                              '#$e',
                              style: const TextStyle(fontSize: 12),
                            ),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: Colors.orange.shade50,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _editarDeporte(BuildContext context, Deporte deporte) async {
    final nombre = TextEditingController(text: deporte.nombre);
    final disciplina = TextEditingController(text: deporte.disciplina);
    final horarios = TextEditingController(text: deporte.horarios.join('\n'));
    final lugar = TextEditingController(text: deporte.lugar);
    final cupos = TextEditingController(text: deporte.cupos.toString());
    final etiquetas = TextEditingController(text: deporte.etiquetas.join(', '));

    final cambios = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Editar ${deporte.nombre}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _campoEdicion(controller: nombre, label: 'Nombre del deporte'),
              const SizedBox(height: 12),
              _campoEdicion(
                controller: disciplina,
                label: 'Categoría / disciplina',
              ),
              const SizedBox(height: 12),
              _campoEdicion(
                controller: horarios,
                label: 'Horarios',
                hint: 'Un horario por línea',
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              _campoEdicion(controller: lugar, label: 'Lugar / cancha'),
              const SizedBox(height: 12),
              _campoEdicion(
                controller: cupos,
                label: 'Cupos máximos',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _campoEdicion(
                controller: etiquetas,
                label: 'Etiquetas',
                hint: 'Separadas por coma',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final nombreTexto = nombre.text.trim();
              final nuevosHorarios = horarios.text
                  .split('\n')
                  .map((horario) => horario.trim())
                  .where((horario) => horario.isNotEmpty)
                  .toList();
              final cuposTexto = int.tryParse(cupos.text.trim());
              if (nombreTexto.isEmpty ||
                  nuevosHorarios.isEmpty ||
                  cuposTexto == null ||
                  cuposTexto < 1) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Ingrese nombre, al menos un horario y cupos válidos.',
                    ),
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext, {
                'nombre': nombreTexto,
                'disciplina': disciplina.text.trim(),
                'horarios': nuevosHorarios,
                'lugar': lugar.text.trim(),
                'cupos': cuposTexto,
                'etiquetas': etiquetas.text
                    .split(',')
                    .map((etiqueta) => etiqueta.trim())
                    .where((etiqueta) => etiqueta.isNotEmpty)
                    .toSet()
                    .toList(),
              });
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    nombre.dispose();
    disciplina.dispose();
    horarios.dispose();
    lugar.dispose();
    cupos.dispose();
    etiquetas.dispose();

    if (cambios == null || !context.mounted) return;
    final confirmado = await _confirmar(
      context,
      titulo: 'Confirmar modificación',
      mensaje:
          '¿Estás seguro de modificar los parámetros de "${deporte.nombre}"?',
      textoAccion: 'Modificar',
    );
    if (!confirmado || !context.mounted) return;

    try {
      await FirestoreService.instance.sports.doc(deporte.id).update(cambios);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deporte actualizado correctamente.')),
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      final mensaje = e.code == 'permission-denied'
          ? 'No tienes permiso para modificar este deporte.'
          : 'No se pudo actualizar el deporte. Revisa tu conexión e intenta de nuevo.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensaje)));
    }
  }

  Future<void> _eliminarDeporte(BuildContext context, Deporte deporte) async {
    final confirmado = await _confirmar(
      context,
      titulo: 'Eliminar deporte',
      mensaje:
          '¿Estás seguro de eliminar "${deporte.nombre}"? Esta acción no se puede deshacer. Las inscripciones y asistencias existentes no se eliminarán automáticamente.',
      textoAccion: 'Eliminar',
      accionPeligrosa: true,
    );
    if (!confirmado || !context.mounted) return;

    try {
      await FirestoreService.instance.sports.doc(deporte.id).delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deporte eliminado correctamente.')),
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      final mensaje = e.code == 'permission-denied'
          ? 'No tienes permiso para eliminar este deporte.'
          : 'No se pudo eliminar el deporte. Revisa tu conexión e intenta de nuevo.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensaje)));
    }
  }

  Future<bool> _confirmar(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    required String textoAccion,
    bool accionPeligrosa = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(titulo),
            content: Text(mensaje),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: accionPeligrosa
                    ? FilledButton.styleFrom(backgroundColor: Colors.red)
                    : null,
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(textoAccion),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _campoEdicion({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _AccionAdmin extends StatelessWidget {
  const _AccionAdmin({
    super.key,
    required this.icono,
    required this.titulo,
    this.onTap,
  });

  final IconData icono;
  final String titulo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Material(
        color: Colors.white,
        elevation: 1,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icono, color: _naranja, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _azul,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
