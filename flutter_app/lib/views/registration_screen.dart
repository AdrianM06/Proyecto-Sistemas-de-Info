import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../navigation/app_routes.dart';
import '../services/auth_service.dart';
import '../utils/app_validators.dart';
import '../utils/imagenes.dart';
import 'widgets/boton_volver_inicio.dart';

const _panelGray = Color(0xFFD9D9D9);
const _buttonBrown = Color(0xFF514943);
const _navy = Color(0xFF003B82);

/// Registro público de estudiantes (ruta `/registro`).
///
/// Pide Nombre, Apellido, Correo estudiantil (@correo.unimet.edu.ve),
/// Cédula, Carnet (11 dígitos) y Contraseña (con confirmación). Todos son
/// obligatorios y se validan antes de enviar nada a Firebase; luego
/// `AuthService` los vuelve a revisar y las reglas de Firestore también.
///
/// Los entrenadores ya no se registran aquí: los crea el administrador desde
/// su panel.
class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 760) {
            return Row(
              children: [
                const Expanded(child: _RegistrationHero()),
                Expanded(
                  child: Container(
                    color: _panelGray,
                    child: LayoutBuilder(
                      builder: (context, panelConstraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: panelConstraints.maxHeight,
                            ),
                            child: const _RegistrationContent(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          }

          return Container(
            color: _panelGray,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 320, child: _RegistrationHero()),
                  const _RegistrationContent(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RegistrationHero extends StatelessWidget {
  const _RegistrationHero();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/padel_stock_photo.jpg', fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.35),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.15),
              ],
            ),
          ),
        ),
        Positioned(
          top: 28,
          left: 28,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/unimet_sports_logo.png',
                width: 184,
                height: 68,
                cacheWidth: pixelesFisicos(context, 184),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RegistrationContent extends StatefulWidget {
  const _RegistrationContent();

  @override
  State<_RegistrationContent> createState() => _RegistrationContentState();
}

class _RegistrationContentState extends State<_RegistrationContent> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _carnetController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmacionController = TextEditingController();

  bool _isLoading = false;
  bool _mostrarClave = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _cedulaController.dispose();
    _carnetController.dispose();
    _passwordController.dispose();
    _confirmacionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final sesion = await AuthService.instance.registerUser(
        nombre: _nombreController.text,
        apellido: _apellidoController.text,
        email: _emailController.text,
        cedula: _cedulaController.text,
        carnet: _carnetController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('¡Cuenta creada con éxito!'),
        ),
      );

      // La cuenta queda con la sesión iniciada: se va directo a su vista.
      AppRoutes.irAVistaDelRol(context, sesion);
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Error al registrar usuario';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'El correo electrónico ya está registrado.';
      } else if (e.code == 'carnet-already-in-use') {
        errorMessage = 'Ese carnet ya está registrado.';
      } else if (e.code == 'cedula-already-in-use') {
        errorMessage = 'Esa cédula ya está registrada.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'El correo no tiene un formato válido.';
      } else if (e.code == 'network-request-failed') {
        errorMessage = 'Sin conexión. Revisa tu internet e intenta de nuevo.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'La contraseña debe tener mayor seguridad.';
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(errorMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('No se pudo crear la cuenta. Intenta de nuevo.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 500 ? 20.0 : 40.0;
        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 560),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 38,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: BotonVolverInicio(),
                ),
                const SizedBox(height: 8),
                const Text(
                  'REGISTRACIÓN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 25,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Registro de estudiantes · ¿Eres entrenador? Tu cuenta la crea el administrador.',
                  key: Key('registro-nota-entrenadores'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _RegistrationField(
                                  fieldKey: const Key('registro-nombre'),
                                  label: 'Nombre',
                                  controller: _nombreController,
                                  capitalization: TextCapitalization.words,
                                  validator: AppValidators.validateNombre,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _RegistrationField(
                                  fieldKey: const Key('registro-apellido'),
                                  label: 'Apellido',
                                  controller: _apellidoController,
                                  capitalization: TextCapitalization.words,
                                  validator: AppValidators.validateApellido,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _RegistrationField(
                            fieldKey: const Key('registro-correo'),
                            label: 'Correo Electrónico Unimet',
                            hint: 'nombre@correo.unimet.edu.ve',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: AppValidators.validateEmailEstudiante,
                          ),
                          const SizedBox(height: 16),
                          _RegistrationField(
                            fieldKey: const Key('registro-cedula'),
                            label: 'Cédula de Identidad',
                            hint: 'V-12345678',
                            controller: _cedulaController,
                            validator: AppValidators.validateCedula,
                          ),
                          const SizedBox(height: 16),
                          _RegistrationField(
                            fieldKey: const Key('registro-carnet'),
                            label: 'Carnet Universitario',
                            hint: '11 dígitos, ej. 20221110045',
                            controller: _carnetController,
                            keyboardType: TextInputType.number,
                            maxLength: 11,
                            validator: AppValidators.validateCarnet,
                          ),
                          const SizedBox(height: 16),
                          _RegistrationField(
                            fieldKey: const Key('registro-clave'),
                            label: 'Contraseña',
                            hint: 'Mínimo 8 caracteres, una mayúscula y un número',
                            controller: _passwordController,
                            obscureText: !_mostrarClave,
                            validator: AppValidators.validatePassword,
                            suffix: IconButton(
                              tooltip: _mostrarClave
                                  ? 'Ocultar contraseña'
                                  : 'Mostrar contraseña',
                              icon: Icon(
                                _mostrarClave
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                () => _mostrarClave = !_mostrarClave,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _RegistrationField(
                            fieldKey: const Key('registro-confirmar-clave'),
                            label: 'Confirmar contraseña',
                            controller: _confirmacionController,
                            obscureText: !_mostrarClave,
                            validator: (valor) =>
                                AppValidators.validateConfirmacion(
                                  valor,
                                  _passwordController.text,
                                ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            key: const Key('boton-registrar'),
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _buttonBrown,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Crear Cuenta',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    final navigator = Navigator.of(context);
                    if (navigator.canPop()) {
                      navigator.pop();
                    } else {
                      navigator.pushReplacementNamed(AppRoutes.login);
                    }
                  },
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                      children: [
                        const TextSpan(
                          text: 'ya tiene una cuenta? inicie sesión ',
                        ),
                        TextSpan(
                          text: 'aqui',
                          style: const TextStyle(
                            color: _navy,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RegistrationField extends StatelessWidget {
  const _RegistrationField({
    required this.label,
    this.fieldKey,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.capitalization = TextCapitalization.none,
    this.maxLength,
    this.suffix,
  });

  final String label;
  final Key? fieldKey;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextCapitalization capitalization;
  final int? maxLength;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black)),
        const SizedBox(height: 4),
        TextFormField(
          key: fieldKey,
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          textCapitalization: capitalization,
          maxLength: maxLength,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            isDense: true,
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: Colors.black38),
            errorMaxLines: 2,
            counterText: '',
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}
