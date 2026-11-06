import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';

const _azul = Color(0xFF003B82);
const _naranja = Color(0xFFFF8C2A);

class CrearDeporteView extends StatefulWidget {
  const CrearDeporteView({super.key});

  @override
  State<CrearDeporteView> createState() => _CrearDeporteViewState();
}

class _CrearDeporteViewState extends State<CrearDeporteView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _disciplinaCtrl = TextEditingController();
  final _horarioCtrl = TextEditingController();
  final _lugarCtrl = TextEditingController();
  final _cuposCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();

  final List<String> _etiquetas = [];
  bool _guardando = false;

  void _agregarEtiqueta() {
    final texto = _tagCtrl.text.trim();
    if (texto.isNotEmpty && !_etiquetas.contains(texto)) {
      setState(() {
        _etiquetas.add(texto);
        _tagCtrl.clear();
      });
    }
  }

  Future<void> _guardarDeporte() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      await FirestoreService.instance.sports.add({
        'nombre': _nombreCtrl.text.trim(),
        'disciplina': _disciplinaCtrl.text.trim(),
        'horarios': [_horarioCtrl.text.trim()],
        'lugar': _lugarCtrl.text.trim(),
        'cupos': int.tryParse(_cuposCtrl.text) ?? 20,
        'entrenadorId': '',
        'etiquetas': _etiquetas,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear deporte: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nueva Disciplina'),
        backgroundColor: _azul,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Deporte',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Ingrese el nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _disciplinaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Categoría / Disciplina',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _horarioCtrl,
                decoration: const InputDecoration(
                  labelText: 'Horario (ej. Lun y Mié 2:00 PM - 4:00 PM)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Ingrese el horario' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lugarCtrl,
                decoration: const InputDecoration(
                  labelText: 'Lugar / Cancha',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cuposCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cupos Máximos',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v!.isEmpty ? 'Ingrese la cantidad de cupos' : null,
              ),
              const SizedBox(height: 16),
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
                    .map((tag) => Chip(
                          label: Text('#$tag'),
                          onDeleted: () =>
                              setState(() => _etiquetas.remove(tag)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _naranja,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _guardando ? null : _guardarDeporte,
                child: const Text('Guardar Deporte',
                    style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deporte.nombre), // Muestra el nombre de la disciplina
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 1. Información del Deporte (Puedes reutilizar tus widgets de tarjeta)
              Text(
                'Reseñas de la comunidad',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // 2. Formulario para comentar
              _construirFormulario(),
              const Divider(height: 32),

              // 3. Mostrar errores si la regla de negocio falla (ej. No inscrito)
              if (_controller.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _controller.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              // 4. Lista (Feed) de reseñas
              _construirListaResenas(),
            ],
          );
        },
      ),
    );
  }

Widget _construirFormulario() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selector de calificación simple
          DropdownButtonFormField<int>(
            value: _calificacion,
            decoration: const InputDecoration(
              labelText: 'Calificación',
              border: OutlineInputBorder(),
            ),
            items: [1, 2, 3, 4, 5].map((e) => DropdownMenuItem(
              value: e,
              child: Text('$e Estrellas'),
            )).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _calificacion = val);
            },
          ),
          const SizedBox(height: 12),
          // Input del comentario
          TextFormField(
            controller: _comentarioCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Cuéntanos tu experiencia',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) 
                ? 'El comentario es obligatorio' 
                : null,
          ),
          const SizedBox(height: 16),
          // Botón de guardado con manejo de estado
          FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            // Deshabilitar botón si ya se está enviando a Firebase
            onPressed: _controller.enviando ? null : _enviarResena,
            child: _controller.enviando 
                ? const SizedBox(
                    height: 20, width: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : const Text('Publicar Reseña'),
          ),
        ],
      ),
    );
  }

  Future<void> _enviarResena() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Llamamos a la lógica de negocio del controlador
    final exito = await _controller.publicarResena(
      _calificacion, 
      _comentarioCtrl.text,
    );

    if (exito) {
      _comentarioCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reseña publicada con éxito')),
        );
      }
    }
  }

  Widget _construirListaResenas() {
    if (_controller.cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    final resenas = _controller.resenas ?? [];
    if (resenas.isEmpty) {
      return const Text('Aún no hay reseñas. ¡Sé el primero en comentar!');
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // Evita conflicto de scroll con el ListView padre
      itemCount: resenas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final r = resenas[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.star, color: Colors.amber),
            title: Text('${r.calificacion} Estrellas'),
            subtitle: Text(r.comentario),
            trailing: Text(
              '${r.fecha.day}/${r.fecha.month}/${r.fecha.year}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}
