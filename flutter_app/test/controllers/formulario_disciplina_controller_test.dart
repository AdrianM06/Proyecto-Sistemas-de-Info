import 'dart:async';

import 'package:flutter_app/controllers/formulario_disciplina_controller.dart';
import 'package:flutter_app/models/deporte.dart';
import 'package:flutter_app/models/usuario.dart';
import 'package:flutter_app/services/gestion_entrenadores_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _Datos implements GestionEntrenadoresDataSource {
  final entrenadoresFlujo = StreamController<List<Usuario>>.broadcast();
  final deportesFlujo = StreamController<List<Deporte>>.broadcast();
  Deporte? guardada;

  @override
  Stream<List<Usuario>> entrenadores() => entrenadoresFlujo.stream;

  @override
  Stream<List<Deporte>> deportes() => deportesFlujo.stream;

  @override
  Future<void> asignar({
    required String entrenadorId,
    required String entrenadorNombre,
    required String deporteId,
  }) async {}

  @override
  Future<void> revocar({
    required String entrenadorId,
    required String deporteId,
  }) async {}

  @override
  Future<void> guardarDisciplina(Deporte deporte) async => guardada = deporte;
}

const _ana = Usuario(
  uid: 'ana',
  email: 'ana@unimet.edu.ve',
  nombre: 'Ana',
  apellido: 'Rojas',
  rol: RolUsuario.entrenador,
);

const _luis = Usuario(
  uid: 'luis',
  email: 'luis@unimet.edu.ve',
  nombre: 'Luis',
  apellido: 'Pérez',
  rol: RolUsuario.entrenador,
);

const _futbol = Deporte(
  id: 'fut',
  nombre: 'Fútbol',
  disciplina: 'Fútbol',
  cupos: 30,
  entrenadoresIds: ['ana'],
  horarios: ['Lun y Mié 4:00 pm - 6:00 pm'],
);

void main() {
  late _Datos datos;
  late FormularioDisciplinaController c;

  Future<void> iniciar({Deporte? original}) async {
    datos = _Datos();
    c = FormularioDisciplinaController(datos: datos, original: original)
      ..iniciar();
    datos.entrenadoresFlujo.add([_luis, _ana]);
    datos.deportesFlujo.add([_futbol]);
    await Future<void>.delayed(Duration.zero);
  }

  tearDown(() => c.dispose());

  test('agrega horarios válidos y explica los inválidos', () async {
    await iniciar();
    expect(c.agregarHorario('Martes 5 pm'), contains('hora de fin'));
    expect(c.agregarHorario('Mar y Jue 5:00 pm - 7:00 pm'), isNull);
    expect(c.agregarHorario('Jue 6:00 pm - 8:00 pm'), contains('se solapan'));
    expect(c.horarios, ['Mar y Jue 5:00 pm - 7:00 pm']);
    expect(c.bloques.map((b) => b.dia), [2, 4]);
  });

  test('permite varios entrenadores si no chocan', () async {
    await iniciar();
    c.agregarHorario('Mar 5:00 pm - 7:00 pm');
    expect(c.alternarEntrenador(_ana), isNull);
    expect(c.alternarEntrenador(_luis), isNull);
    expect(c.seleccionados, ['ana', 'luis']);

    expect(
      await c.guardar(
        nombre: 'Voleibol',
        disciplina: 'Voleibol',
        lugar: 'Gimnasio',
        cupos: 16,
        etiquetas: const [],
      ),
      isNull,
    );
    final guardada = datos.guardada!;
    expect(guardada.entrenadoresIds, ['ana', 'luis']);
    expect(guardada.entrenadoresNombres, {
      'ana': 'Ana Rojas',
      'luis': 'Luis Pérez',
    });
    expect(guardada.toJson()['bloquesHorario'], [
      {'dia': 2, 'inicio': 1020, 'fin': 1140},
    ]);
  });

  test('no deja elegir a un entrenador cuyo horario choca', () async {
    await iniciar();
    c.agregarHorario('Lun 5:00 pm - 7:00 pm');

    final error = c.alternarEntrenador(_ana, nombreDisciplina: 'Voleibol');
    expect(error, contains('Fútbol'));
    expect(error, contains('Voleibol'));
    expect(c.ultimoErrorFueChoque, isTrue);
    expect(c.estaSeleccionado(_ana), isFalse);
  });

  test('al guardar vuelve a validar si los horarios cambiaron', () async {
    await iniciar();
    c.agregarHorario('Vie 5:00 pm - 7:00 pm');
    expect(c.alternarEntrenador(_ana), isNull);
    c.quitarHorario('Vie 5:00 pm - 7:00 pm');
    c.agregarHorario('Mié 5:00 pm - 7:00 pm');

    final error = await c.guardar(
      nombre: 'Voleibol',
      disciplina: '',
      lugar: '',
      cupos: 10,
      etiquetas: const [],
    );
    expect(error, contains('choca'));
    expect(c.ultimoErrorFueChoque, isTrue);
    expect(datos.guardada, isNull);
  });

  test('al editar, la disciplina no choca consigo misma', () async {
    await iniciar(original: _futbol);
    expect(c.editando, isTrue);
    expect(c.seleccionados, ['ana']);
    expect(c.choquesDe(_ana), isEmpty);

    expect(
      await c.guardar(
        nombre: 'Fútbol',
        disciplina: 'Fútbol',
        lugar: '',
        cupos: 25,
        etiquetas: const [],
      ),
      isNull,
    );
    expect(datos.guardada!.id, 'fut');
    expect(datos.guardada!.cupos, 25);
  });

  test('sin horarios no se guarda', () async {
    await iniciar();
    expect(
      await c.guardar(
        nombre: 'X',
        disciplina: '',
        lugar: '',
        cupos: 5,
        etiquetas: const [],
      ),
      contains('al menos un horario'),
    );
  });
}
