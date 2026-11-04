import 'package:flutter/material.dart';

import '../../controllers/buscador_controller.dart';
import '../../models/deporte.dart';
import '../../services/buscador_service.dart';
import '../../services/inscripcion_service.dart';
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

  /// Pantalla del estudiante con la sesión abierta: además de buscar, el
  /// detalle de cada deporte deja inscribirse. El botón pasa a "Inscrito"
  /// cuando ya tiene una inscripción activa.
  factory BuscadorScreen.paraEstudiante({
    Key? key,
    required String estudianteId,
  }) {
    return BuscadorScreen(
      key: key,
      controller: BuscadorController(
        datos: BuscadorService(),
        inscripciones: InscripcionService(),
        estudianteId: estudianteId,
      ),
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
                              cuposDisponibles: _controller.cuposDisponiblesDe(
                                deporte,
                              ),
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
    final aviso = ValueNotifier<_Aviso?>(null);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (contextoHoja) {
        return ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final cuposLibres = _controller.cuposDisponiblesDe(deporte);
            final inscrito = _controller.estaInscrito(deporte);
            final inscribiendo = _controller.inscribiendo == deporte.id;
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
                                style: const TextStyle(
                                  color: SamanColors.neutro500,
                                ),
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
                    Text(
                      deporte.lugar.isEmpty
                          ? 'Lugar por definir'
                          : deporte.lugar,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Cupos: ${deporte.cupos} · '
                      'Inscritos: ${_controller.inscritosDe(deporte)}',
                      style: const TextStyle(color: SamanColors.neutro500),
                    ),
                    if (onSeleccionar != null ||
                        _controller.permiteInscribir) ...[
                      const SizedBox(height: 20),
                      ValueListenableBuilder<_Aviso?>(
                        valueListenable: aviso,
                        builder: (context, valor, _) {
                          if (valor == null) return const SizedBox.shrink();
                          final color = valor.exito
                              ? Colors.green[700]
                              : Colors.red[700];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              key: const Key('aviso-inscripcion'),
                              children: [
                                Icon(
                                  valor.exito
                                      ? Icons.check_circle
                                      : Icons.error_outline,
                                  color: color,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    valor.texto,
                                    style: TextStyle(color: color),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          key: const Key('boton-inscribirme'),
                          onPressed:
                              inscrito || inscribiendo || cuposLibres == 0
                              ? null
                              : () =>
                                    _inscribirme(contextoHoja, deporte, aviso),
                          child: inscribiendo
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  inscrito
                                      ? 'Inscrito'
                                      : cuposLibres == 0
                                      ? 'Sin cupos disponibles'
                                      : 'Inscribirme',
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
      },
    );
  }

  /// Con inscripción propia (estudiante) confirma y guarda en Firestore; si
  /// no, cierra el detalle y le pasa el deporte a `onSeleccionar`.
  Future<void> _inscribirme(
    BuildContext contextoHoja,
    Deporte deporte,
    ValueNotifier<_Aviso?> aviso,
  ) async {
    if (!_controller.permiteInscribir) {
      Navigator.of(contextoHoja).pop();
      widget.onSeleccionar?.call(deporte);
      return;
    }

    final confirmar = await showDialog<bool>(
      context: contextoHoja,
      builder: (contextoDialogo) => AlertDialog(
        key: const Key('dialogo-inscripcion'),
        title: const Text('Inscribirme'),
        content: Text('¿Quieres inscribirte en ${deporte.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contextoDialogo).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirmar-inscripcion'),
            onPressed: () => Navigator.of(contextoDialogo).pop(true),
            child: const Text('Inscribirme'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    aviso.value = null;
    final error = await _controller.inscribirse(deporte);
    if (!mounted) return;
    aviso.value = error == null
        ? _Aviso('¡Quedaste inscrito en ${deporte.nombre}!', exito: true)
        : _Aviso(error, exito: false);
  }
}

/// Mensaje de resultado de la inscripción dentro del detalle del deporte.
class _Aviso {
  const _Aviso(this.texto, {required this.exito});

  final String texto;
  final bool exito;
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
            Padding(padding: const EdgeInsets.only(right: 8), child: chip),
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
