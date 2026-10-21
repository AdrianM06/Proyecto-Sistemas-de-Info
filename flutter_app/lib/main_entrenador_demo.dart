import 'package:flutter/material.dart';

import 'controllers/entrenador_controller.dart';
import 'services/entrenador_demo_service.dart';
import 'views/entrenador/entrenador_home_screen.dart';
import 'views/theme/saman_colors.dart';

/// Demo de la vista del entrenador con datos de ejemplo (sin Firebase ni
/// inicio de sesión).
///
/// Para abrirla:
/// ```
/// flutter run -t lib/main_entrenador_demo.dart -d chrome
/// ```
void main() {
  runApp(const EntrenadorDemoApp());
}

class EntrenadorDemoApp extends StatelessWidget {
  const EntrenadorDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Samán Deportivo · Entrenador',
      debugShowCheckedModeBanner: false,
      theme: SamanColors.tema(),
      home: EntrenadorHomeScreen(
        controller: EntrenadorController(
          datos: EntrenadorDemoService(),
          entrenadorId: EntrenadorDemoService.entrenadorDemoId,
        ),
        nombreEntrenador: EntrenadorDemoService.entrenadorDemoNombre,
      ),
    );
  }
}
