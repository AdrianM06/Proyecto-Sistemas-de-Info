import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../utils/app_validators.dart';

const _panelGray = Color(0xFFD9D9D9);
const _buttonBrown = Color(0xFF514943);
const _navy = Color(0xFF003B82);

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

  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _carnetController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _carnetController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AuthService.instance.registerStudent(
        email: _emailController.text,
        username: _usernameController.text,
        carnet: _carnetController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('¡Cuenta creada e inscrita con éxito en Firebase!'),
        ),
      );

      Navigator.pop(context); // Volver a la pantalla de Inicio de Sesión
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Error al registrar usuario';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'El correo electrónico ya está registrado.';
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
        SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')),
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
                          _RegistrationField(
                            label: 'Correo Electrónico Unimet',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: AppValidators.validateEmail,
                          ),
                          const SizedBox(height: 16),
                          _RegistrationField(
                            label: 'Nombre de Usuario',
                            controller: _usernameController,
                            validator: AppValidators.validateUsername,
                          ),
                          const SizedBox(height: 16),
                          _RegistrationField(
                            label: 'Carnet Universitario',
                            controller: _carnetController,
                            keyboardType: TextInputType.number,
                            validator: AppValidators.validateCarnet,
                          ),
                          const SizedBox(height: 16),
                          _RegistrationField(
                            label: 'Contraseña',
                            controller: _passwordController,
                            obscureText: true,
                            validator: AppValidators.validatePassword,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
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
                    Navigator.pop(context);
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
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
  });

  final String label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }
}