import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/controllers/gestion_entrenadores_controller.dart';
import 'package:flutter_app/models/deporte.dart';
import 'package:flutter_app/models/usuario.dart';
import 'package:flutter_app/services/gestion_entrenadores_service.dart';
import 'package:flutter_app/utils/choques_horario.dart';
import 'package:flutter_app/views/admin/gestion_entrenadores_view.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simula Firestore: guarda las disciplinas en memoria y, al asignar o
/// revocar, emite la lista nueva igual que lo haría `snapshots()`. Como el
/// servicio real, vuelve a validar los choques de horario al asignar.
class _Datos implements GestionEntrenadoresDataSource {
  _Datos(this._deportes);

  final _entrenadoresFlujo = StreamController<List<Usuario>>.broadcast();
  final _deportesFlujo = StreamController<List<Deporte>>.broadcast();
  List<Deporte> _deportes;
  List<Usuario> entrenadoresActuales = const [];
  int escrituras = 0;
  Completer<void>? bloqueo;
  Deporte? guardada;

  @override
  Stream<List<Usuario>> entrenadores() => _entrenadoresFlujo.stream;

  @override
  Stream<List<Deporte>> deportes() => _deportesFlujo.stream;

  void emitir() {
    _entrenadoresFlujo.add(entrenadoresActuales);
    _deportesFlujo.add(_deportes);
  }

  Deporte _deporte(String id) => _deportes.firstWhere((d) => d.id == id);

  /// Cambia los entrenadores de una disciplina sin pasar por el controlador,
  /// como si lo hiciera otro administrador.
  void poner(String deporteId, List<String> ids) {
    _deportes = [
      for (final d in _deportes) d.id == deporteId ? d.conEntrenadores(ids) : d,
    ];
    _deportesFlujo.add(_deportes);
  }

  @override
  Future<void> asignar({
    required String entrenadorId,
    required String entrenadorNombre,
    required String deporteId,
  }) async {
    await bloqueo?.future;
    final deporte = _deporte(deporteId);
    final choques = buscarChoques(
      bloques: deporte.bloques,
      asignadas: _deportes.where((d) => d.tieneEntrenador(entrenadorId)),
      disciplinaId: deporteId,
    );
    if (choques.isNotEmpty) {
      throw ChoqueHorarioException(
        mensajeDeChoques(
          entrenador: entrenadorNombre,
          disciplina: deporte.nombre,
          choques: choques,
        )!,
        choques,
      );
    }
    escrituras++;
    poner(deporteId, [...deporte.entrenadoresIds, entrenadorId]);
  }

  @override
  Future<void> revocar({
    required String entrenadorId,
    required String deporteId,
  }) async {
    await bloqueo?.future;
    final actual = _deporte(deporteId);
    if (!actual.tieneEntrenador(entrenadorId)) {
      throw const GestionEntrenadoresException(
        'Esa disciplina ya no está asignada a este entrenador.',
      );
    }
    escrituras++;
    poner(deporteId, [
      for (final id in actual.entrenadoresIds)
        if (id != entrenadorId) id,
    ]);
  }

  @override
  Future<void> guardarDisciplina(Deporte deporte) async {
    escrituras++;
    guardada = deporte;
  }
}

const _ana = Usuario(
  uid: 'ana',
  email: 'ana@unimet.edu.ve',
  nombre: 'Ana',
  apellido: 'Rojas',
  rol: RolUsuario.entrenador,
  carnet: '20201110001',
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
  nombre: 'Futbol Campo Masculino',
  disciplina: 'Futbol Campo',
  cupos: 30,
  entrenadoresIds: ['ana'],
  horarios: ['Lun y Mié 12:15 PM - 1:45 PM'],
);

const _ajedrez = Deporte(
  id: 'aje',
  nombre: 'Ajedrez',
  disciplina: 'Ajedrez',
  cupos: 20,
  horarios: ['Martes y Jueves 3:00 PM - 5:00 PM'],
);

