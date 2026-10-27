import 'package:flutter_app/utils/formato_moneda.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('usa el formato Bs. 00,00', () {
    expect(formatoBolivares(0), 'Bs. 00,00');
    expect(formatoBolivares(5.5), 'Bs. 05,50');
    expect(formatoBolivares(25), 'Bs. 25,00');
    expect(formatoBolivares(1234.5), 'Bs. 1.234,50');
    expect(formatoBolivares(1234567.891), 'Bs. 1.234.567,89');
    expect(formatoBolivares(-12), '-Bs. 12,00');
  });
}
