import 'package:flutter/material.dart';

import '../../navigation/app_routes.dart';

/// Botón "Volver al inicio": lleva a la Landing Page desde el login, el
/// registro y la recuperación de contraseña, aunque se haya entrado directo
/// por la URL o se haya recargado la página.
class BotonVolverInicio extends StatelessWidget {
  const BotonVolverInicio({super.key, this.color = const Color(0xFF003B82)});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      key: const Key('boton-volver-inicio'),
      onPressed: () => AppRoutes.irALanding(context),
      style: TextButton.styleFrom(foregroundColor: color),
      icon: const Icon(Icons.arrow_back),
      label: const Text(
        'Volver al inicio',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
