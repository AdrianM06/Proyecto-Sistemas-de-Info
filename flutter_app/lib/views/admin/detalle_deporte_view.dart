import 'package:flutter/material.dart';

// Rutas ajustadas para subir dos niveles (../../) desde lib/views/admin/
import '../../models/deporte.dart';
import '../../controllers/detalle_deporte_controller.dart';
import '../../services/resena_service.dart';

class DetalleDeporteView extends StatefulWidget {
  const DetalleDeporteView({
    super.key,
    required this.deporte,
    required this.estudianteId,
  });

  final Deporte deporte;
  final String estudianteId;

  @override
  State<DetalleDeporteView> createState() => _DetalleDeporteViewState();
}

class _DetalleDeporteViewState extends State<DetalleDeporteView> {
  late DetalleDeporteController _controller;
  final _formKey = GlobalKey<FormState>();
  final _comentarioCtrl = TextEditingController();
  int _calificacion = 5;

  @override
  void initState() {
    super.initState();
    _controller = DetalleDeporteController(
      deporteId: widget.deporte.id,
      estudianteId: widget.estudianteId,
      datos: ResenasService(),
    );
    _controller.iniciar();
  }

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.deporte.nombre)),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                'Reseñas de la comunidad',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _construirFormulario(),
              const Divider(height: 32),
              if (_controller.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _controller.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
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
          FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
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
      physics: const NeverScrollableScrollPhysics(),
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
