import 'package:flutter_app/controllers/buscador_controller.dart';
import 'package:flutter_app/models/deporte.dart';
import 'package:flutter_app/services/buscador_demo_service.dart';
import 'package:flutter_app/services/buscador_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fuente de datos que siempre falla, para probar el mensaje de error.
class _FuenteConError implements BuscadorDataSource {
  @override
  Future<List<Deporte>> todosLosDeportes() async =>
      throw Exception('Sin conexión');

  @override
  Future<Map<String, int>> inscritosPorDeporte() async =>
      throw Exception('Sin conexión');
}

void main() {
  late BuscadorController controller;

  List<String> ids() => controller.resultados.map((d) => d.id).toList();
  Deporte deporte(String id) => controller.todos.firstWhere((d) => d.id == id);

  setUp(() async {
    controller = BuscadorController(
      datos: BuscadorDemoService(latencia: Duration.zero),
    );
    await controller.iniciar();
  });

  tearDown(() => controller.dispose());

  test('carga toda la oferta ordenada por nombre', () {
    expect(ids(), [
      'AJE-01',
      'ATL-01',
      'BAL-M01',
      'FUT-M01',
      'FSA-01',
      'NAT-01',
      'TEN-01',
      'VOL-F01',
    ]);
    expect(controller.error, isNull);
    expect(controller.cargando, isFalse);
    expect(controller.hayFiltros, isFalse);
  });

  test('arma la lista de disciplinas sin repetir', () {
    expect(controller.disciplinas, [
      'Ajedrez',
      'Atletismo',
      'Baloncesto',
      'Fútbol',
      'Natación',
      'Tenis de mesa',
      'Voleibol',
    ]);
  });

  test('calcula los cupos disponibles con las inscripciones activas', () {
    expect(controller.cuposDisponiblesDe(deporte('VOL-F01')), 0);
    expect(controller.cuposDisponiblesDe(deporte('FUT-M01')), 17);
    expect(controller.inscritosDe(deporte('FUT-M01')), 8);
  });

  test('la búsqueda ignora mayúsculas y acentos', () {
    controller.buscar('FUTBOL');
    expect(ids(), ['FUT-M01', 'FSA-01']);

    controller.buscar('natacion');
    expect(ids(), ['NAT-01']);
  });

  test('también busca por lugar', () {
    controller.buscar('gimnasio');
    expect(ids(), ['FSA-01', 'VOL-F01']);
  });

  test('filtra por disciplina y la quita al elegirla de nuevo', () {
    controller.elegirDisciplina('Fútbol');
    expect(ids(), ['FUT-M01', 'FSA-01']);

    controller.elegirDisciplina('Fútbol');
    expect(controller.disciplina, isNull);
    expect(controller.resultados, hasLength(8));
  });

  test('filtra por día de la semana', () {
    controller.elegirDia('Mar');
    expect(ids(), ['ATL-01', 'BAL-M01', 'VOL-F01']);

    controller.elegirDia('Sáb');
    expect(ids(), ['ATL-01', 'FSA-01']);
  });

  test('solo con cupos quita los deportes llenos', () {
    controller.cambiarSoloConCupos(true);
    expect(controller.resultados, hasLength(7));
    expect(ids(), isNot(contains('VOL-F01')));
  });

  test('los filtros se combinan', () {
    controller.elegirDia('Mar');
    controller.cambiarSoloConCupos(true);
    expect(ids(), ['ATL-01', 'BAL-M01']);
  });

  test('limpiar filtros vuelve a mostrar todo', () {
    controller.buscar('xyz');
    expect(controller.resultados, isEmpty);
    expect(controller.hayFiltros, isTrue);

    controller.limpiarFiltros();
    expect(controller.resultados, hasLength(8));
    expect(controller.hayFiltros, isFalse);
    expect(controller.texto, '');
  });

  test('si falla la carga deja un mensaje de error', () async {
    final conError = BuscadorController(datos: _FuenteConError());
    addTearDown(conError.dispose);

    await conError.iniciar();

    expect(conError.error, isNotNull);
    expect(conError.resultados, isEmpty);
    expect(conError.cargando, isFalse);
  });
}
