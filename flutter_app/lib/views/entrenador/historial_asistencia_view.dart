import 'package:flutter/material.dart';

import '../../controllers/entrenador_controller.dart';
import '../theme/saman_colors.dart';
import 'formato.dart';
import 'widgets/entrenador_widgets.dart';

/// Pestaña "Asistencia": promedio del período y lista de sesiones guardadas.
class HistorialAsistenciaView extends StatelessWidget {
  const HistorialAsistenciaView({
    super.key,
    required this.controller,
    required this.onTomarAsistencia,
    required this.onAbrirSesion,
  });

  final EntrenadorController controller;

  /// Abre la toma de asistencia para hoy.
  final VoidCallback onTomarAsistencia;

  /// Abre la toma de asistencia de una sesión ya guardada para revisarla.
  final ValueChanged<DateTime> onAbrirSesion;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final historial = controller.historial;
        final inscritos = controller.inscritos;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Promedio de asistencia',
                            style: TextStyle(color: SamanColors.neutro500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            porcentaje(controller.promedioAsistencia),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: SamanColors.azulNoche,
                            ),
                          ),
                          Text(
                            '${historial.length} sesiones registradas',
                            style: const TextStyle(color: SamanColors.neutro500),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: onTomarAsistencia,
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text('Tomar'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (historial.isEmpty)
              const MensajeVacio(
                icono: Icons.event_note_outlined,
                titulo: 'Todavía no hay asistencias guardadas',
                detalle: 'Toma la asistencia de la primera sesión para ver el historial.',
              )
            else
              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < historial.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: SamanColors.azul50,
                          child: Text(
                            '${historial[i].fecha.day}',
                            style: const TextStyle(
                              color: SamanColors.azul,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          fechaCorta(historial[i].fecha),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${_presentesEnNomina(historial[i].presentes)} de '
                          '$inscritos presentes',
                        ),
                        trailing: EtiquetaPorcentaje(
                          valor: controller.porcentajeDeSesion(historial[i]),
                        ),
                        onTap: () => onAbrirSesion(historial[i].fecha),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  int _presentesEnNomina(List<String> presentes) => controller.nomina
      .where((estudiante) => presentes.contains(estudiante.uid))
      .length;
}
