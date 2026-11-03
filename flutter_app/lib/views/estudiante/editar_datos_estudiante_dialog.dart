import 'package:flutter/material.dart';

import '../../utils/app_validators.dart';

const _naranja = Color(0xFFFF8C2A);

/// Diálogo "Editar mis datos" del perfil del estudiante.
///
/// Se pueden cambiar el **nombre** y el **apellido**. El **carnet** y la
/// **cédula** se muestran bloqueados (solo lectura): no se pueden modificar
/// después del registro. Las reglas de Firestore también lo impiden.
///
/// [onGuardar] guarda los cambios y devuelve un mensaje de error, o `null`
/// si todo salió bien (entonces el diálogo se cierra con `true`).
class EditarDatosEstudianteDialog extends StatefulWidget {
  const EditarDatosEstudianteDialog({
    super.key,
    required this.nombreActual,
    required this.apellidoActual,
    required this.cedulaActual,
    required this.carnetActual,
    required this.onGuardar,
  });

  final String nombreActual;
  final String apellidoActual;
  final String cedulaActual;
  final String carnetActual;
  final Future<String?> Function(String nombre, String apellido) onGuardar;

  @override
  State<EditarDatosEstudianteDialog> createState() =>
      _EditarDatosEstudianteDialogState();
}

class _EditarDatosEstudianteDialogState
    extends State<EditarDatosEstudianteDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _apellidoCtrl;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.nombreActual);
    _apellidoCtrl = TextEditingController(text: widget.apellidoActual);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    final navigator = Navigator.of(context);
    final error = await widget.onGuardar(_nombreCtrl.text, _apellidoCtrl.text);
    if (!mounted) return;
    if (error == null) {
      navigator.pop(true);
      return;
    }
    setState(() {
      _guardando = false;
      _error = error;
    });
  }

  Widget _campoBloqueado({
    required Key key,
    required String etiqueta,
    required String valor,
  }) {
    return TextFormField(
      key: key,
      initialValue: valor.isEmpty ? 'Sin registrar' : valor,
      readOnly: true,
      enabled: false,
      decoration: InputDecoration(
        labelText: etiqueta,
        helperText: 'No se puede modificar',
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.lock_outline),
        filled: true,
        fillColor: const Color(0xFFF2F2F7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('dialogo-editar-datos'),
      title: const Text('Editar mis datos'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const Key('editar-nombre'),
                  controller: _nombreCtrl,
                  enabled: !_guardando,
                  textCapitalization: TextCapitalization.words,
                  validator: AppValidators.validateNombre,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('editar-apellido'),
                  controller: _apellidoCtrl,
                  enabled: !_guardando,
                  textCapitalization: TextCapitalization.words,
                  validator: AppValidators.validateApellido,
                  decoration: const InputDecoration(
                    labelText: 'Apellido',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                _campoBloqueado(
                  key: const Key('editar-cedula'),
                  etiqueta: 'Cédula de identidad',
                  valor: widget.cedulaActual,
                ),
                const SizedBox(height: 12),
                _campoBloqueado(
                  key: const Key('editar-carnet'),
                  etiqueta: 'Carnet universitario',
                  valor: widget.carnetActual,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    key: const Key('error-editar-datos'),
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('guardar-datos'),
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
              : const Text('Guardar cambios'),
        ),
      ],
    );
  }
}
