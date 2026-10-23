import 'package:flutter/material.dart';

const _orange = Color(0xFFF58220);
const _navy = Color(0xFF003B82);
const _panelGray = Color(0xFFD9D9D9);
const _buttonBrown = Color(0xFF514943);

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
          if (constraints.maxWidth >= 760) {
            return Row(
              children: [
                const Expanded(child: _SportsHero()),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(color: _panelGray),
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

          return Container(
            decoration: const BoxDecoration(color: _panelGray),
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
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF364A2D), Color(0xFF6F7950), Color(0xFF182B35)],
              stops: [0, 0.43, 1],
            ),
          ),
        ),
        const _CourtIllustration(),
        Positioned(
          top: 28,
          left: 28,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const _UnimetSportsLogo(),
          ),
        ),
      ],
    );
  }
}

class _CourtIllustration extends StatelessWidget {
  const _CourtIllustration();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Fallback to default height if constraints are unbounded or 0
        final height = constraints.maxHeight > 0 && constraints.maxHeight.isFinite 
            ? constraints.maxHeight 
            : 400.0;
        final width = constraints.maxWidth > 0 && constraints.maxWidth.isFinite 
            ? constraints.maxWidth 
            : 400.0;

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: height * 0.38,
              left: -width * 0.08,
              right: -width * 0.08,
              bottom: -height * 0.08,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1486AE), Color(0xFF00648D)],
                  ),
                ),
              ),
            ),
            Positioned(
              top: height * 0.43,
              left: width * 0.06,
              right: width * 0.06,
              bottom: height * 0.05,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white70, width: 2),
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Container(width: 2, color: Colors.white70),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Container(height: 2, color: Colors.white70),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: height * 0.28,
                      child: Container(
                        height: 3,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDAE4E4),
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: width * 0.16,
              bottom: height * 0.12,
              child: const _PlayerSilhouette(color: Color(0xFF26333B)),
            ),
            Positioned(
              right: width * 0.18,
              top: height * 0.48,
              child: const _PlayerSilhouette(color: Color(0xFF554D43)),
            ),
          ],
        );
      },
    );
  }
}

class _PlayerSilhouette extends StatelessWidget {
  const _PlayerSilhouette({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Container(
          width: 34,
          height: 80,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ],
    );
  }
}

class _UnimetSportsLogo extends StatelessWidget {
  const _UnimetSportsLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(width: 9, height: 48, color: _orange),
            const SizedBox(width: 4),
            Container(width: 9, height: 58, color: _orange),
            const SizedBox(width: 4),
            Container(width: 9, height: 68, color: _orange),
          ],
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'UNIMET',
              style: TextStyle(
                color: _orange,
                fontSize: 27,
                fontWeight: FontWeight.w900,
                height: 0.95,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'SPORTS',
              style: TextStyle(
                color: _navy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
            ),
          ],
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
                        style: TextStyle(
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

class _LoginForm extends StatelessWidget {
  const _LoginForm();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Expanded(
              child: _RoleOption(
                label: 'Estudiante',
                backgroundColor: _orange,
                fontSize: 17,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _RoleOption(
                label: 'Entrenador',
                backgroundColor: _navy,
                fontSize: 25,
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
        const _InputPlaceholder(),
        const SizedBox(height: 20),
        const Text(
          'Contraseña',
          style: TextStyle(fontSize: 18, color: Colors.black),
        ),
        const SizedBox(height: 4),
        const _InputPlaceholder(),
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
                style: TextStyle(
                  color: _navy,
                  decoration: TextDecoration.underline,
                ),
              ),
              const TextSpan(text: ' si se le olvidó su contraseña'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _buttonBrown,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'Iniciar Sesión',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
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
    required this.fontSize,
  });

  final String label;
  final Color backgroundColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: TextStyle(color: Colors.white, fontSize: fontSize),
        ),
      ),
    );
  }
}

class _InputPlaceholder extends StatelessWidget {
  const _InputPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFB8B1A8), width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
