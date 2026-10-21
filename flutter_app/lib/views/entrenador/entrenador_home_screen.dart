import 'package:flutter/material.dart';

import '../../controllers/entrenador_controller.dart';
import '../../models/deporte.dart';
import '../../services/entrenador_service.dart';
import '../theme/saman_colors.dart';
import 'formato.dart';
import 'historial_asistencia_view.dart';
import 'nomina_view.dart';
import 'tomar_asistencia_screen.dart';
import 'widgets/entrenador_widgets.dart';

/// Pantalla principal del entrenador (la "V" de MVC).
///
/// Tiene tres pestañas: Inicio (panel con la disciplina y sus datos),
/// Nómina (estudiantes inscritos) y Asistencia (historial de sesiones).
/// Toda la lógica está en [EntrenadorController]; esta pantalla solo
/// muestra su estado y le pasa las acciones del usuario.
///
/// Desde el inicio de sesión, cuando el rol del usuario es `entrenador`:
/// ```dart
/// Navigator.of(context).pushReplacement(MaterialPageRoute(
///   builder: (_) => EntrenadorHomeScreen.conFirestore(
///     entrenadorId: usuario.uid,
///     nombreEntrenador: usuario.nombreCompleto,
///   ),
/// ));
/// ```
class EntrenadorHomeScreen extends StatefulWidget {
  const EntrenadorHomeScreen({
    super.key,
    required this.controller,
    required this.nombreEntrenador,
  });

  /// Crea la pantalla conectada a Cloud Firestore.
  factory EntrenadorHomeScreen.conFirestore({
    Key? key,
    required String entrenadorId,
    required String nombreEntrenador,
  }) {
    return EntrenadorHomeScreen(
      key: key,
      controller: EntrenadorController(
        datos: EntrenadorService(),
        entrenadorId: entrenadorId,
      ),
      nombreEntrenador: nombreEntrenador,
    );
  }

  /// La pantalla se encarga de liberar este controlador al cerrarse.
  final EntrenadorController controller;
  final String nombreEntrenador;

  @override
  State<EntrenadorHomeScreen> createState() => _EntrenadorHomeScreenState();
}

class _EntrenadorHomeScreenState extends State<EntrenadorHomeScreen> {
  int _pestana = 0;

  EntrenadorController get _controller => widget.controller;

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

  Future<void> _tomarAsistenciaHoy() async {
    await _controller.irAHoy();
    if (!mounted) return;
    await _abrirTomaDeAsistencia();
  }

  Future<void> _abrirSesion(DateTime fecha) async {
    await _controller.cambiarFecha(fecha);
    if (!mounted) return;
    await _abrirTomaDeAsistencia();
  }

  Future<void> _abrirTomaDeAsistencia() {
    _controller.limpiarError();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TomarAsistenciaScreen(controller: _controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titulos = ['Hola, ${widget.nombreEntrenador}', 'Nómina', 'Asistencia'];
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(titulos[_pestana]),
            actions: [
              IconButton(
                tooltip: 'Actualizar',
                onPressed: _controller.cargando ? null : _controller.recargar,
                icon: const Icon(Icons.refresh),
              ),
            ],
            bottom: _controller.cargando
                ? const PreferredSize(
                    preferredSize: Size.fromHeight(4),
                    child: LinearProgressIndicator(),
                  )
                : null,
          ),
          body: _contenido(),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _pestana,
            onDestinationSelected: (indice) => setState(() => _pestana = indice),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups),
                label: 'Nómina',
              ),
              NavigationDestination(
                icon: Icon(Icons.fact_check_outlined),
                selectedIcon: Icon(Icons.fact_check),
                label: 'Asistencia',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _contenido() {
    final controller = _controller;
    if (controller.deportes.isEmpty) {
      if (controller.cargando) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.error != null) {
        return MensajeVacio(
          icono: Icons.cloud_off_outlined,
          titulo: controller.error!,
          accion: FilledButton(
            onPressed: controller.iniciar,
            child: const Text('Reintentar'),
          ),
        );
      }
      return const MensajeVacio(
        icono: Icons.sports_outlined,
        titulo: 'No tienes disciplinas asignadas',
        detalle: 'Cuando la coordinación te asigne una disciplina, aparecerá aquí.',
      );
    }

    return Column(
      children: [
        _SelectorDeDisciplina(controller: controller),
        Expanded(
          child: switch (_pestana) {
            0 => _PanelView(
                controller: controller,
                onTomarAsistencia: _tomarAsistenciaHoy,
                onVerNomina: () => setState(() => _pestana = 1),
              ),
            1 => NominaView(controller: controller),
            _ => HistorialAsistenciaView(
                controller: controller,
                onTomarAsistencia: _tomarAsistenciaHoy,
                onAbrirSesion: _abrirSesion,
              ),
          },
        ),
      ],
    );
  }
}

