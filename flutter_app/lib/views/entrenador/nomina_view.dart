import 'package:flutter/material.dart';

import '../../controllers/entrenador_controller.dart';
import '../theme/saman_colors.dart';
import 'widgets/entrenador_widgets.dart';

/// Pestaña "Nómina": estudiantes inscritos en la disciplina seleccionada,
/// con buscador por nombre o carnet y su porcentaje de asistencia.
class NominaView extends StatelessWidget {
  const NominaView({super.key, required this.controller});

  final EntrenadorController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final deporte = controller.deporteActual;
        if (deporte == null) {
          return const MensajeVacio(
            icono: Icons.sports_outlined,
            titulo: 'No tienes disciplinas asignadas',
          );
        }
        final estudiantes = controller.nominaFiltrada;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                key: const Key('buscador-nomina'),
                onChanged: controller.buscarEnNomina,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar por nombre o carnet',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${deporte.nombre} · ${controller.inscritos} inscritos',
                      style: const TextStyle(
                        color: SamanColors.neutro500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Text(
                    'Asistencia',
                    style: TextStyle(
                      color: SamanColors.neutro500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: estudiantes.isEmpty
                  ? MensajeVacio(
                      icono: Icons.person_search_outlined,
                      titulo: controller.busqueda.isEmpty
                          ? 'Aún no hay estudiantes inscritos'
                          : 'Ningún estudiante coincide con la búsqueda',
                    )
                  : RefreshIndicator(
                      onRefresh: controller.recargar,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                        itemCount: estudiantes.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, indent: 72),
                        itemBuilder: (context, i) {
                          final estudiante = estudiantes[i];
                          return ListTile(
                            leading: AvatarIniciales(usuario: estudiante),
                            title: Text(
                              estudiante.nombreCompleto,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text('Carnet ${estudiante.carnet ?? '—'}'),
                            trailing: EtiquetaPorcentaje(
                              valor: controller.porcentajeDe(estudiante.uid),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
