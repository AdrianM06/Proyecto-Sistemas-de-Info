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