/// Fila de chips para cambiar de disciplina cuando el entrenador tiene más
/// de una.
class _SelectorDeDisciplina extends StatelessWidget {
  const _SelectorDeDisciplina({required this.controller});

  final EntrenadorController controller;

  @override
  Widget build(BuildContext context) {
    final deportes = controller.deportes;
    if (deportes.length < 2) return const SizedBox.shrink();
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        itemCount: deportes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final Deporte deporte = deportes[i];
          return ChoiceChip(
            label: Text(deporte.nombre),
            selected: deporte.id == controller.deporteActual?.id,
            onSelected: (_) => controller.seleccionarDeporte(deporte),
          );
        },
      ),
    );
  }
}

/// Pestaña "Inicio": datos de la disciplina, acciones rápidas, cupos,
/// asistencia promedio y estudiantes con baja asistencia.
class _PanelView extends StatelessWidget {
  const _PanelView({
    required this.controller,
    required this.onTomarAsistencia,
    required this.onVerNomina,
  });

  final EntrenadorController controller;
  final VoidCallback onTomarAsistencia;
  final VoidCallback onVerNomina;

  @override
  Widget build(BuildContext context) {
    final deporte = controller.deporteActual!;
    final enRiesgo = controller.estudiantesEnRiesgo();
    final cupos = deporte.cupos;
    final ocupacion = cupos == 0 ? 0.0 : controller.inscritos / cupos;

    return RefreshIndicator(
      onRefresh: controller.recargar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: SamanColors.azul,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deporte.disciplina.isEmpty ? 'Disciplina' : deporte.disciplina,
                    style: const TextStyle(color: SamanColors.azul200),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    deporte.nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Dato(icono: Icons.schedule, texto: deporte.horariosTexto),
                  const SizedBox(height: 6),
                  _Dato(
                    icono: Icons.place_outlined,
                    texto: deporte.lugar.isEmpty ? 'Lugar por definir' : deporte.lugar,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          key: const Key('boton-tomar-asistencia'),
                          style: FilledButton.styleFrom(
                            backgroundColor: SamanColors.naranja,
                            foregroundColor: SamanColors.azulNoche,
                          ),
                          onPressed: onTomarAsistencia,
                          icon: const Icon(Icons.fact_check_outlined),
                          label: const Text('Tomar asistencia'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Ver nómina',
                        onPressed: onVerNomina,
                        icon: const Icon(Icons.groups_outlined),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Indicador(
                  titulo: 'Inscritos',
                  valor: '${controller.inscritos}',
                  detalle: '/ $cupos cupos',
                  progreso: ocupacion.clamp(0.0, 1.0).toDouble(),
                  colorProgreso:
                      ocupacion >= 0.85 ? SamanColors.naranja : SamanColors.verde,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Indicador(
                  titulo: 'Asistencia promedio',
                  valor: porcentaje(controller.promedioAsistencia),
                  detalle: '${controller.historial.length} sesiones',
                  progreso: controller.promedioAsistencia ?? 0,
                  colorProgreso: SamanColors.azul,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Alertas de asistencia',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          if (enRiesgo.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.check_circle_outline, color: SamanColors.verde),
                title: Text('Todos los estudiantes están sobre 75 % de asistencia'),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final estudiante in enRiesgo)
                    ListTile(
                      leading: AvatarIniciales(usuario: estudiante),
                      title: Text(
                        estudiante.nombreCompleto,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text('Asistencia por debajo de 75 %'),
                      trailing: EtiquetaPorcentaje(
                        valor: controller.porcentajeDe(estudiante.uid),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 18, color: SamanColors.azul100),
        const SizedBox(width: 8),
        Expanded(
          child: Text(texto, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _Indicador extends StatelessWidget {
  const _Indicador({
    required this.titulo,
    required this.valor,
    required this.detalle,
    required this.progreso,
    required this.colorProgreso,
  });

  final String titulo;
  final String valor;
  final String detalle;
  final double progreso;
  final Color colorProgreso;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(color: SamanColors.neutro500)),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: SamanColors.azulNoche,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    detalle,
                    style: const TextStyle(color: SamanColors.neutro500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progreso,
                minHeight: 6,
                color: colorProgreso,
                backgroundColor: SamanColors.azul50,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
