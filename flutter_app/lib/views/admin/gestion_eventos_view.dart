import 'package:flutter/material.dart';

import '../../controllers/gestion_eventos_controller.dart';
import '../../models/bloque_horario.dart';
import '../../models/cancha.dart';
import '../../models/deporte.dart';
import '../../models/evento.dart';
import '../entrenador/formato.dart';
import '../theme/saman_colors.dart';
import 'gestion_canchas_view.dart';

const _azul = Color(0xFF003B82);
const _naranja = Color(0xFFF58220);

class GestionEventosView extends StatefulWidget {
  const GestionEventosView({
    super.key,
    required this.adminId,
    this.controller,
  });

  final String adminId;
  final GestionEventosController? controller;

  @override
  State<GestionEventosView> createState() => _GestionEventosViewState();
}

class _GestionEventosViewState extends State<GestionEventosView> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  late final GestionEventosController _controller;

  String? _deporteIdSeleccionado;
  String? _canchaIdSeleccionada;
  DateTime? _fechaSeleccionada;
  TimeOfDay _horaInicio = const TimeOfDay(hour: 16, minute: 0);
  TimeOfDay _horaFin = const TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? GestionEventosController(adminId: widget.adminId);
    _controller.iniciar();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  int _aMinutos(TimeOfDay hora) => hora.hour * 60 + hora.minute;

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? hoy,
      firstDate: DateTime(hoy.year - 1),
      lastDate: DateTime(hoy.year + 3),
    );
    if (elegida != null) setState(() => _fechaSeleccionada = elegida);
  }

  Future<void> _elegirHora({required bool esInicio}) async {
    final elegida = await showTimePicker(
      context: context,
      initialTime: esInicio ? _horaInicio : _horaFin,
    );
    if (elegida != null) {
      setState(() {
        if (esInicio) {
          _horaInicio = elegida;
        } else {
          _horaFin = elegida;
        }
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final deporte = _controller.deportes
        .where((d) => d.id == _deporteIdSeleccionado)
        .firstOrNull;
    final cancha = _controller.canchasActivas
        .where((c) => c.id == _canchaIdSeleccionada)
        .firstOrNull;

    final error = await _controller.crearEvento(
      titulo: _tituloCtrl.text,
      deporte: deporte,
      cancha: cancha,
      fecha: _fechaSeleccionada,
      horaInicio: _aMinutos(_horaInicio),
      horaFin: _aMinutos(_horaFin),
      descripcion: _descripcionCtrl.text,
    );
    if (!mounted) return;
    if (error == null) {
      _tituloCtrl.clear();
      _descripcionCtrl.clear();
      setState(() => _fechaSeleccionada = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green[700],
          content: const Text('Evento creado y publicado en los horarios.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red[700], content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SamanColors.niebla,
      appBar: AppBar(
        title: const Text('Eventos y Torneos'),
        backgroundColor: _azul,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GestionCanchasView()),
            ),
            icon: const Icon(Icons.stadium, color: Colors.white),
            label: const Text(
              'Canchas',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final deportes = _controller.deportes;
          final canchas = _controller.canchasActivas;
          final deporteValido = deportes.any(
            (d) => d.id == _deporteIdSeleccionado,
          );
          final canchaValida = canchas.any(
            (c) => c.id == _canchaIdSeleccionada,
          );

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Form(
                    key: _formKey,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Programar nuevo evento',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              key: const Key('campo-titulo-evento'),
                              controller: _tituloCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Título del evento / torneo',
                                hintText: 'Ej. Copa UNIMET - Fase de Grupos',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => (v ?? '').trim().isEmpty
                                  ? 'Ingresa el título del evento'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              key: const Key('selector-deporte-evento'),
                              initialValue: deporteValido
                                  ? _deporteIdSeleccionado
                                  : null,
                              decoration: const InputDecoration(
                                labelText: 'Disciplina / Deporte',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                for (final Deporte d in deportes)
                                  DropdownMenuItem(
                                    value: d.id,
                                    child: Text(d.nombre),
                                  ),
                              ],
                              onChanged: (val) =>
                                  setState(() => _deporteIdSeleccionado = val),
                              validator: (v) =>
                                  v == null ? 'Selecciona un deporte' : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    key: const Key('selector-cancha-evento'),
                                    initialValue: canchaValida
                                        ? _canchaIdSeleccionada
                                        : null,
                                    decoration: const InputDecoration(
                                      labelText: 'Cancha asignada',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: [
                                      for (final Cancha c in canchas)
                                        DropdownMenuItem(
                                          value: c.id,
                                          child: Text(c.nombreConUbicacion),
                                        ),
                                    ],
                                    onChanged: (val) => setState(
                                      () => _canchaIdSeleccionada = val,
                                    ),
                                    validator: (v) => v == null
                                        ? 'Selecciona una cancha'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: IconButton.filled(
                                    tooltip: 'Agregar cancha a la lista',
                                    style: IconButton.styleFrom(
                                      backgroundColor: _azul,
                                    ),
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const GestionCanchasView(),
                                      ),
                                    ),
                                    icon: const Icon(Icons.add),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _elegirFecha,
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _fechaSeleccionada == null
                                    ? 'Seleccionar fecha del evento'
                                    : fechaLarga(_fechaSeleccionada!),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _elegirHora(esInicio: true),
                                    icon: const Icon(Icons.access_time),
                                    label: Text(
                                      'Inicio: ${BloqueHorario.horaTexto(_aMinutos(_horaInicio))}',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _elegirHora(esInicio: false),
                                    icon: const Icon(Icons.access_time_filled),
                                    label: Text(
                                      'Fin: ${BloqueHorario.horaTexto(_aMinutos(_horaFin))}',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _descripcionCtrl,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Descripción / Notas (opcional)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              key: const Key('boton-guardar-evento'),
                              style: FilledButton.styleFrom(
                                backgroundColor: _naranja,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                              ),
                              onPressed:
                                  _controller.guardando ? null : _guardar,
                              icon: const Icon(Icons.emoji_events),
                              label: const Text('Publicar Evento'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Eventos programados',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (_controller.cargando)
                    const Center(child: CircularProgressIndicator())
                  else if (_controller.eventos.isEmpty)
                    const Text(
                      'No hay eventos programados.',
                      style: TextStyle(color: Colors.black54),
                    )
                  else
                    for (final evento in _controller.eventos)
                      _tarjetaEvento(evento),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tarjetaEvento(EventoDeportivo evento) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.emoji_events, color: _naranja),
        title: Text(
          evento.titulo,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${evento.deporteNombre} · ${fechaLarga(evento.fecha)}\n'
          '${evento.horarioTexto} · ${evento.canchaNombre}',
        ),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: 'Eliminar evento',
          icon: Icon(Icons.delete_outline, color: Colors.red[700]),
          onPressed: () => _controller.eliminarEvento(evento),
        ),
      ),
    );
  }
}