/// Choca con fútbol el lunes (1:00 pm cae dentro de 12:15–1:45 pm).
const _voleibol = Deporte(
  id: 'vol',
  nombre: 'Voleibol',
  disciplina: 'Voleibol',
  cupos: 16,
  horarios: ['Lun 1:00 PM - 3:00 PM'],
);

const _vacio = Deporte(
  id: 'vacio',
  nombre: 'Sin nombre',
  disciplina: '',
  cupos: 0,
);

void main() {
  late _Datos datos;
  late GestionEntrenadoresController controlador;

  setUp(() {
    datos = _Datos([_futbol, _ajedrez, _voleibol, _vacio])
      ..entrenadoresActuales = [_luis, _ana];
    controlador = GestionEntrenadoresController(datos: datos);
  });

  Future<void> esperar() => Future<void>.delayed(Duration.zero);

  Future<void> iniciar() async {
    controlador.iniciar();
    datos.emitir();
    await esperar();
  }

  Map<String, EntrenadorConDisciplinas> porId() => {
    for (final f in controlador.entrenadores) f.entrenador.uid: f,
  };

  group('controlador', () {
    test(
      'une cada entrenador con sus disciplinas y ordena por nombre',
      () async {
        controlador.iniciar();
        expect(controlador.cargando, isTrue);
        datos.emitir();
        await esperar();

        expect(controlador.cargando, isFalse);
        final filas = controlador.entrenadores;
        expect(filas.map((f) => f.entrenador.uid), ['ana', 'luis']);
        expect(filas[0].disciplinas.map((d) => d.id), ['fut']);
        expect(filas[1].disciplinas, isEmpty);
        // El documento vacío no se ofrece para asignar.
        expect(controlador.deportes.map((d) => d.id), ['aje', 'fut', 'vol']);
        controlador.dispose();
      },
    );

    test('asignar se refleja en tiempo real', () async {
      await iniciar();

      expect(await controlador.asignar(_luis, _ajedrez), isNull);
      await esperar();

      expect(porId()['luis']!.disciplinas.map((d) => d.id), ['aje']);
      controlador.dispose();
    });

    test('una disciplina puede tener varios entrenadores', () async {
      await iniciar();
      expect(controlador.entrenadoresDe(_futbol), ['Ana Rojas']);

      expect(await controlador.asignar(_luis, _futbol), isNull);
      await esperar();

      expect(porId()['ana']!.disciplinas.map((d) => d.id), ['fut']);
      expect(porId()['luis']!.disciplinas.map((d) => d.id), ['fut']);
      final futbol = controlador.deportes.firstWhere((d) => d.id == 'fut');
      expect(futbol.entrenadoresIds, ['ana', 'luis']);
      expect(controlador.entrenadoresDe(futbol), ['Ana Rojas', 'Luis Pérez']);
      controlador.dispose();
    });

    test('revocar quita solo a ese entrenador', () async {
      datos.poner('fut', ['ana', 'luis']);
      await iniciar();

      expect(await controlador.revocar(_ana, _futbol), isNull);
      await esperar();

      expect(porId()['ana']!.disciplinas, isEmpty);
      expect(
        controlador.deportes.firstWhere((d) => d.id == 'fut').entrenadoresIds,
        ['luis'],
      );
      controlador.dispose();
    });

    test(
      'revocar algo que ya no es suyo devuelve el error del servicio',
      () async {
        await iniciar();

        final error = await controlador.revocar(_luis, _futbol);
        expect(error, contains('ya no está asignada'));
        expect(datos.escrituras, 0);
        controlador.dispose();
      },
    );

    test('bloquea asignar una disciplina que choca con su horario', () async {
      await iniciar();

      expect(controlador.choquesAlAsignar(_ana, _voleibol), hasLength(1));
      expect(controlador.choquesAlAsignar(_luis, _voleibol), isEmpty);

      final error = await controlador.asignar(_ana, _voleibol);
      expect(error, contains('Futbol Campo Masculino'));
      expect(error, contains('Lun 1:00 pm – 3:00 pm'));
      expect(controlador.ultimoErrorFueChoque, isTrue);
      expect(datos.escrituras, 0);
      controlador.dispose();
    });

    test('si otro admin asignó algo al mismo tiempo, el servicio detecta el choque', () async {
      await iniciar();
      // El controlador todavía no vio este cambio: su validación previa
      // pasa, pero la del servicio no.
      datos._deportes = [
        for (final d in datos._deportes)
          d.id == 'vol' ? d.conEntrenadores(['luis']) : d,
      ];

      final error = await controlador.asignar(_luis, _futbol);
      expect(error, contains('Voleibol'));
      expect(controlador.ultimoErrorFueChoque, isTrue);
      expect(datos.escrituras, 0);
      controlador.dispose();
    });

    test('no permite dos cambios a la vez', () async {
      await iniciar();
      datos.bloqueo = Completer<void>();

      final primero = controlador.asignar(_luis, _ajedrez);
      await esperar();
      expect(controlador.ocupado, 'aje');
      expect(await controlador.asignar(_luis, _futbol), isNotNull);

      datos.bloqueo!.complete();
      expect(await primero, isNull);
      expect(controlador.ocupado, isNull);
      controlador.dispose();
    });
  });

  group('pantalla', () {
    Future<void> abrir(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(home: GestionEntrenadoresView(controller: controlador)),
      );
      datos.emitir();
      await tester.pump();
    }

    testWidgets('lista los entrenadores con su carnet y sus disciplinas', (
      tester,
    ) async {
      await abrir(tester);

      expect(find.byKey(const Key('entrenador-ana')), findsOneWidget);
      expect(find.byKey(const Key('entrenador-luis')), findsOneWidget);
      expect(find.text('Carnet: 20201110001'), findsOneWidget);
      expect(find.text('Sin carnet'), findsOneWidget);
      expect(find.byKey(const Key('asignada-ana-fut')), findsOneWidget);
      expect(find.text('Sin disciplinas asignadas'), findsOneWidget);
    });

    testWidgets('asignar una disciplina libre la agrega al entrenador', (
      tester,
    ) async {
      await abrir(tester);

      await tester.tap(find.byKey(const Key('asignar-luis')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dialogo-asignar')), findsOneWidget);
      expect(find.textContaining('Entrenadores: Ana Rojas'), findsOneWidget);
      expect(find.byKey(const Key('opcion-vacio')), findsNothing);

      await tester.tap(find.byKey(const Key('opcion-aje')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('asignada-luis-aje')), findsOneWidget);
      expect(
        find.textContaining('Ajedrez asignada a Luis Pérez'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('asignar una disciplina con entrenador suma un segundo', (
      tester,
    ) async {
      await abrir(tester);

      await tester.tap(find.byKey(const Key('asignar-luis')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('opcion-fut')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('asignada-luis-fut')), findsOneWidget);
      expect(find.byKey(const Key('asignada-ana-fut')), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('un choque de horario se avisa y no se asigna', (tester) async {
      await abrir(tester);

      await tester.tap(find.byKey(const Key('asignar-ana')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('opcion-vol')),
          matching: find.textContaining('Choca con su horario'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('opcion-vol')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dialogo-choque-horario')), findsOneWidget);
      expect(find.textContaining('Futbol Campo Masculino'), findsWidgets);
      expect(datos.escrituras, 0);

      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('asignada-ana-vol')), findsNothing);
    });

    testWidgets('revocar pide confirmación y quita la disciplina', (
      tester,
    ) async {
      await abrir(tester);

      await tester.tap(find.byKey(const Key('revocar-ana-fut')));
      await tester.pumpAndSettle();
      expect(find.text('Revocar disciplina'), findsOneWidget);
      expect(find.textContaining('quedará sin entrenador'), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirmar-revocar')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('asignada-ana-fut')), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(const Key('resumen-ana'))).data,
        'Sin disciplinas asignadas',
      );
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('un cambio hecho por otro administrador aparece solo', (
      tester,
    ) async {
      await abrir(tester);
      expect(find.byKey(const Key('asignada-luis-aje')), findsNothing);

      datos.poner('aje', ['luis']);
      await tester.pump();

      expect(find.byKey(const Key('asignada-luis-aje')), findsOneWidget);
    });
  });
}
