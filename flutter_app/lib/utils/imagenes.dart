import 'package:flutter/widgets.dart';

/// Píxeles físicos que ocupa un tamaño lógico en la pantalla actual.
///
/// Se pasa como `cacheWidth` o `cacheHeight` de `Image.asset` para que
/// Flutter decodifique la imagen al tamaño en que se ve y no a su resolución
/// original (el logo mide 2000 × 2000 px y se muestra a 40-184 px).
int pixelesFisicos(BuildContext context, double logicos) =>
    (logicos * MediaQuery.devicePixelRatioOf(context)).ceil();
