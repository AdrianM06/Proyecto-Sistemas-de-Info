import 'package:flutter_app/utils/horarios.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('diasDeSemanaDe', () {
    test('lee varios días en una línea (formato del panel admin)', () {
      expect(diasDeSemanaDe('Lun y Mié 12:15 PM - 1:45 PM'), {1, 3});
      expect(diasDeSemanaDe('Lun y Mié 2:00 PM - 4:00 PM'), {1, 3});
    });

    test('acepta nombres completos, plurales, acentos y mayúsculas', () {
      expect(diasDeSemanaDe('Martes, Jueves 5 pm'), {2, 4});
      expect(diasDeSemanaDe('SÁBADOS 9:00 am'), {6});
      expect(diasDeSemanaDe('miercoles y viernes'), {3, 5});
      expect(diasDeSemanaDe('Domingo 8:00 am'), {7});
    });

    test('expande rangos como "Lun a Vie" y "Lun - Vie"', () {
      expect(diasDeSemanaDe('Lun a Vie 7:00 am'), {1, 2, 3, 4, 5});
      expect(diasDeSemanaDe('Lun - Mié 6 pm'), {1, 2, 3});
      expect(diasDeSemanaDe('Vie a Lun'), {5, 6, 7, 1});
    });

    test('los rangos de horas no se confunden con rangos de días', () {
      expect(diasDeSemanaDe('Lun 4:00–6:00 pm, Mié 4:00–6:00 pm'), {1, 3});
      expect(diasDeSemanaDe('Mar 5:00 pm - 7:00 pm'), {2});
    });

    test('un horario sin días da un conjunto vacío', () {
      expect(diasDeSemanaDe(''), isEmpty);
      expect(diasDeSemanaDe('Por definir'), isEmpty);
      expect(diasDeSemanaDe('marzo 2026'), isEmpty);
    });
  });

  test('diasDeEntrenamientoDe une los días de todos los horarios', () {
    expect(diasDeEntrenamientoDe(['Lun 4 pm', 'Mié y Vie 5 pm']), {1, 3, 5});
  });

  test('numeroDeDia convierte las abreviaturas del filtro', () {
    expect(abreviaturasDias.map(numeroDeDia), [1, 2, 3, 4, 5, 6, 7]);
    expect(numeroDeDia('xx'), isNull);
  });
}
