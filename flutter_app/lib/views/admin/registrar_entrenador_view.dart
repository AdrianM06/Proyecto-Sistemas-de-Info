import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/deporte.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_validators.dart';

const _azul = Color(0xFF003B82);
const _naranja = Color(0xFFF58220);

/// Formulario del panel del administrador para registrar entrenadores
/// (ruta `/admin/entrenadores/nuevo`, solo para el rol admin).
///
/// Crea la cuenta del entrenador con una contraseña temporal, guarda su
/// perfil con `rol: "entrenador"` y, si se elige, le asigna una disciplina.
class RegistrarEntrenadorView extends StatefulWidget {
  const RegistrarEntrenadorView({super.key});

  @override
  State<RegistrarEntrenadorView> createState() =>
      _RegistrarEntrenadorViewState();
}

class _RegistrarEntrenadorViewState extends State<RegistrarEntrenadorView> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _correo = TextEditingController();
  final _carnet = TextEditingController();
  final _cedula = TextEditingController();
  final _telefono = TextEditingController();
  final _clave = TextEditingController();

  late final Future<List<Deporte>> _deportes = _cargarDeportes();
  String? _deporteId;
  bool _guardando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _correo.dispose();
    _carnet.dispose();
    _cedula.dispose();
    _telefono.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<List<Deporte>> _cargarDeportes() async {
    final resultado = await FirestoreService.instance.sports.get();
    return resultado.docs.map(Deporte.fromFirestore).toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  static String? _obligatorio(String? valor, String campo) {
    if (valor == null || valor.trim().isEmpty) return 'Escribe $campo';
    return null;
  }

  static String? _validarCorreo(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return 'Escribe el correo';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(texto)) {
      return 'El correo no tiene un formato válido';
    }
    return null;
  }

  String _mensajeDeError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'Ya existe una cuenta con ese correo.';
        case 'invalid-email':
          return 'El correo no tiene un formato válido.';
        case 'weak-password':
          return 'La contraseña temporal es muy débil.';
        case 'no-autorizado':
          return error.message ?? 'No tienes permiso para registrar entrenadores.';
      }
      if (error.message != null) return error.message!;
    }
    return 'No se pudo registrar al entrenador. Intenta de nuevo.';
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final mensajero = ScaffoldMessenger.of(context);
    try {
      await AuthService.instance.registrarEntrenador(
        email: _correo.text,
        nombre: _nombre.text,
        apellido: _apellido.text,
        carnet: _carnet.text,
        password: _clave.text,
        cedula: _cedula.text,
        telefono: _telefono.text,
        deporteId: _deporteId,
      );
      final nombreCompleto = '${_nombre.text.trim()} ${_apellido.text.trim()}';
      if (!mounted) return;
      _formKey.currentState?.reset();
      for (final campo in [
        _nombre,
        _apellido,
        _correo,
        _carnet,
        _cedula,
        _telefono,
        _clave,
      ]) {
        campo.clear();
      }
      setState(() => _deporteId = null);
      mensajero.showSnackBar(
        SnackBar(
          backgroundColor: Colors.green[700],
          content: Text('Entrenador registrado: $nombreCompleto.'),
        ),
      );
    } catch (e) {
      mensajero.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red[700],
          content: Text(_mensajeDeError(e)),
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  InputDecoration _decoracion(String etiqueta, {String? ayuda}) {
    return InputDecoration(
      labelText: etiqueta,
      helperText: ayuda,
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar entrenador'),
        backgroundColor: _azul,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Los entrenadores solo se registran desde este panel. '
                  'Comparte con el entrenador su correo o su carnet y la '
                  'contraseña temporal para que inicie sesión.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('entrenador-nombre'),
                        controller: _nombre,
                        decoration: _decoracion('Nombre'),
                        validator: (v) => _obligatorio(v, 'el nombre'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: const Key('entrenador-apellido'),
                        controller: _apellido,
                        decoration: _decoracion('Apellido'),
                        validator: (v) => _obligatorio(v, 'el apellido'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('entrenador-correo'),
                  controller: _correo,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _decoracion('Correo electrónico'),
                  validator: _validarCorreo,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('entrenador-carnet'),
                  controller: _carnet,
                  keyboardType: TextInputType.number,
                  decoration: _decoracion(
                    'Carnet',
                    ayuda: '11 dígitos, empieza por el año (ej. 20221110045). '
                        'Con el carnet también inicia sesión.',
                  ),
                  validator: AppValidators.validateCarnet,
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('entrenador-cedula'),
                        controller: _cedula,
                        keyboardType: TextInputType.number,
                        decoration: _decoracion('Cédula (opcional)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: const Key('entrenador-telefono'),
                        controller: _telefono,
                        keyboardType: TextInputType.phone,
                        decoration: _decoracion('Teléfono (opcional)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('entrenador-clave'),
                  controller: _clave,
                  obscureText: true,
                  decoration: _decoracion(
                    'Contraseña temporal',
                    ayuda: 'Mínimo 8 caracteres, una mayúscula y un número.',
                  ),
                  validator: AppValidators.validatePassword,
                ),
                const SizedBox(height: 14),
                FutureBuilder<List<Deporte>>(
                  future: _deportes,
                  builder: (context, snapshot) {
                    final deportes = snapshot.data ?? const <Deporte>[];
                    return DropdownButtonFormField<String?>(
                      key: const Key('entrenador-disciplina'),
                      initialValue: _deporteId,
                      decoration: _decoracion(
                        'Disciplina asignada (opcional)',
                        ayuda: snapshot.hasError
                            ? 'No se pudieron cargar las disciplinas.'
                            : null,
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Sin asignar por ahora'),
                        ),
                        for (final deporte in deportes)
                          DropdownMenuItem<String?>(
                            value: deporte.id,
                            child: Text(
                              deporte.sinEntrenadores
                                  ? deporte.nombre
                                  : '${deporte.nombre} (entrenadores: ${deporte.entrenadoresIds.length})',
                            ),
                          ),
                      ],
                      onChanged: _guardando
                          ? null
                          : (valor) => setState(() => _deporteId = valor),
                    );
                  },
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const Key('boton-registrar-entrenador'),
                  onPressed: _guardando ? null : _registrar,
                  style: FilledButton.styleFrom(
                    backgroundColor: _naranja,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: _guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.person_add_alt_1),
                  label: const Text(
                    'Registrar entrenador',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
