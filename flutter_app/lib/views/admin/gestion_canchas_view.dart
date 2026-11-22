import 'package:flutter/material.dart';

import '../../controllers/gestion_canchas_controller.dart';
import '../../models/cancha.dart';
import '../theme/saman_colors.dart';

const _azul = Color(0xFF003B82);
const _naranja = Color(0xFFF58220);

class GestionCanchasView extends StatefulWidget {
  const GestionCanchasView({super.key, this.controller});

  final GestionCanchasController? controller;

  @override
  State<GestionCanchasView> createState() => _GestionCanchasViewState();
}

class _GestionCanchasViewState extends State<GestionCanchasView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();
  late final GestionCanchasController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? GestionCanchasController();
    _controller.iniciar();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _ubicacionCtrl.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  Future<void> _agregar() async {
    if (!_formKey.currentState!.validate()) return;
    final error = await _controller.agregarCancha(
      nombre: _nombreCtrl.text,
      ubicacion: _ubicacionCtrl.text,
    );
    if (!mounted) return;
    if (error == null) {
      _nombreCtrl.clear();
      _ubicacionCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green[700],
          content: const Text('Cancha agregada a la lista.'),
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
        title: const Text('Gestión de Canchas'),
        backgroundColor: _azul,
        foregroundColor: Colors.white,
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
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
                              'Agregar nueva cancha',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              key: const Key('campo-nombre-cancha'),
                              controller: _nombreCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Nombre de la cancha',
                                hintText: 'Ej. Cancha Techada 1',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => (v ?? '').trim().isEmpty
                                  ? 'Ingresa el nombre de la cancha'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _ubicacionCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Ubicación / Referencia (opcional)',
                                hintText: 'Ej. Complejo Deportivo Sur',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 14),
                            FilledButton.icon(
                              key: const Key('boton-agregar-cancha'),
                              style: FilledButton.styleFrom(
                                backgroundColor: _naranja,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed:
                                  _controller.guardando ? null : _agregar,
                              icon: const Icon(Icons.add_location_alt),
                              label: const Text('Agregar Cancha'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Canchas registradas',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (_controller.cargando)
                    const Center(child: CircularProgressIndicator())
                  else if (_controller.error != null)
                    Text(
                      _controller.error!,
                      style: TextStyle(color: Colors.red[700]),
                    )
                  else if (_controller.canchas.isEmpty)
                    const Text(
                      'Aún no hay canchas registradas.',
                      style: TextStyle(color: Colors.black54),
                    )
                  else
                    for (final cancha in _controller.canchas)
                      _tarjetaCancha(cancha),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tarjetaCancha(Cancha cancha) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.stadium_outlined,
          color: cancha.activa ? _azul : Colors.grey,
        ),
        title: Text(
          cancha.nombre,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: cancha.activa ? Colors.black87 : Colors.black45,
          ),
        ),
        subtitle: cancha.ubicacion.isEmpty ? null : Text(cancha.ubicacion),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: cancha.activa,
              activeThumbColor: _naranja,
              onChanged: (valor) => _controller.cambiarEstado(cancha, valor),
            ),
            IconButton(
              tooltip: 'Eliminar cancha',
              icon: Icon(Icons.delete_outline, color: Colors.red[700]),
              onPressed: () => _controller.eliminarCancha(cancha),
            ),
          ],
        ),
      ),
    );
  }
}