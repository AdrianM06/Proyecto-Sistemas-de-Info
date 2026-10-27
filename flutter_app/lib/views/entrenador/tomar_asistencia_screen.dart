import 'package:flutter/material.dart';

import '../../controllers/entrenador_controller.dart';
import '../theme/saman_colors.dart';
import 'formato.dart';
import 'widgets/entrenador_widgets.dart';

/// Pantalla para tomar la asistencia de una sesión de entrenamiento.
///
/// El entrenador elige la fecha, marca a cada estudiante como Presente o
/// Ausente y guarda. Si ya había asistencia guardada para esa fecha, se
/// carga para poder corregirla.
class TomarAsistenciaScreen extends StatelessWidget {
  const TomarAsistenciaScreen({super.key, required this.controller});

  final EntrenadorController controller;

  Future<void> _elegirFecha(BuildContext context) async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: controller.fechaAsistencia,
      firstDate: DateTime(hoy.year - 1),
      lastDate: hoy,
      helpText: 'Fecha de la sesión',
    );
    if (elegida != null) await controller.cambiarFecha(elegida);
  }

  Future<void> _guardar(BuildContext context) async {
    final mensajero = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);
    final guardado = await controller.guardarAsistencia();
    if (guardado) {
      mensajero.showSnackBar(
        SnackBar(
          content: Text(
            'Asistencia guardada: ${controller.presentes} presentes, '
            '${controller.ausentes} ausentes.',
          ),
        ),
      );
      if (navegador.canPop()) navegador.pop();
    } else if (controller.error != null) {
      mensajero.showSnackBar(
        SnackBar(
          content: Text(controller.error!),
          backgroundColor: SamanColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final deporte = controller.deporteActual;
        final nomina = controller.nomina;
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tomar asistencia'),
                if (deporte != null)
                  Text(
                    deporte.nombre,
                    style: const TextStyle(
                      fontSize: 13,
                      color: SamanColors.neutro500,
                    ),
                  ),
              ],
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    const Icon(Icons.event, color: SamanColors.azul),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fechaLarga(controller.fechaAsistencia),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _elegirFecha(context),
                      child: const Text('Cambiar fecha'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    _Contador(
                      valor: controller.presentes,
                      texto: 'Presentes',
                      fondo: SamanColors.verde50,
                      color: SamanColors.verde700,
                    ),
                    const SizedBox(width: 8),
                    _Contador(
                      valor: controller.ausentes,
                      texto: 'Ausentes',
                      fondo: SamanColors.errorFondo,
                      color: SamanColors.error,
                    ),
                    const SizedBox(width: 8),
                    _Contador(
                      valor: controller.sinMarcar,
                      texto: 'Sin marcar',
                      fondo: SamanColors.azul50,
                      color: SamanColors.neutro500,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${nomina.length} estudiantes',
                        style: const TextStyle(
                          color: SamanColors.neutro500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: nomina.isEmpty
                          ? null
                          : () => controller.marcarTodos(presentes: true),
                      child: const Text('Marcar todos presentes'),
                    ),
                  ],
                ),
              ),
              if (controller.cargando) const LinearProgressIndicator(),
              Expanded(
                child: nomina.isEmpty
                    ? const MensajeVacio(
                        icono: Icons.groups_outlined,
                        titulo: 'No hay estudiantes inscritos',
                        detalle: 'Cuando haya inscripciones activas aparecerán aquí.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                        itemCount: nomina.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, indent: 64),
                        itemBuilder: (context, i) {
                          final estudiante = nomina[i];
                          final marca = controller.marcaDe(estudiante.uid);
                          return ListTile(
                            key: Key('fila-${estudiante.uid}'),
                            leading: AvatarIniciales(usuario: estudiante, radio: 18),
                            title: Text(
                              estudiante.nombreCompleto,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            trailing: SegmentedButton<bool>(
                              key: Key('marca-${estudiante.uid}'),
                              showSelectedIcon: false,
                              emptySelectionAllowed: true,
                              segments: const [
                                ButtonSegment(
                                  value: true,
                                  icon: Icon(Icons.check),
                                  tooltip: 'Presente',
                                ),
                                ButtonSegment(
                                  value: false,
                                  icon: Icon(Icons.close),
                                  tooltip: 'Ausente',
                                ),
                              ],
                              selected: marca == null ? <bool>{} : {marca},
                              onSelectionChanged: (seleccion) {
                                if (seleccion.isEmpty) return;
                                controller.marcar(
                                  estudiante.uid,
                                  presente: seleccion.first,
                                );
                              },
                              style: SegmentedButton.styleFrom(
                                selectedBackgroundColor: marca == false
                                    ? SamanColors.error
                                    : SamanColors.verde,
                                selectedForegroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton.icon(
                key: const Key('guardar-asistencia'),
                onPressed: controller.guardando || nomina.isEmpty
                    ? null
                    : () => _guardar(context),
                icon: controller.guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  'Guardar asistencia '
                  '(${nomina.length - controller.sinMarcar}/${nomina.length})',
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Contador extends StatelessWidget {
  const _Contador({
    required this.valor,
    required this.texto,
    required this.fondo,
    required this.color,
  });

  final int valor;
  final String texto;
  final Color fondo;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$valor',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(texto, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}
