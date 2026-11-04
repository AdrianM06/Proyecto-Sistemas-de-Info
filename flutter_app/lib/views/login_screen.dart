import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';
import '../services/auth_service.dart';
import '../utils/app_validators.dart';
import 'widgets/boton_volver_inicio.dart';

/// Pantalla de inicio de sesión (ruta `/login`).
///
/// "Iniciar Sesión" valida las credenciales con Firebase Authentication,
/// lee el rol del usuario en la colección `users` y lo envía a la vista de
/// su rol (estudiante, entrenador o admin). Si la cuenta no tiene el rol que
/// se eligió, no entra. "Iniciar sesión como Administrador" cambia al acceso
/// del panel admin. "Crear cuenta" abre el registro de estudiantes; las
/// cuentas de entrenador las crea el administrador.

// NO TOCAR ESTOS COLORES, SON DE LA PALETA UNIVERSITARIA, NO MODIFICAR NI DEJAR DE USAR!
const _orange = Color(0xFFF58220);
const _navy = Color(0xFF003B82);
const _panelGray = Color(0xFFD9D9D9);
const _buttonBrown = Color(0xFF514943);

enum UserRole { estudiante, entrenador, admin }

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Desktop / Tablet layout
          if (constraints.maxWidth >= 760) {
            return Row(
              children: [
                const Expanded(child: _SportsHero()),
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
                            child: const _LoginContent(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          }

          // Mobile layout
          return Container(
            color: _panelGray,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 320, child: _SportsHero()),
                  const _LoginContent(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SportsHero extends StatelessWidget {
  const _SportsHero();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Background Photo
        Image.asset(
          'assets/images/tennis_stock_photo.jpg',
          fit: BoxFit.cover,
        ),
        
        // Dark gradient overlay for improved logo contrast
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.4),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.2),
              ],
            ),
          ),
        ),

        // 2. Logo Container floating in the top left
        Positioned(
          top: 28,
          left: 28,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/unimet_sports_logo.png',
              height: 184,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginContent extends StatelessWidget {
  const _LoginContent();

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
                  'INICIAR SESIÓN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 30,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'si no tiene una cuenta ya hecha, registrese ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pushNamed(AppRoutes.registro);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'aquí',
                          style: TextStyle(
                            color: _navy,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 570),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const _LoginForm(),
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

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  UserRole _selectedRole = UserRole.estudiante;
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _mostrarClave = false;

  bool get _modoAdmin => _selectedRole == UserRole.admin;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _rolEsperado {
    switch (_selectedRole) {
      case UserRole.admin:
        return RolesUsuario.admin;
      case UserRole.entrenador:
        return RolesUsuario.entrenador;
      case UserRole.estudiante:
        return RolesUsuario.estudiante;
    }
  }

  void _cambiarRol(UserRole rol) {
    setState(() => _selectedRole = rol);
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);

    try {
      final sesion = await AuthService.instance.iniciarSesion(
        identificador: identifier,
        password: password,
        rolEsperado: _rolEsperado,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            '¡Bienvenido, ${sesion.nombre}! Entraste como '
            '${RolesUsuario.nombreVisible(sesion.rol)}.',
          ),
        ),
      );

      // Redirección según el rol guardado en la base de datos.
      AppRoutes.irAVistaDelRol(context, sesion);
    } on FirebaseAuthException catch (e) {
      String message = 'Credenciales inválidas.';
      if (e.code == 'user-not-found') {
        message = e.message ?? 'El correo o carnet no está registrado.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Correo, carnet o contraseña incorrectos.';
      } else if (e.code == 'invalid-email') {
        message = 'El correo no tiene un formato válido.';
      } else if (e.code == 'user-disabled') {
        message = 'Esta cuenta está deshabilitada.';
      } else if (e.code == 'too-many-requests') {
        message = 'Demasiados intentos. Espera un momento e intenta de nuevo.';
      } else if (e.code == 'network-request-failed') {
        message = 'Sin conexión. Revisa tu internet e intenta de nuevo.';
      } else if (e.message != null) {
        message = e.message!;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('No se pudo iniciar sesión. Intenta de nuevo.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _decoracion({String? ayuda, Widget? sufijo}) {
    return InputDecoration(
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      helperText: ayuda,
      suffixIcon: sufijo,
      errorMaxLines: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_modoAdmin)
            Container(
              key: const Key('aviso-modo-admin'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _navy,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Acceso de administrador',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _RoleOption(
                    label: 'Estudiante',
                    backgroundColor: _orange,
                    isSelected: _selectedRole == UserRole.estudiante,
                    onTap: () => _cambiarRol(UserRole.estudiante),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RoleOption(
                    label: 'Entrenador',
                    backgroundColor: _navy,
                    isSelected: _selectedRole == UserRole.entrenador,
                    onTap: () => _cambiarRol(UserRole.entrenador),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
          Text(
            _modoAdmin ? 'Correo institucional' : 'Correo/Carnet Universitario',
            style: const TextStyle(fontSize: 18, color: Colors.black),
          ),
          const SizedBox(height: 4),
          TextFormField(
            key: const Key('login-identificador'),
            controller: _identifierController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            textInputAction: TextInputAction.next,
            validator: _modoAdmin
                ? AppValidators.validateEmail
                : AppValidators.validateIdentificadorLogin,
            decoration: _decoracion(
              ayuda: _modoAdmin
                  ? 'ej. nombre@unimet.edu.ve'
                  : 'ej. nombre@correo.unimet.edu.ve o 20221110045',
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Contraseña',
            style: TextStyle(fontSize: 18, color: Colors.black),
          ),
          const SizedBox(height: 4),
          TextFormField(
            key: const Key('login-clave'),
            controller: _passwordController,
            obscureText: !_mostrarClave,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _isLoading ? null : _handleLogin(),
            validator: (valor) => (valor == null || valor.isEmpty)
                ? 'Escribe tu contraseña'
                : null,
            decoration: _decoracion(
              sufijo: IconButton(
                key: const Key('login-ver-clave'),
                tooltip: _mostrarClave ? 'Ocultar contraseña' : 'Mostrar contraseña',
                icon: Icon(
                  _mostrarClave ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _mostrarClave = !_mostrarClave),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // El administrador no recupera ni cambia su contraseña desde la app.
          if (!_modoAdmin)
          Wrap(
            key: const Key('enlace-recuperar-clave'),
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'dale click ',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.recuperarContrasena);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'aquí',
                    style: TextStyle(
                      color: _navy,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const Text(
                ' si se le olvidó su contraseña',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            key: const Key('boton-iniciar-sesion'),
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: _modoAdmin ? _navy : _buttonBrown,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    _modoAdmin ? 'Entrar al panel' : 'Iniciar Sesión',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          if (!_modoAdmin)
            OutlinedButton(
              key: const Key('boton-crear-cuenta'),
              onPressed: _isLoading
                  ? null
                  : () {
                      if (_selectedRole == UserRole.entrenador) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Las cuentas de entrenador las crea el administrador. '
                              'Pídele tus datos de acceso.',
                            ),
                          ),
                        );
                        return;
                      }
                      Navigator.of(context).pushNamed(AppRoutes.registro);
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: _buttonBrown,
                side: const BorderSide(color: _buttonBrown, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Crear cuenta',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
              ),
            ),
          const SizedBox(height: 8),
          TextButton.icon(
            key: const Key('boton-modo-admin'),
            onPressed: _isLoading
                ? null
                : () => _cambiarRol(
                      _modoAdmin ? UserRole.estudiante : UserRole.admin,
                    ),
            style: TextButton.styleFrom(foregroundColor: _navy),
            icon: Icon(
              _modoAdmin ? Icons.arrow_back : Icons.admin_panel_settings_outlined,
            ),
            label: Text(
              _modoAdmin
                  ? 'Volver al acceso de estudiantes y entrenadores'
                  : 'Iniciar sesión como Administrador',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.label,
    required this.backgroundColor,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(
          vertical: isSelected ? 12 : 6,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? backgroundColor
              : backgroundColor.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: backgroundColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: isSelected ? 22 : 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label),
          ),
        ),
      ),
    );
  }
}