import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';

const _naranja = Color(0xFFFF8C2A);

class EditarDatosEstudianteDialog extends StatefulWidget {
  const EditarDatosEstudianteDialog({
    super.key,
    required this.nombreActual,
    required this.apellidoActual,
    required this.cedulaActual,
    required this.carnetActual,
  });

  final String nombreActual;
  final String apellidoActual;
  final String cedulaActual;
  final String carnetActual;

  @override
  State<EditarDatosEstudianteDialog> createState() =>
      _EditarDatosEstudianteDialogState();
}

class _EditarDatosEstudianteDialogState
    extends State<EditarDatosEstudianteDialog> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _apellidoCtrl;
  late final TextEditingController _cedulaCtrl;
  late final TextEditingController _carnetCtrl;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.nombreActual);
    _apellidoCtrl = TextEditingController(text: widget.apellidoActual);
    _cedulaCtrl = TextEditingController(text: widget.cedulaActual);
    _carnetCtrl = TextEditingController(text: widget.carnetActual);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _cedulaCtrl.dispose();
    _carnetCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    setState(() => _guardando = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirestoreService.instance.users.doc(uid).update({
          'nombre': _nombreCtrl.text.trim(),
          'apellido': _apellidoCtrl.text.trim(),
          'cedula': _cedulaCtrl.text.trim(),
          'carnet': _carnetCtrl.text.trim(),
        });
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar datos: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Mis Datos Personales'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apellidoCtrl,
              decoration: const InputDecoration(
                labelText: 'Apellido',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cedulaCtrl,
              decoration: const InputDecoration(
                labelText: 'Cédula de Identidad',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _carnetCtrl,
              decoration: const InputDecoration(
                labelText: 'Número de Carnet',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _naranja),
          onPressed: _guardando ? null : _guardarCambios,
          child: _guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Guardar Cambios'),
        ),
      ],
    );
  }
}