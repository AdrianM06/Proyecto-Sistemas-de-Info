import 'package:flutter_app/models/bloque_horario.dart';
import 'package:flutter_app/models/deporte.dart';
import 'package:flutter_app/utils/choques_horario.dart';
import 'package:flutter_app/utils/horarios.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bloque con horas en formato de 24 h: `b(1, 16, 18)` = Lun 4–6 pm.
BloqueHorario b(int dia, num inicio, num fin) => BloqueHorario(
  dia: dia,
  inicio: (inicio * 60).round(),
  fin: (fin * 60).round(),
);

void main() {
  group('interpretarHorario', () {
    test('lee el formato del panel admin con AM/PM en las dos horas', () {
      final r = interpretarHorario('Lun 8:00 AM - 10:00 AM');
      expect(r.esValido, isTrue);
      expect(r.bloques, [b(1, 8, 10)]);
      expect(r.bloques.single.duracion, const Duration(hours: 2));
    });

    test('varios días comparten el mismo rango', () {
      expect(interpretarHorario('Lun y Mié 2:00 PM - 4:00 PM').bloques, [
        b(1, 14, 16),
        b(3, 14, 16),
      ]);
      expect(
        interpretarHorario('Lun a Vie 7:00 am - 8:00 am').bloques
            .map((x) => x.dia),
        [1, 2, 3, 4, 5],
      );
    });

    test('am/pm escrito solo al final vale para las dos horas', () {
      expect(interpretarHorario('Lun 4:00–6:00 pm').bloques, [b(1, 16, 18)]);
      expect(interpretarHorario('Sáb 9:00–11:00 am').bloques, [b(6, 9, 11)]);
      expect(interpretarHorario('Lun 7:00–8:30 am').bloques, [b(1, 7, 8.5)]);
    });

    test('cruza el mediodía sin confundirse', () {
      expect(interpretarHorario('Mar 11:00–1:00 pm').bloques, [b(2, 11, 13)]);
      expect(interpretarHorario('Lun y Mié 12:15 PM - 1:45 PM').bloques, [
        b(1, 12.25, 13.75),
        b(3, 12.25, 13.75),
      ]);
      expect(interpretarHorario('Jue 11 am - 1').bloques, [b(4, 11, 13)]);
    });

    test('acepta 24 horas, "a"/"hasta" y p.m. con puntos', () {
      expect(interpretarHorario('Vie 14:00 - 16:30').bloques, [b(5, 14, 16.5)]);
      expect(interpretarHorario('Jue 5 a 7 p.m.').bloques, [b(4, 17, 19)]);
      expect(interpretarHorario('Dom 8 hasta 10 a. m.').bloques, [b(7, 8, 10)]);
    });

    test('cada rango usa los días escritos antes de él', () {
      expect(interpretarHorario('Lun 8-10 am, Mié 2-4 pm').bloques, [
        b(1, 8, 10),
        b(3, 14, 16),
      ]);
    });

    test('explica por qué un horario no sirve', () {
      expect(interpretarHorario('Martes 5 pm').error, contains('hora de fin'));
      expect(interpretarHorario('4:00 - 6:00 pm').error, contains('día'));
      expect(
        interpretarHorario('Lun 13:00 pm - 2:00 pm').error,
        contains('no es válida'),
      );
      expect(
        interpretarHorario('Lun 6:00 pm - 4:00 pm').error,
        contains('posterior'),
      );
    });
  });

  test('validarHorarios rechaza horarios que se solapan entre sí', () {
    expect(validarHorarios([]), contains('al menos'));
    expect(validarHorarios(['Lun 4-6 pm', 'Mié 4-6 pm']), isNull);
    expect(
      validarHorarios(['Lun 4-6 pm', 'Lun 5-7 pm']),
      contains('se solapan'),
    );
  });

  group('BloqueHorario', () {
    test('se solapa solo si comparten día y horas', () {
      expect(b(1, 16, 18).seSolapaCon(b(1, 17, 19)), isTrue);
      expect(b(1, 16, 18).seSolapaCon(b(1, 15, 20)), isTrue);
      expect(b(1, 16, 18).seSolapaCon(b(2, 16, 18)), isFalse);
      // Uno termina cuando empieza el otro: no chocan.
      expect(b(1, 16, 18).seSolapaCon(b(1, 18, 20)), isFalse);
    });

    test('se guarda como {dia, inicio, fin} en minutos', () {
      expect(b(3, 16, 18).toJson(), {'dia': 3, 'inicio': 960, 'fin': 1080});
      expect(
        BloqueHorario.fromJson({'dia': 3, 'inicio': 960, 'fin': 1080}),
        b(3, 16, 18),
      );
      expect(BloqueHorario.fromJson({'dia': 9, 'inicio': 1, 'fin': 2}), isNull);
      expect(b(1, 16, 18).texto, 'Lun 4:00 pm – 6:00 pm');
      expect(BloqueHorario.horaTexto(0), '12:00 am');
      expect(BloqueHorario.horaTexto(12 * 60 + 30), '12:30 pm');
    });
  });

  group('Deporte', () {
    test('lee el entrenador viejo y lo pasa a la lista', () {
      final viejo = Deporte.fromJson({
        'nombre': 'Fútbol',
        'entrenadorId': 'ana',
        'horarios': ['Lun 4:00–6:00 pm'],
      }, id: 'fut');
      expect(viejo.entrenadoresIds, ['ana']);
      expect(viejo.bloques, [b(1, 16, 18)]);

      final nuevo = Deporte.fromJson({
        'nombre': 'Fútbol',
        'entrenadoresIds': ['ana', 'luis'],
        'entrenadoresNombres': {'ana': 'Ana Rojas', 'luis': 'Luis Pérez'},
        'bloquesHorario': [
          {'dia': 2, 'inicio': 600, 'fin': 720},
        ],
      }, id: 'fut');
      expect(nuevo.entrenadoresIds, ['ana', 'luis']);
      expect(nuevo.entrenadoresTexto, 'Ana Rojas, Luis Pérez');
      expect(nuevo.bloques, [b(2, 10, 12)]);
      expect(nuevo.diasDeEntrenamiento, {2});
    });

    test('toJson guarda los campos consultables', () {
      const deporte = Deporte(
        id: 'x',
        nombre: 'Natación',
        disciplina: 'Natación',
        cupos: 10,
        entrenadoresIds: ['ana'],
        horarios: ['Lun y Mié 2:00 PM - 4:00 PM', 'Sáb 9-11 am'],
      );
      final json = deporte.toJson();
      expect(json['entrenadoresIds'], ['ana']);
      expect(json.containsKey('entrenadorId'), isFalse);
      expect(json['diasSemana'], [1, 3, 6]);
      expect(json['horaMinima'], 9 * 60);
      expect(json['horaMaxima'], 16 * 60);
      expect((json['bloquesHorario'] as List).first, {
        'dia': 1,
        'inicio': 840,
        'fin': 960,
      });
    });
  });

  test('buscarChoques compara cada bloque con las disciplinas asignadas', () {
    const futbol = Deporte(
      id: 'fut',
      nombre: 'Fútbol',
      disciplina: '',
      cupos: 1,
      horarios: ['Lun y Mié 4-6 pm'],
    );
    final choques = buscarChoques(
      bloques: [b(3, 17, 19), b(5, 17, 19)],
      asignadas: [futbol],
    );
    expect(choques, hasLength(1));
    expect(choques.single.descripcion, contains('Mié 5:00 pm – 7:00 pm'));
    expect(choques.single.descripcion, contains('Fútbol'));
    // La propia disciplina no choca consigo misma al editarla.
    expect(
      buscarChoques(
        bloques: futbol.bloques,
        asignadas: [futbol],
        disciplinaId: 'fut',
      ),
      isEmpty,
    );
  });
}
