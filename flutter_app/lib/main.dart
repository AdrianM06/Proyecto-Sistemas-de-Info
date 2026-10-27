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
      ),
      // La raíz (/) es la Landing Page; desde ahí se entra al login.
      initialRoute: AppRoutes.landing,
      onGenerateRoute: AppRoutes.generarRuta,
    );
  }
}
