import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../controllers/buscador_controller.dart';
import '../../models/bloque_horario.dart';
import '../../models/deporte.dart';
import '../../services/buscador_service.dart';
import '../../services/inscripcion_service.dart';
import '../entrenador/widgets/entrenador_widgets.dart';
import '../theme/saman_colors.dart';
import 'detalle_deporte_view.dart';
import 'widgets/tarjeta_deporte.dart';

class BuscadorScreen extends StatefulWidget {
  const BuscadorScreen({
    super.key,
    required this.controller,
    this.onSeleccionar,
    this.paginaDeResenas,
  });

  factory BuscadorScreen.conFirestore({
    Key? key,
    String? estudianteId,
    void Function(Deporte deporte)? onSeleccionar,
  }) {
    final uid = estudianteId ?? FirebaseAuth.instance.currentUser?.uid;
    return BuscadorScreen(
      key: key,
      controller: BuscadorController(
        datos: BuscadorService(),
        inscripciones: uid != null ? InscripcionService() : null,
        estudianteId: uid,
      ),
      onSeleccionar: onSeleccionar,
    );
  }

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

  final BuscadorController controller;
  final void Function(Deporte deporte)? onSeleccionar;

  /// Página que abre "Ver reseñas". Por defecto, [DetalleDeporteView]
  /// conectada a Firestore; las pruebas pasan otra.
  final Widget Function(Deporte deporte, String? estudianteId)? paginaDeResenas;

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
                  FilterChip(
                    key: const Key('filtro-horas'),
                    avatar: const Icon(Icons.schedule, size: 18),
                    label: Text(
                      _controller.filtraPorHoras
                          ? '${BloqueHorario.horaTexto(_controller.desde!)} – '
                                '${BloqueHorario.horaTexto(_controller.hasta!)}'
                          : 'Horario',
                    ),
                    selected: _controller.filtraPorHoras,
                    onSelected: (_) => _elegirRangoHoras(),
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
              _FilaDeChips(
                children: [
                  for (final etiqueta in _controller.etiquetas)
                    ChoiceChip(
                      key: Key('etiqueta-$etiqueta'),
                      label: Text('#$etiqueta'),
                      selected: _controller.etiqueta == etiqueta,
                      onSelected: (_) => _controller.elegirEtiqueta(etiqueta),
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
                        detalle: 'Prueba con otro nombre o quita algunos filtros.',
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
                              cuposDisponibles: _controller.cuposDisponiblesDe(deporte),
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

  /// Hoja para elegir la franja horaria (por ejemplo, de 2:00 pm a 6:00 pm).
  /// Se combina con el filtro por día.
  Future<void> _elegirRangoHoras() async {
    const primera = BuscadorController.primeraHora;
    const ultima = BuscadorController.ultimaHora;
    var rango = RangeValues(
      (_controller.desde ?? primera).toDouble(),
      (_controller.hasta ?? ultima).toDouble(),
    );
    final resultado = await showModalBottomSheet<RangeValues?>(
      context: context,
      showDragHandle: true,
      builder: (contextoHoja) => StatefulBuilder(
        builder: (contextoHoja, actualizar) => SafeArea(
          child: Padding(
            key: const Key('hoja-rango-horas'),
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '¿A qué hora puedes entrenar?',
                  style: Theme.of(contextoHoja).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Entre ${BloqueHorario.horaTexto(rango.start.round())} y '
                  '${BloqueHorario.horaTexto(rango.end.round())}',
                  key: const Key('texto-rango-horas'),
                ),
                RangeSlider(
                  key: const Key('slider-rango-horas'),
                  min: primera.toDouble(),
                  max: ultima.toDouble(),
                  divisions: (ultima - primera) ~/ 30,
                  values: rango,
                  labels: RangeLabels(
                    BloqueHorario.horaTexto(rango.start.round()),
                    BloqueHorario.horaTexto(rango.end.round()),
                  ),
                  onChanged: (valores) {
                    if (valores.end - valores.start < 30) return;
                    actualizar(() => rango = valores);
                  },
                ),
                Row(
                  children: [
                    TextButton(
                      key: const Key('quitar-rango-horas'),
                      onPressed: () => Navigator.of(
                        contextoHoja,
                      ).pop(const RangeValues(-1, -1)),
                      child: const Text('Quitar filtro'),
                    ),
                    const Spacer(),
                    FilledButton(
                      key: const Key('aplicar-rango-horas'),
                      onPressed: () => Navigator.of(contextoHoja).pop(rango),
                      child: const Text('Aplicar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (resultado == null || !mounted) return;
    if (resultado.start < 0) {
      _controller.elegirRangoHoras(null, null);
    } else {
      _controller.elegirRangoHoras(
        resultado.start.round(),
        resultado.end.round(),
      );
    }
  }

  /// Abre el detalle de la disciplina con sus reseñas y su promedio.
  void _abrirResenas(Deporte deporte) {
    final pagina = widget.paginaDeResenas ??
        (deporte, estudianteId) => DetalleDeporteView.conFirebase(
              deporte: deporte,
              estudianteId: estudianteId,
            );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => pagina(deporte, _controller.estudianteId),
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
                    _Subtitulo(
                      deporte.entrenadoresIds.length > 1
                          ? 'Entrenadores'
                          : 'Entrenador',
                    ),
                    Text(
                      deporte.entrenadoresTexto,
                      key: const Key('entrenadores-detalle'),
                    ),
                    const SizedBox(height: 12),
                    const _Subtitulo('Lugar'),
                    Text(
                      deporte.lugar.isEmpty ? 'Lugar por definir' : deporte.lugar,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Cupos totales: ${deporte.cupos} · '
                      'Inscritos: ${_controller.inscritosDe(deporte)}',
                      style: const TextStyle(color: SamanColors.neutro500),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      key: const Key('boton-ver-resenas'),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () {
                        Navigator.of(contextoHoja).pop();
                        _abrirResenas(deporte);
                      },
                      icon: const Icon(Icons.star_outline_rounded),
                      label: const Text('Ver reseñas y valoraciones'),
                    ),
                    if (onSeleccionar != null || _controller.permiteInscribir) ...[
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
                      if (!inscrito)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            key: const Key('boton-inscribirme'),
                            onPressed: inscribiendo || cuposLibres == 0
                                ? null
                                : () => _inscribirme(contextoHoja, deporte, aviso),
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
                                    cuposLibres == 0
                                        ? 'Sin cupos disponibles'
                                        : 'Inscribirme',
                                  ),
                          ),
                        )
                      else ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green[700]),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Actualmente estás inscrito en esta disciplina.',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            key: const Key('boton-cancelar-inscripcion-catalogo'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red[700],
                              side: BorderSide(color: Colors.red.shade300),
                            ),
                            onPressed: inscribiendo
                                ? null
                                : () => _cancelarInscripcion(
                                      contextoHoja,
                                      deporte,
                                      aviso,
                                    ),
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Cancelar mi inscripción'),
                          ),
                        ),
                      ],
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
        title: const Text('Confirmar Inscripción'),
        content: Text('¿Deseas inscribirte en ${deporte.nombre}?'),
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

  Future<void> _cancelarInscripcion(
    BuildContext contextoHoja,
    Deporte deporte,
    ValueNotifier<_Aviso?> aviso,
  ) async {
    final confirmar = await showDialog<bool>(
      context: contextoHoja,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('Cancelar Inscripción'),
        content: Text('¿Seguro que deseas retirarte de ${deporte.nombre}? Se liberará tu cupo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contextoDialogo).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () => Navigator.of(contextoDialogo).pop(true),
            child: const Text('Sí, retirarme'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    aviso.value = null;
    final error = await _controller.cancelarInscripcion(deporte);
    if (!mounted) return;

    aviso.value = error == null
        ? _Aviso('Tu inscripción ha sido cancelada con éxito.', exito: true)
        : _Aviso(error, exito: false);
  }
}

class _Aviso {
  const _Aviso(this.texto, {required this.exito});
  final String texto;
  final bool exito;
}

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