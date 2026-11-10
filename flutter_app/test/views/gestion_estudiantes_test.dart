import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/controllers/gestion_estudiantes_controller.dart';
import 'package:flutter_app/models/usuario.dart';
import 'package:flutter_app/services/gestion_estudiantes_service.dart';
import 'package:flutter_app/views/admin/gestion_estudiantes_view.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simula Firestore: al cambiar el estado emite la lista nueva, como
/// `snapshots()`.
class _Datos implements GestionEstudiantesDataSource {
  _Datos(this._lista);

  final _flujo = StreamController<List<Usuario>>.broadcast();
  List<Usuario> _lista;
  String? fallo;
  final List<(String, bool)> cambios = [];

  /// Disciplinas con inscripción activa de cada estudiante.
  final Map<String, Set<String>> inscripciones = {
    'andrea': {'fut', 'aje'},
  };

  void emitir() => _flujo.add(_lista);

  @override
  Stream<List<Usuario>> estudiantes() => _flujo.stream;

  @override
  Future<int> cambiarEstado({required String uid, required bool activo}) async {
    if (fallo != null) throw GestionEstudiantesException(fallo!);
    cambios.add((uid, activo));
    _lista = [for (final u in _lista) u.uid == uid ? _conEstado(u, activo) : u];
    var retiradas = 0;
    if (!activo) {
      retiradas = inscripciones[uid]?.length ?? 0;
      inscripciones.remove(uid);
    }
    emitir();
    return retiradas;
  }
}

Usuario _conEstado(Usuario u, bool activo) => Usuario(
  uid: u.uid,
  email: u.email,
  nombre: u.nombre,
  apellido: u.apellido,
  rol: u.rol,
  carnet: u.carnet,
  cedula: u.cedula,
  estadoActivo: activo,
);

const _andrea = Usuario(
  uid: 'andrea',
  email: 'andrea.perez@correo.unimet.edu.ve',
  nombre: 'Andrea',
  apellido: 'Pérez',
  rol: RolUsuario.estudiante,
  carnet: '20221110342',
  cedula: 'V-28111222',
);

const _luis = Usuario(
  uid: 'luis',
  email: 'luis.hernandez@correo.unimet.edu.ve',
  nombre: 'Luis',
  apellido: 'Hernández',
  rol: RolUsuario.estudiante,
  carnet: '20231110117',
  estadoActivo: false,
);

void main() {
  late _Datos datos;
  late GestionEstudiantesController controlador;

  setUp(() {
    datos = _Datos([_luis, _andrea]);
    controlador = GestionEstudiantesController(datos: datos);
  });

  Future<void> abrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: GestionEstudiantesView(controller: controlador)),
    );
    datos.emitir();
    await tester.pump();
  }

  bool interruptor(WidgetTester tester, String uid) =>
      tester.widget<SwitchListTile>(find.byKey(Key('estado-$uid'))).value;

  test('ordena, cuenta y busca estudiantes', () async {
    controlador.iniciar();
    datos.emitir();
    await Future<void>.delayed(Duration.zero);

    expect(controlador.estudiantes.map((e) => e.uid), ['andrea', 'luis']);
    expect(controlador.activos, 1);
    expect(controlador.inactivos, 1);

    controlador.buscar('2023');
    expect(controlador.estudiantes.single.uid, 'luis');
    controlador.buscar('v-2811');
    expect(controlador.estudiantes.single.uid, 'andrea');
    controlador.dispose();
  });

  testWidgets('el interruptor deshabilita y habilita en Firestore', (
    tester,
  ) async {
    await abrir(tester);
    expect(interruptor(tester, 'andrea'), isTrue);
    expect(interruptor(tester, 'luis'), isFalse);

    await tester.tap(find.byKey(const Key('estado-andrea')));
    await tester.pumpAndSettle();
    // Antes de deshabilitar pide confirmación y avisa del retiro.
    expect(find.byKey(const Key('dialogo-deshabilitar')), findsOneWidget);
    expect(find.textContaining('Se le retirará de inmediato'), findsOneWidget);
    expect(datos.cambios, isEmpty);

    await tester.tap(find.byKey(const Key('confirmar-deshabilitar')));
    await tester.pumpAndSettle();
    expect(datos.cambios, [('andrea', false)]);
    expect(datos.inscripciones['andrea'], isNull);
    expect(interruptor(tester, 'andrea'), isFalse);
    expect(
      find.text(
        'Andrea Pérez quedó deshabilitado. Se le retiró de 2 disciplinas.',
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('resumen-estudiantes'))).data,
      'Habilitados: 0 · Deshabilitados: 2',
    );

    // Habilitar no pide confirmación.
    await tester.tap(find.byKey(const Key('estado-luis')));
    await tester.pumpAndSettle();
    expect(datos.cambios.last, ('luis', true));
    expect(interruptor(tester, 'luis'), isTrue);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('cancelar la confirmación no deshabilita', (tester) async {
    await abrir(tester);

    await tester.tap(find.byKey(const Key('estado-andrea')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(datos.cambios, isEmpty);
    expect(datos.inscripciones['andrea'], {'fut', 'aje'});
    expect(interruptor(tester, 'andrea'), isTrue);
  });

  testWidgets('si Firestore rechaza el cambio, el interruptor vuelve', (
    tester,
  ) async {
    await abrir(tester);
    datos.fallo =
        'No tienes permiso para cambiar el estado de los estudiantes.';

    await tester.tap(find.byKey(const Key('estado-andrea')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmar-deshabilitar')));
    await tester.pumpAndSettle();

    expect(interruptor(tester, 'andrea'), isTrue);
    expect(find.textContaining('No tienes permiso'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}
