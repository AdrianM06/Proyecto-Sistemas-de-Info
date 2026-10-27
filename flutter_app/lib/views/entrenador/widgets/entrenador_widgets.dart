import 'package:flutter/material.dart';

import '../../../models/usuario.dart';
import '../../theme/saman_colors.dart';
import '../formato.dart';

/// Círculo con las iniciales del estudiante.
class AvatarIniciales extends StatelessWidget {
  const AvatarIniciales({super.key, required this.usuario, this.radio = 20});

  final Usuario usuario;
  final double radio;

  static const _fondos = [
    SamanColors.azul100,
    Color(0xFFFDE4C6),
    Color(0xFFC9EBD6),
    Color(0xFFE9E3F8),
    Color(0xFFFCE3EC),
  ];
  static const _textos = [
    SamanColors.azul,
    SamanColors.naranja700,
    SamanColors.verde700,
    Color(0xFF5B3FA8),
    Color(0xFFA3325C),
  ];

  @override
  Widget build(BuildContext context) {
    final indice = usuario.uid.hashCode.abs() % _fondos.length;
    return CircleAvatar(
      radius: radio,
      backgroundColor: _fondos[indice],
      child: Text(
        usuario.iniciales,
        style: TextStyle(
          color: _textos[indice],
          fontWeight: FontWeight.w600,
          fontSize: radio * 0.7,
        ),
      ),
    );
  }
}

/// Etiqueta de porcentaje con color según el nivel de asistencia:
/// verde (85 % o más), naranja (70 % a 84 %) y rojo (menos de 70 %).
class EtiquetaPorcentaje extends StatelessWidget {
  const EtiquetaPorcentaje({super.key, required this.valor});

  final double? valor;

  @override
  Widget build(BuildContext context) {
    final (fondo, texto) = switch (valor) {
      null => (SamanColors.azul50, SamanColors.neutro500),
      double v when v >= 0.85 => (SamanColors.verde50, SamanColors.verde700),
      double v when v >= 0.70 => (SamanColors.naranja50, SamanColors.naranja700),
      _ => (SamanColors.errorFondo, SamanColors.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        porcentaje(valor),
        style: TextStyle(color: texto, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

/// Mensaje centrado para listas vacías o errores.
class MensajeVacio extends StatelessWidget {
  const MensajeVacio({
    super.key,
    required this.icono,
    required this.titulo,
    this.detalle,
    this.accion,
  });

  final IconData icono;
  final String titulo;
  final String? detalle;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 48, color: SamanColors.azul200),
            const SizedBox(height: 12),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (detalle != null) ...[
              const SizedBox(height: 6),
              Text(
                detalle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: SamanColors.neutro500),
              ),
            ],
            if (accion != null) ...[const SizedBox(height: 16), accion!],
          ],
        ),
      ),
    );
  }
}
