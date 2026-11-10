import 'package:flutter/material.dart';

const _ambar = Color(0xFFF2A900);

/// Selector de 1 a 5 estrellas para el formulario de reseñas.
///
/// [valor] es la cantidad elegida (0 = todavía sin elegir). Con
/// [onChanged] en `null` las estrellas quedan deshabilitadas.
class SelectorEstrellas extends StatelessWidget {
  const SelectorEstrellas({
    super.key,
    required this.valor,
    required this.onChanged,
    this.tamano = 32,
  });

  final int valor;
  final ValueChanged<int>? onChanged;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            key: Key('estrella-$i'),
            tooltip: i == 1 ? '1 estrella' : '$i estrellas',
            onPressed: onChanged == null ? null : () => onChanged!(i),
            icon: Icon(
              i <= valor ? Icons.star_rounded : Icons.star_outline_rounded,
              color: i <= valor ? _ambar : Colors.grey,
              size: tamano,
            ),
          ),
      ],
    );
  }
}

/// Estrellas de solo lectura. Muestra medias estrellas, para promedios.
class EstrellasFijas extends StatelessWidget {
  const EstrellasFijas({super.key, required this.valor, this.tamano = 18});

  final double valor;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${valor.toStringAsFixed(1)} de 5 estrellas',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              valor >= i
                  ? Icons.star_rounded
                  : valor >= i - 0.5
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
              color: _ambar,
              size: tamano,
            ),
        ],
      ),
    );
  }
}
