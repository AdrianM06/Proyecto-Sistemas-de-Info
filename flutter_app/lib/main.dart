import 'package:flutter/material.dart';

//NO TOCAR ESTOS COLORES, SON DE LA PALETA UNIVERSITARIA, NO MODIFICAR NI DEJAR DE USAR!
const _orange = Color(0xFFF58220);
const _navy = Color(0xFF003B82);
const _panelGray = Color(0xFFD9D9D9);
const _buttonBrown = Color(0xFF514943);

enum UserRole { estudiante, entrenador }

void main() {
  runApp(const UnimetSportsApp());
}

class UnimetSportsApp extends StatelessWidget {
  const UnimetSportsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UNIMET Sports',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _navy),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

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
                Colors.black.withOpacity(0.4),
                Colors.transparent,
                Colors.black.withOpacity(0.2),
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
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                    children: [
                      const TextSpan(
                        text: 'si no tiene una cuenta ya hecha, registrese ',
                      ),
                      TextSpan(
                        text: 'aquí',
                        style: const TextStyle(
                          color: _navy,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
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
  UserRole _selectedRole = UserRole.estudiante;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _RoleOption(
                label: 'Estudiante',
                backgroundColor: _orange,
                isSelected: _selectedRole == UserRole.estudiante,
                onTap: () {
                  setState(() {
                    _selectedRole = UserRole.estudiante;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RoleOption(
                label: 'Entrenador',
                backgroundColor: _navy,
                isSelected: _selectedRole == UserRole.entrenador,
                onTap: () {
                  setState(() {
                    _selectedRole = UserRole.entrenador;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Correo/Carnet Universitario',
          style: TextStyle(fontSize: 18, color: Colors.black),
        ),
        const SizedBox(height: 4),
        const TextField(
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Contraseña',
          style: TextStyle(fontSize: 18, color: Colors.black),
        ),
        const SizedBox(height: 4),
        const TextField(
          obscureText: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
            children: [
              const TextSpan(text: 'dale click '),
              TextSpan(
                text: 'aquí',
                style: const TextStyle(
                  color: _navy,
                  decoration: TextDecoration.underline,
                ),
              ),
              const TextSpan(text: ' si se le olvidó su contraseña'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            // Access active selection via `_selectedRole`
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _buttonBrown,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Iniciar Sesión',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
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
              : backgroundColor.withOpacity(0.35),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: backgroundColor.withOpacity(0.3),
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