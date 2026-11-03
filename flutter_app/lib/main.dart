import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'navigation/app_routes.dart';

// NO TOCAR ESTOS COLORES, SON DE LA PALETA UNIVERSITARIA, NO MODIFICAR NI DEJAR DE USAR!
// (Los colores del login viven ahora en lib/views/login_screen.dart.)
const _navy = Color(0xFF003B82);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // La app abre igual; el inicio de sesión mostrará el error.
    debugPrint('No se pudo inicializar Firebase: $e');
  }
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
        // Transición suave (fundido) entre pantallas en todas las
        // plataformas: evita el "salto" del diseño al pasar del Inicio al
        // Perfil.
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            for (final plataforma in TargetPlatform.values)
              plataforma: const _TransicionFundido(),
          },
        ),
      ),
      // La raíz (/) es la Landing Page; desde ahí se entra al login.
      initialRoute: AppRoutes.landing,
      onGenerateRoute: AppRoutes.generarRuta,
    );
  }
}

/// Transición de página con un fundido corto.
class _TransicionFundido extends PageTransitionsBuilder {
  const _TransicionFundido();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    );
  }
}
