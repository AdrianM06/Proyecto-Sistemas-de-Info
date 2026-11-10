import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/bloque_horario.dart';
import '../../models/deporte.dart';
import '../../services/baja_disciplina_service.dart';
import '../../services/firestore_service.dart';
import '../../services/gestion_entrenadores_service.dart';
import '../../utils/choques_horario.dart';
import '../../utils/horarios.dart';
import 'panel_resumen_admin.dart';

const _azul = Color(0xFF003B82);
const _naranja = Color(0xFFF58220);

/// Panel del administrador (CU14: Visualizar Dashboard): resumen en números
/// (estudiantes, entrenadores, disciplinas e inscripciones activas), accesos
/// rápidos (registrar entrenadores, crear y gestionar disciplinas, gestionar
/// estudiantes) y la lista de deportes con sus horarios y etiquetas.
///
/// Cada deporte de la lista se puede editar rápido (nombre, categoría,
/// horarios, lugar, cupos y etiquetas) o eliminar, siempre con una
/// confirmación antes de aplicar el cambio. Los cambios pasan por los mismos
/// servicios que "Gestionar disciplinas": se valida el formato de los
/// horarios y que no choquen con otras disciplinas de los entrenadores, y al
/// eliminar se retiran las inscripciones activas.
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
    this.onEditarDeporte,
    this.onGestionarDisciplinas,
    this.listaDeportes,
    this.resumen,
    this.datosDisciplinas,
    this.baja,
  });

  /// Guarda los cambios de la edición rápida. Por defecto,
  /// [GestionEntrenadoresService] (Firestore).
  final GestionEntrenadoresDataSource? datosDisciplinas;

  /// Elimina deportes. Por defecto, [BajaDisciplinaService] (Firestore).
  final BajaDisciplinaDataSource? baja;

  /// Reemplaza la lista de deportes de Firestore (para las pruebas).
  final Widget? listaDeportes;

  /// Reemplaza el resumen en números conectado a Firestore (para las
  /// pruebas). Por defecto, [PanelResumenAdmin.conFirebase].
  final Widget? resumen;

  /// Abre la lista de disciplinas para cambiar su horario, nombre, lugar,
  /// etiquetas y entrenadores.
  final VoidCallback? onGestionarDisciplinas;

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

  /// Abre el formulario para editar una disciplina (horarios, entrenadores,
  /// cupos...). Si es `null`, no aparece el botón de editar.
  final void Function(Deporte deporte)? onEditarDeporte;

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
      // Toda la página se desplaza: así el resumen, los accesos y la lista
      // caben también en el teléfono.
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: resumen ?? PanelResumenAdmin.conFirebase(),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Text(
              'Accesos rápidos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  key: const Key('admin-gestionar-disciplinas'),
                  icono: Icons.edit_calendar_outlined,
                  titulo: 'Gestionar disciplinas',
                  onTap: onGestionarDisciplinas,
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
          listaDeportes ?? _listaDeportes(),
        ],
      ),
    );
  }

  Widget _listaDeportes() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirestoreService.instance.sports.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No se pudieron cargar los deportes.'),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No hay deportes registrados.')),
            );
          }

          final deportes = snapshot.data!.docs
              .map((doc) => Deporte.fromFirestore(doc))
              .toList();

          return ListView.builder(
            // La página completa ya se desplaza: la lista ocupa su alto
            // natural.
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
                                onPressed: () =>
                                    _editarDeporte(context, deporte),
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
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.sports_outlined,
                              color: _azul, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Entrenadores: ${deporte.entrenadoresTexto}',
                            ),
                          ),
                        ],
                      ),
                      if (deporte.lugar.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.place_outlined,
                                color: Colors.grey, size: 18),
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
                              label: Text('#$e',
                                  style: const TextStyle(fontSize: 12)),
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

  // ------------------------------------------------- edición rápida y baja

  Future<void> _editarDeporte(BuildContext context, Deporte deporte) async {
    final nombre = TextEditingController(text: deporte.nombre);
    final disciplina = TextEditingController(text: deporte.disciplina);
    final horarios = TextEditingController(text: deporte.horarios.join('\n'));
    final lugar = TextEditingController(text: deporte.lugar);
    final cupos = TextEditingController(text: deporte.cupos.toString());
    final etiquetas = TextEditingController(text: deporte.etiquetas.join(', '));

    final cambios = await showDialog<Deporte>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('dialogo-editar-deporte'),
        title: Text('Editar ${deporte.nombre}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _campoEdicion(
                key: const Key('editar-deporte-nombre'),
                controller: nombre,
                label: 'Nombre del deporte',
              ),
              const SizedBox(height: 12),
              _campoEdicion(
                controller: disciplina,
                label: 'Categoría / disciplina',
              ),
              const SizedBox(height: 12),
              _campoEdicion(
                key: const Key('editar-deporte-horarios'),
                controller: horarios,
                label: 'Horarios',
                hint: 'Un horario por línea, ej. Lun y Mié 4:00 pm - 6:00 pm',
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              _campoEdicion(controller: lugar, label: 'Lugar / cancha'),
              const SizedBox(height: 12),
              _campoEdicion(
                key: const Key('editar-deporte-cupos'),
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
              if (onEditarDeporte != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('editar-deporte-completo'),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      onEditarDeporte!(deporte);
                    },
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Editar entrenadores y más'),
                  ),
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
            key: const Key('continuar-editar-deporte'),
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
                _avisar(
                  dialogContext,
                  'Ingrese nombre, al menos un horario y cupos válidos.',
                );
                return;
              }
              // Cada horario se interpreta en bloques (día + hora de inicio
              // y fin), igual que en el formulario de la disciplina.
              final bloques = <BloqueHorario>[];
              for (final horario in nuevosHorarios) {
                final resultado = interpretarHorario(horario);
                if (!resultado.esValido) {
                  _avisar(dialogContext, '"$horario": ${resultado.error}');
                  return;
                }
                bloques.addAll(resultado.bloques);
              }
              Navigator.pop(
                dialogContext,
                Deporte(
                  id: deporte.id,
                  nombre: nombreTexto,
                  disciplina: disciplina.text.trim(),
                  cupos: cuposTexto,
                  entrenadoresIds: deporte.entrenadoresIds,
                  entrenadoresNombres: deporte.entrenadoresNombres,
                  horarios: nuevosHorarios,
                  bloques: bloques,
                  lugar: lugar.text.trim(),
                  etiquetas: etiquetas.text
                      .split(',')
                      .map((etiqueta) => etiqueta.trim())
                      .where((etiqueta) => etiqueta.isNotEmpty)
                      .toSet()
                      .toList(),
                ),
              );
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
      await (datosDisciplinas ?? GestionEntrenadoresService())
          .guardarDisciplina(cambios);
      if (!context.mounted) return;
      _avisar(context, 'Deporte actualizado correctamente.');
    } on ChoqueHorarioException catch (e) {
      if (context.mounted) _avisar(context, e.mensaje);
    } on GestionEntrenadoresException catch (e) {
      if (context.mounted) _avisar(context, e.mensaje);
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      _avisar(
        context,
        e.code == 'permission-denied'
            ? 'No tienes permiso para modificar este deporte.'
            : 'No se pudo actualizar el deporte. Revisa tu conexión e intenta de nuevo.',
      );
    }
  }

  Future<void> _eliminarDeporte(BuildContext context, Deporte deporte) async {
    final servicio = baja ?? BajaDisciplinaService();
    int? inscritos;
    try {
      inscritos = await servicio.inscripcionesActivas(deporte.id);
    } catch (_) {
      inscritos = null;
    }
    if (!context.mounted) return;

    final aviso = switch (inscritos) {
      null => 'Los estudiantes inscritos perderán su cupo.',
      0 => 'No tiene estudiantes inscritos.',
      1 => '1 estudiante inscrito perderá su cupo.',
      final n => '$n estudiantes inscritos perderán su cupo.',
    };
    final confirmado = await _confirmar(
      context,
      titulo: 'Eliminar deporte',
      mensaje:
          '¿Estás seguro de eliminar "${deporte.nombre}"? Esta acción no se '
          'puede deshacer. $aviso Se borran sus reseñas y las asistencias ya '
          'tomadas se conservan como historial.',
      textoAccion: 'Eliminar',
      accionPeligrosa: true,
    );
    if (!confirmado || !context.mounted) return;

    try {
      await servicio.eliminar(deporte.id);
      if (!context.mounted) return;
      _avisar(context, 'Deporte eliminado correctamente.');
    } on BajaDisciplinaException catch (e) {
      if (context.mounted) _avisar(context, e.mensaje);
    } catch (_) {
      if (!context.mounted) return;
      _avisar(
        context,
        'No se pudo eliminar el deporte. Revisa tu conexión e intenta de nuevo.',
      );
    }
  }

  static void _avisar(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
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
            key: const Key('dialogo-confirmar'),
            title: Text(titulo),
            content: Text(mensaje),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                key: const Key('confirmar-accion'),
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
    Key? key,
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      key: key,
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
