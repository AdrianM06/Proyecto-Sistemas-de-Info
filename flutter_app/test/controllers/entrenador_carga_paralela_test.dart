import 'package:flutter_app/controllers/entrenador_controller.dart';
import 'package:flutter_app/models/asistencia.dart';
import 'package:flutter_app/models/usuario.dart';
import 'package:flutter_app/services/entrenador_demo_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cuenta cuántas consultas de la disciplina están en curso a la vez.
class _Contador extends EntrenadorDemoService {
  _Contador({super.hoy}) : super(latencia: const Duration(milliseconds: 20));

  int activas = 0;
  int maximo = 0;

  Future<T> _medir<T>(Future<T> Function() consulta) async {
    activas++;
    if (activas > maximo) maximo = activas;
    try {
      return await consulta();
    } finally {
      activas--;
    }
  }

  @override
  Future<List<Usuario>> nominaDelDeporte(String deporteId) =>
      _medir(() => super.nominaDelDeporte(deporteId));

  @override
  Future<List<Asistencia>> historialDeAsistencia(String deporteId) =>
      _medir(() => super.historialDeAsistencia(deporteId));

  @override
  Future<Asistencia?> asistenciaDelDia(String deporteId, DateTime fecha) =>
      _medir(() => super.asistenciaDelDia(deporteId, fecha));
}

void main() {
  final lunes = DateTime(2026, 10, 19);

  test('nómina, historial y asistencia del día se piden en paralelo', () async {
    final datos = _Contador(hoy: lunes);
    final controlador = EntrenadorController(
      datos: datos,
      entrenadorId: EntrenadorDemoService.entrenadorDemoId,
      reloj: () => lunes,
    );

    await controlador.iniciar();
    expect(datos.maximo, 3);

    datos.maximo = 0;
    await controlador.seleccionarDeporte(controlador.deportes.last);
    expect(datos.maximo, 3);
    controlador.dispose();
  });

  test(
    'las marcas de la asistencia guardada se aplican tras la carga',
    () async {
      final datos = EntrenadorDemoService(latencia: Duration.zero, hoy: lunes);
      final controlador = EntrenadorController(
        datos: datos,
        entrenadorId: EntrenadorDemoService.entrenadorDemoId,
        reloj: () => lunes,
      );
      await controlador.iniciar();

      // Se guarda la asistencia de hoy y se vuelve a cargar la disciplina.
      controlador.marcarTodos(presentes: true);
      expect(await controlador.guardarAsistencia(), isTrue);
      await controlador.recargar();

      expect(controlador.sinMarcar, 0);
      expect(controlador.presentes, controlador.nomina.length);
      controlador.dispose();
    },
  );
}
