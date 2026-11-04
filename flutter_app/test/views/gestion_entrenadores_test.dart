import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/controllers/gestion_entrenadores_controller.dart';
import 'package:flutter_app/models/deporte.dart';
import 'package:flutter_app/models/usuario.dart';
import 'package:flutter_app/services/gestion_entrenadores_service.dart';
import 'package:flutter_app/views/admin/gestion_entrenadores_view.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simula Firestore: guarda las disciplinas en memoria y, al asignar o
/// revocar, emite la lista nueva igual que lo haría `snapshots()`.
class _Datos implements GestionEntrenadoresDataSource {
  _Datos(this._deportes);

  final _entrenadoresFlujo = StreamController<List<Usuario>>.broadcast();
  final _deportesFlujo = StreamController<List<Deporte>>.broadcast();
  List<Deporte> _deportes;
  List<Usuario> entrenadoresActuales = const [];
  int escrituras = 0;
  Completer<void>? bloqueo;

  @override
  Stream<List<Usuario>> entrenadores() => _entrenadoresFlujo.stream;

  @override
  Stream<List<Deporte>> deportes() => _deportesFlujo.stream;

  void emitir() {
    _entrenadoresFlujo.add(entrenadoresActuales);
    _deportesFlujo.add(_deportes);
  }

  void _poner(String deporteId, String entrenadorId) {
    _deportes = [
      for (final d in _deportes) d.id == deporteId ? _con(d, entrenadorId) : d,
    ];
    _deportesFlujo.add(_deportes);
  }

  Deporte _con(Deporte d, String entrenadorId) => Deporte(
    id: d.id,
    nombre: d.nombre,
    disciplina: d.disciplina,
    cupos: d.cupos,
    entrenadorId: entrenadorId,
    horarios: d.horarios,
  );

  @override
  Future<void> asignar({
    required String entrenadorId,
    required String deporteId,
  }) async {
    await bloqueo?.future;
    escrituras++;
    _poner(deporteId, entrenadorId);
  }

  @override
  Future<void> revocar({
    required String entrenadorId,
    required String deporteId,
  }) async {
    await bloqueo?.future;
    final actual = _deportes.firstWhere((d) => d.id == deporteId);
    if (actual.entrenadorId != entrenadorId) {
      throw const GestionEntrenadoresException(
        'Esa disciplina ya no está asignada a este entrenador.',
      );
    }
    escrituras++;
    _poner(deporteId, '');
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
  entrenadorId: 'ana',
  horarios: ['Lun y Mié 12:15 PM - 1:45 PM'],
);

const _ajedrez = Deporte(
  id: 'aje',
  nombre: 'Ajedrez',
  disciplina: 'Ajedrez',
  cupos: 20,
  entrenadorId: '',
  horarios: ['Martes y Jueves 3:00 PM - 5:00 PM'],
);

const _vacio = Deporte(
  id: 'vacio',
  nombre: 'Sin nombre',
  disciplina: '',
  cupos: 0,
  entrenadorId: '',
);

void main() {
  late _Datos datos;
  late GestionEntrenadoresController controlador;

  setUp(() {
    datos = _Datos([_futbol, _ajedrez, _vacio])
      ..entrenadoresActuales = [_luis, _ana];
    controlador = GestionEntrenadoresController(datos: datos);
  });

  Future<void> esperar() => Future<void>.delayed(Duration.zero);

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
        expect(controlador.deportes.map((d) => d.id), ['aje', 'fut']);
        controlador.dispose();
      },
    );

    test('asignar se refleja en tiempo real', () async {
      controlador.iniciar();
      datos.emitir();
      await esperar();

      expect(await controlador.asignar(_luis, _ajedrez), isNull);
      await esperar();

      final luis = controlador.entrenadores.firstWhere(
        (f) => f.entrenador.uid == 'luis',
      );
      expect(luis.disciplinas.map((d) => d.id), ['aje']);
      controlador.dispose();
    });

    test('revocar quita la disciplina del entrenador', () async {
      controlador.iniciar();
      datos.emitir();
      await esperar();

      expect(await controlador.revocar(_ana, _futbol), isNull);
      await esperar();

      final ana = controlador.entrenadores.first;
      expect(ana.disciplinas, isEmpty);
      expect(
        controlador.deportes.firstWhere((d) => d.id == 'fut').entrenadorId,
        isEmpty,
      );
      controlador.dispose();
    });

    test('reasignar pasa la disciplina al nuevo entrenador', () async {
      controlador.iniciar();
      datos.emitir();
      await esperar();
      expect(controlador.entrenadorDe(_futbol), 'Ana Rojas');

      await controlador.asignar(_luis, _futbol);
      await esperar();

      final porId = {
        for (final f in controlador.entrenadores) f.entrenador.uid: f,
      };
      expect(porId['ana']!.disciplinas, isEmpty);
      expect(porId['luis']!.disciplinas.map((d) => d.id), ['fut']);
      controlador.dispose();
    });

    test(
      'revocar algo que ya no es suyo devuelve el error del servicio',
      () async {
        controlador.iniciar();
        datos.emitir();
        await esperar();

        final error = await controlador.revocar(_luis, _futbol);
        expect(error, contains('ya no está asignada'));
        expect(datos.escrituras, 0);
        controlador.dispose();
      },
    );

    test('no permite dos cambios a la vez', () async {
      controlador.iniciar();
      datos.emitir();
      await esperar();
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
      // La que ya tiene Ana muestra su nombre; la de Ana no se puede repetir.
      expect(
        find.textContaining('Entrenador actual: Ana Rojas'),
        findsOneWidget,
      );
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

    testWidgets('reasignar pide confirmación y mueve la disciplina', (
      tester,
    ) async {
      await abrir(tester);

      await tester.tap(find.byKey(const Key('asignar-luis')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('opcion-fut')));
      await tester.pumpAndSettle();

      expect(find.text('Reasignar disciplina'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirmar-reasignar')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('asignada-luis-fut')), findsOneWidget);
      expect(find.byKey(const Key('asignada-ana-fut')), findsNothing);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('cancelar la reasignación no cambia nada', (tester) async {
      await abrir(tester);

      await tester.tap(find.byKey(const Key('asignar-luis')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('opcion-fut')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(datos.escrituras, 0);
      expect(find.byKey(const Key('asignada-ana-fut')), findsOneWidget);
    });

    testWidgets('revocar pide confirmación y quita la disciplina', (
      tester,
    ) async {
      await abrir(tester);

      await tester.tap(find.byKey(const Key('revocar-ana-fut')));
      await tester.pumpAndSettle();
      expect(find.text('Revocar disciplina'), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirmar-revocar')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('asignada-ana-fut')), findsNothing);
      expect(find.byKey(const Key('resumen-ana')), findsOneWidget);
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

      datos._poner('aje', 'luis');
      await tester.pump();

      expect(find.byKey(const Key('asignada-luis-aje')), findsOneWidget);
    });
  });
}
