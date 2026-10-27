import 'package:flutter/material.dart';

import '../../controllers/buscador_controller.dart';
import '../../models/deporte.dart';
import '../../services/buscador_service.dart';
import '../entrenador/widgets/entrenador_widgets.dart';
import '../theme/saman_colors.dart';
import 'widgets/tarjeta_deporte.dart';

/// Buscador de la oferta deportiva para el estudiante (REQ-14).
///
/// Permite buscar por nombre, disciplina o lugar y filtrar por disciplina,
/// día de la semana y cupos disponibles. Al tocar un deporte se abre su
/// detalle; si se pasa [onSeleccionar], el detalle muestra el botón
/// "Inscribirme" que lo llama.
///
/// Para abrirla con los datos reales de Firestore:
/// ```dart
/// Navigator.of(context).push(MaterialPageRoute(
///   builder: (_) => BuscadorScreen.conFirestore(),
/// ));
/// ```
class BuscadorScreen extends StatefulWidget {
  const BuscadorScreen({
    super.key,
    required this.controller,
    this.onSeleccionar,
  });

  /// Pantalla conectada a Firestore real.
  factory BuscadorScreen.conFirestore({
    Key? key,
    void Function(Deporte deporte)? onSeleccionar,
  }) {
    return BuscadorScreen(
      key: key,
      controller: BuscadorController(datos: BuscadorService()),
      onSeleccionar: onSeleccionar,
    );
  }

  /// Controlador del buscador. La pantalla lo libera al cerrarse.
  final BuscadorController controller;

  /// Acción del botón "Inscribirme". Si es `null`, el botón no aparece.
  final void Function(Deporte deporte)? onSeleccionar;

  @override
  State<BuscadorScreen> createState() => _BuscadorScreenState();
}

class _BuscadorScreenState extends State<BuscadorScreen> {
  final _campoBusqueda = TextEditingController();

  BuscadorController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.iniciar();
  }

  @override
  void dispose() {
    _campoBusqueda.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _limpiarFiltros() {
    _campoBusqueda.clear();
    _controller.limpiarFiltros();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar deportes')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.cargando && _controller.todos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_controller.error != null) {
            return MensajeVacio(
              icono: Icons.wifi_off,
              titulo: 'No se pudo cargar',
              detalle: _controller.error,
              accion: FilledButton(
                onPressed: _controller.recargar,
                child: const Text('Reintentar'),
              ),
            );
          }
          final resultados = _controller.resultados;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  key: const Key('buscador-deportes'),
                  controller: _campoBusqueda,
                  onChanged: _controller.buscar,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Buscar por nombre, disciplina o lugar',
                    suffixIcon: _controller.texto.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Borrar búsqueda',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _campoBusqueda.clear();
                              _controller.buscar('');
                            },
                          ),
                  ),
                ),
              ),
              _FilaDeChips(
                children: [
                  FilterChip(
                    key: const Key('filtro-cupos'),
                    label: const Text('Solo con cupos'),
                    selected: _controller.soloConCupos,
                    onSelected: _controller.cambiarSoloConCupos,
                  ),
                  for (final dia in diasDeLaSemana)
                    ChoiceChip(
                      key: Key('dia-$dia'),
                      label: Text(dia),
                      selected: _controller.dia == dia,
                      onSelected: (_) => _controller.elegirDia(dia),
                    ),
                ],
              ),
              _FilaDeChips(
                children: [
                  for (final disciplina in _controller.disciplinas)
                    ChoiceChip(
                      key: Key('disciplina-$disciplina'),
                      label: Text(disciplina),
                      selected: _controller.disciplina == disciplina,
                      onSelected: (_) =>
                          _controller.elegirDisciplina(disciplina),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        resultados.length == 1
                            ? '1 deporte'
                            : '${resultados.length} deportes',
                        key: const Key('contador-resultados'),
                        style: const TextStyle(
                          color: SamanColors.neutro500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_controller.hayFiltros)
                      TextButton(
                        onPressed: _limpiarFiltros,
                        child: const Text('Limpiar'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: resultados.isEmpty
                    ? MensajeVacio(
                        icono: Icons.search_off,
                        titulo: 'No encontramos deportes',
                        detalle:
                            'Prueba con otro nombre o quita algunos filtros.',
                        accion: FilledButton(
                          key: const Key('limpiar-filtros'),
                          onPressed: _limpiarFiltros,
                          child: const Text('Limpiar filtros'),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _controller.recargar,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: resultados.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final deporte = resultados[i];
                            return TarjetaDeporte(
                              key: Key('tarjeta-${deporte.id}'),
                              deporte: deporte,
                              cuposDisponibles:
                                  _controller.cuposDisponiblesDe(deporte),
                              onTap: () => _mostrarDetalle(deporte),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _mostrarDetalle(Deporte deporte) {
    final onSeleccionar = widget.onSeleccionar;
    final cuposLibres = _controller.cuposDisponiblesDe(deporte);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (contextoHoja) {
        return SafeArea(
          child: Padding(
            key: const Key('detalle-deporte'),
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            deporte.nombre,
                            style: Theme.of(contextoHoja)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            deporte.disciplina,
                            style:
                                const TextStyle(color: SamanColors.neutro500),
                          ),
                        ],
                      ),
                    ),
                    EtiquetaCupos(cuposDisponibles: cuposLibres),
                  ],
                ),
                const SizedBox(height: 16),
                const _Subtitulo('Horarios'),
                if (deporte.horarios.isEmpty)
                  const Text('Horario por definir')
                else
                  for (final horario in deporte.horarios)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 18,
                            color: SamanColors.azul,
                          ),
                          const SizedBox(width: 8),
                          Text(horario),
                        ],
                      ),
                    ),
                const SizedBox(height: 12),
                const _Subtitulo('Lugar'),
                Text(deporte.lugar.isEmpty ? 'Lugar por definir' : deporte.lugar),
                const SizedBox(height: 12),
                Text(
                  'Cupos: ${deporte.cupos} · '
                  'Inscritos: ${_controller.inscritosDe(deporte)}',
                  style: const TextStyle(color: SamanColors.neutro500),
                ),
                if (onSeleccionar != null) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('boton-inscribirme'),
                      onPressed: cuposLibres == 0
                          ? null
                          : () {
                              Navigator.of(contextoHoja).pop();
                              onSeleccionar(deporte);
                            },
                      child: Text(
                        cuposLibres == 0 ? 'Sin cupos disponibles' : 'Inscribirme',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Fila horizontal desplazable de chips de filtro.
class _FilaDeChips extends StatelessWidget {
  const _FilaDeChips({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          for (final chip in children)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: chip,
            ),
        ],
      ),
    );
  }
}

class _Subtitulo extends StatelessWidget {
  const _Subtitulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        texto,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: SamanColors.azulNoche,
        ),
      ),
    );
  }
}
