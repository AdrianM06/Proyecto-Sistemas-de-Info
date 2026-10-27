import 'package:flutter/material.dart';

import 'controllers/buscador_controller.dart';
import 'services/buscador_demo_service.dart';
import 'views/buscador/buscador_screen.dart';
import 'views/theme/saman_colors.dart';

/// Demo del buscador de deportes con datos de ejemplo (sin Firebase ni
/// inicio de sesión).
///
/// Para abrirla:
/// ```
/// flutter run -t lib/main_buscador_demo.dart -d chrome
/// ```
void main() {
  runApp(const BuscadorDemoApp());
}

class BuscadorDemoApp extends StatelessWidget {
  const BuscadorDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Samán Deportivo · Buscador',
      debugShowCheckedModeBanner: false,
      theme: SamanColors.tema(),
      home: Builder(
        builder: (context) => BuscadorScreen(
          controller: BuscadorController(datos: BuscadorDemoService()),
          onSeleccionar: (deporte) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Elegiste ${deporte.nombre}')),
            );
          },
        ),
      ),
    );
  }
}
