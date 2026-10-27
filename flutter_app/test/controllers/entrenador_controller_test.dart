import 'package:flutter_app/controllers/entrenador_controller.dart';
import 'package:flutter_app/models/asistencia.dart';
import 'package:flutter_app/services/entrenador_demo_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final hoy = DateTime(2026, 10, 21);

  late EntrenadorDemoService datos;
  late EntrenadorController controller;

  setUp(() async {
    datos = EntrenadorDemoService(latencia: Duration.zero, hoy: hoy);
    controller = EntrenadorController(
      datos: datos,
      entrenadorId: EntrenadorDemoService.entrenadorDemoId,
      reloj: () => hoy,
    );
    await controller.iniciar();
  });

  tearDown(() => controller.dispose());

  test('carga solo las disciplinas del entrenador y elige la primera', () {
    expect(controller.deportes.map((d) => d.id), ['FUT-M01', 'FSA-01']);
    expect(controller.deporteActual?.id, 'FUT-M01');
    expect(controller.error, isNull);
  });

  test('la nómina trae los inscritos y el buscador filtra por nombre o carnet', () {
    expect(controller.inscritos, 8);
    expect(controller.cuposDisponibles, 17);

    controller.buscarEnNomina('rojas');
    expect(controller.nominaFiltrada.single.nombreCompleto, 'Valentina Rojas');

    controller.buscarEnNomina('20231110117');
    expect(controller.nominaFiltrada.single.nombre, 'Luis');

    controller.buscarEnNomina('');
    expect(controller.nominaFiltrada, hasLength(8));
  });

  test('calcula el porcentaje de asistencia con el historial', () {
    expect(controller.historial, hasLength(4));
    expect(controller.porcentajeDe('est-01'), 1.0);
    expect(controller.porcentajeDe('est-06'), 0.25);
    expect(
      controller.estudiantesEnRiesgo().map((e) => e.uid),
      containsAll(['est-06']),
    );
  });

  test('no guarda si faltan estudiantes por marcar', () async {
    controller.marcar('est-01', presente: true);

    final guardado = await controller.guardarAsistencia();

    expect(guardado, isFalse);
    expect(controller.error, 'Faltan 7 estudiantes por marcar.');
    expect(await datos.asistenciaDelDia('FUT-M01', hoy), isNull);
  });

  test('guarda la asistencia con la lista de presentes', () async {
    controller.marcarTodos(presentes: true);
    controller.marcar('est-03', presente: false);

    expect(controller.presentes, 7);
    expect(controller.ausentes, 1);
    expect(controller.sinMarcar, 0);

    final guardado = await controller.guardarAsistencia();

    expect(guardado, isTrue);
    final Asistencia? guardada = await datos.asistenciaDelDia('FUT-M01', hoy);
    expect(guardada, isNotNull);
    expect(guardada!.presentes, hasLength(7));
    expect(guardada.estaPresente('est-03'), isFalse);
    expect(controller.historial.first.fecha, hoy);
    expect(controller.historial, hasLength(5));
  });

  test('al volver a una fecha guardada se cargan sus marcas', () async {
    final semanaPasada = hoy.subtract(const Duration(days: 7));

    await controller.cambiarFecha(semanaPasada);

    expect(controller.marcaDe('est-01'), isTrue);
    expect(controller.marcaDe('est-06'), isFalse);
    expect(controller.sinMarcar, 0);
  });

  test('cambiar de disciplina carga su propia nómina', () async {
    final futbolSala = controller.deportes.firstWhere((d) => d.id == 'FSA-01');

    await controller.seleccionarDeporte(futbolSala);

    expect(controller.deporteActual?.id, 'FSA-01');
    expect(controller.inscritos, 3);
    expect(controller.historial, isEmpty);
    expect(controller.promedioAsistencia, isNull);
  });
}
