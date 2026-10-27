/// Formatea un monto en bolívares con el formato `Bs. 00,00`: puntos para
/// los miles, coma para los decimales y al menos dos cifras enteras.
///
/// Ejemplos: `0` → `Bs. 00,00`, `5.5` → `Bs. 05,50`,
/// `1234.5` → `Bs. 1.234,50`, `-12` → `-Bs. 12,00`.
String formatoBolivares(num monto) {
  final negativo = monto < 0;
  final centimosTotales = (monto.abs() * 100).round();
  final enteros = centimosTotales ~/ 100;
  final centimos = (centimosTotales % 100).toString().padLeft(2, '0');

  final cifras = enteros.toString().padLeft(2, '0');
  final conMiles = StringBuffer();
  for (var i = 0; i < cifras.length; i++) {
    final restantes = cifras.length - i;
    conMiles.write(cifras[i]);
    if (restantes > 1 && restantes % 3 == 1) conMiles.write('.');
  }

  return '${negativo ? '-' : ''}Bs. $conMiles,$centimos';
}
