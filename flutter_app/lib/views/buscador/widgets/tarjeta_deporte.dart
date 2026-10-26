import 'package:flutter/material.dart';

import '../../../models/deporte.dart';
import '../../theme/saman_colors.dart';

/// Tarjeta de un deporte en los resultados del buscador.
class TarjetaDeporte extends StatelessWidget {
  const TarjetaDeporte({
    super.key,
    required this.deporte,
    required this.cuposDisponibles,
    this.onTap,
  });

  final Deporte deporte;
  final int cuposDisponibles;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deporte.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: SamanColors.azulNoche,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      deporte.disciplina,
                      style: const TextStyle(color: SamanColors.neutro500),
                    ),
                    const SizedBox(height: 10),
                    _Dato(icono: Icons.schedule, texto: deporte.horariosTexto),
                    const SizedBox(height: 4),
                    _Dato(
                      icono: Icons.place_outlined,
                      texto: deporte.lugar.isEmpty
                          ? 'Lugar por definir'
                          : deporte.lugar,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              EtiquetaCupos(cuposDisponibles: cuposDisponibles),
            ],
          ),
        ),
      ),
    );
  }
}

/// Etiqueta con los cupos libres: verde si hay, naranja si quedan 3 o
/// menos y roja si no queda ninguno.
class EtiquetaCupos extends StatelessWidget {
  const EtiquetaCupos({super.key, required this.cuposDisponibles});

  final int cuposDisponibles;

  @override
  Widget build(BuildContext context) {
    final (texto, fondo, color) = switch (cuposDisponibles) {
      <= 0 => ('Sin cupos', SamanColors.errorFondo, SamanColors.error),
      <= 3 => (
          'Quedan $cuposDisponibles',
          SamanColors.naranja50,
          SamanColors.naranja700,
        ),
      _ => ('$cuposDisponibles cupos', SamanColors.verde50, SamanColors.verde700),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 16, color: SamanColors.azul),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(color: SamanColors.neutro900, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
