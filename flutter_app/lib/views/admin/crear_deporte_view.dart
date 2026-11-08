import 'package:flutter/material.dart';

import '../../controllers/formulario_disciplina_controller.dart';
import '../../models/deporte.dart';
import '../../models/usuario.dart';
import '../../services/gestion_entrenadores_service.dart';
import '../../utils/horarios.dart';

const _azul = Color(0xFF003B82);
const _naranja = Color(0xFFFF8C2A);

/// Formulario del administrador para crear una disciplina o, con [deporte],
/// editarla.
///
/// Los horarios se agregan uno por uno y se interpretan al momento (día,
/// hora de inicio y hora de fin); la disciplina puede tener varios
/// entrenadores y no se puede elegir uno cuyo horario choque.
class CrearDeporteView extends StatefulWidget {
  const CrearDeporteView({super.key, this.deporte, this.controller});

  /// Disciplina a editar; `null` para crear una nueva.
  final Deporte? deporte;

  /// Controlador para las pruebas. Por defecto se conecta a Firestore. La
  /// vista lo libera al cerrarse.
  final FormularioDisciplinaController? controller;

  @override
  State<CrearDeporteView> createState() => _CrearDeporteViewState();
}

class _CrearDeporteViewState extends State<CrearDeporteView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _disciplinaCtrl;
  late final TextEditingController _lugarCtrl;
  late final TextEditingController _cuposCtrl;
  final _horarioCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  late final FormularioDisciplinaController _controller;

  late final List<String> _etiquetas;
  String? _errorHorario;

  @override
  void initState() {
    super.initState();
    final deporte = widget.deporte;
    _nombreCtrl = TextEditingController(text: deporte?.nombre ?? '');
    _disciplinaCtrl = TextEditingController(text: deporte?.disciplina ?? '');
    _lugarCtrl = TextEditingController(text: deporte?.lugar ?? '');
    _cuposCtrl = TextEditingController(
      text: deporte == null ? '' : '${deporte.cupos}',
    );
    _etiquetas = [...?deporte?.etiquetas];
    _controller =
        widget.controller ??
        FormularioDisciplinaController(
          datos: GestionEntrenadoresService(),
          original: deporte,
        );
    _controller.iniciar();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _disciplinaCtrl.dispose();
    _lugarCtrl.dispose();
    _cuposCtrl.dispose();
    _horarioCtrl.dispose();
    _tagCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _agregarEtiqueta() {
    final texto = _tagCtrl.text.trim();
    if (texto.isNotEmpty && !_etiquetas.contains(texto)) {
      setState(() {
        _etiquetas.add(texto);
        _tagCtrl.clear();
      });
    }
  }

  void _agregarHorario() {
    final error = _controller.agregarHorario(_horarioCtrl.text);
    setState(() => _errorHorario = error);
    if (error == null) _horarioCtrl.clear();
  }

  Future<void> _alternarEntrenador(Usuario entrenador) async {
    final choque = _controller.alternarEntrenador(
      entrenador,
      nombreDisciplina: _nombreCtrl.text,
    );
    if (choque != null) await _mostrarChoque(choque);
  }

  Future<void> _mostrarChoque(String mensaje) {
    return showDialog<void>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        key: const Key('dialogo-choque-horario'),
        icon: Icon(Icons.event_busy, color: Colors.red[700], size: 36),
        title: const Text('Choque de horario'),
        content: Text(mensaje),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(contextoDialogo).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final error = await _controller.guardar(
      nombre: _nombreCtrl.text,
      disciplina: _disciplinaCtrl.text,
      lugar: _lugarCtrl.text,
      cupos: int.tryParse(_cuposCtrl.text.trim()) ?? 0,
      etiquetas: List.of(_etiquetas),
    );
    if (!mounted) return;
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green[700],
          content: Text(
            _controller.editando
                ? 'Disciplina actualizada.'
                : 'Disciplina creada.',
          ),
        ),
      );
      Navigator.of(context).maybePop();
    } else if (_controller.ultimoErrorFueChoque) {
      await _mostrarChoque(error);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red[700], content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _controller.editando ? 'Editar disciplina' : 'Crear Nueva Disciplina',
        ),
        backgroundColor: _azul,
        foregroundColor: Colors.white,
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    key: const Key('campo-nombre-disciplina'),
                    controller: _nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Deporte',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Ingrese el nombre' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _disciplinaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Categoría / Disciplina',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _seccionHorarios(),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _lugarCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Lugar / Cancha',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('campo-cupos'),
                    controller: _cuposCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cupos Máximos',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final cupos = int.tryParse((v ?? '').trim());
                      if (cupos == null) return 'Ingrese la cantidad de cupos';
                      if (cupos <= 0) return 'Debe ser mayor que cero';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _seccionEntrenadores(),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tagCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Añadir Etiqueta (ej. Principiante)',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _agregarEtiqueta(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: _azul),
                        onPressed: _agregarEtiqueta,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _etiquetas
                        .map(
                          (tag) => Chip(
                            label: Text('#$tag'),
                            onDeleted: () =>
                                setState(() => _etiquetas.remove(tag)),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('boton-guardar-disciplina'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _naranja,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _controller.guardando ? null : _guardar,
                    child: _controller.guardando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _controller.editando
                                ? 'Guardar cambios'
                                : 'Guardar Deporte',
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _titulo(String texto) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      texto,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
  );

  Widget _seccionHorarios() {
    final horarios = _controller.horarios;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _titulo('Horarios'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                key: const Key('campo-horario'),
                controller: _horarioCtrl,
                onSubmitted: (_) => _agregarHorario(),
                decoration: InputDecoration(
                  labelText: 'Horario',
                  hintText: 'Lun y Mié 4:00 pm - 6:00 pm',
                  helperText:
                      'Días, hora de inicio y hora de fin (am/pm o 24 h).',
                  errorText: _errorHorario,
                  errorMaxLines: 3,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: IconButton.filled(
                key: const Key('agregar-horario'),
                tooltip: 'Agregar horario',
                style: IconButton.styleFrom(backgroundColor: _azul),
                onPressed: _agregarHorario,
                icon: const Icon(Icons.add),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (horarios.isEmpty)
          const Text(
            'Todavía no hay horarios.',
            style: TextStyle(color: Colors.black54),
          ),
        for (final horario in horarios) _filaHorario(horario),
      ],
    );
  }

  static String _duracion(Duration duracion) {
    final horas = duracion.inMinutes ~/ 60;
    final minutos = duracion.inMinutes % 60;
    if (horas == 0) return '$minutos min';
    return minutos == 0 ? '$horas h' : '$horas h $minutos min';
  }

  Widget _filaHorario(String horario) {
    final resultado = interpretarHorario(horario);
    final detalle = resultado.esValido
        ? resultado.bloques
              .map((b) => '${b.texto} (${_duracion(b.duracion)})')
              .join('\n')
        : resultado.error!;
    return Card(
      key: Key('horario-$horario'),
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: Icon(
          resultado.esValido ? Icons.schedule : Icons.warning_amber_rounded,
          color: resultado.esValido ? _azul : Colors.red[700],
        ),
        title: Text(horario),
        subtitle: Text(
          detalle,
          style: TextStyle(
            color: resultado.esValido ? Colors.black54 : Colors.red[700],
          ),
        ),
        trailing: IconButton(
          tooltip: 'Quitar horario',
          onPressed: _controller.guardando
              ? null
              : () => _controller.quitarHorario(horario),
          icon: const Icon(Icons.close),
        ),
      ),
    );
  }

  Widget _seccionEntrenadores() {
    final entrenadores = _controller.entrenadores;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _titulo('Entrenadores (puedes elegir varios)'),
        if (_controller.cargandoEntrenadores)
          const LinearProgressIndicator()
        else if (entrenadores.isEmpty)
          const Text(
            'No hay entrenadores registrados.',
            style: TextStyle(color: Colors.black54),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final entrenador in entrenadores)
                _chipEntrenador(entrenador),
            ],
          ),
      ],
    );
  }

  Widget _chipEntrenador(Usuario entrenador) {
    final elegido = _controller.estaSeleccionado(entrenador);
    final choca = !elegido && _controller.choquesDe(entrenador).isNotEmpty;
    return FilterChip(
      key: Key('elegir-entrenador-${entrenador.uid}'),
      selected: elegido,
      avatar: choca
          ? Icon(Icons.event_busy, size: 18, color: Colors.red[700])
          : null,
      label: Text(entrenador.nombreCompleto),
      tooltip: choca ? 'Su horario choca con esta disciplina' : null,
      onSelected: _controller.guardando
          ? null
          : (_) => _alternarEntrenador(entrenador),
    );
  }
}
