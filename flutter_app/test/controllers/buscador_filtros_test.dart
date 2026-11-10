import 'package:flutter_app/controllers/buscador_controller.dart';
import 'package:flutter_app/models/deporte.dart';
import 'package:flutter_app/services/buscador_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Datos con el mismo formato que hay guardado en Firestore: horarios en
/// texto libre con varios días, etiquetas y un documento vacío.
class _DatosReales implements BuscadorDataSource {
  @override
  Future<List<Deporte>> todosLosDeportes() async => const [
    Deporte(
      id: 'fut',
      nombre: 'Futbol Campo Masculino',
      disciplina: 'Futbol Campo',
      cupos: 30,
      entrenadoresIds: ['abc'],
      horarios: ['Lun y Mié 12:15 PM - 1:45 PM'],
      lugar: 'Cancha Futbol Campo',
      etiquetas: ['Profesional', 'Torneos'],
    ),
    Deporte(
      id: 'aje',
      nombre: 'Ajedrez',
      disciplina: 'Ajedrez',
      cupos: 20,
      entrenadoresIds: [],
      horarios: ['Martes y Jueves 3:00 PM - 5:00 PM'],
      etiquetas: ['Principiante'],
    ),
    Deporte(
      id: 'vacio',
      nombre: 'Sin nombre',
      disciplina: '',
      cupos: 0,
      entrenadoresIds: [],
      horarios: [''],
    ),
  ];

  @override
  Future<Map<String, int>> inscritosPorDeporte() async => const {};
}

void main() {
  late BuscadorController controlador;

  setUp(() async {
    controlador = BuscadorController(datos: _DatosReales());
    await controlador.iniciar();
  });

  tearDown(() => controlador.dispose());

  List<String> ids() => controlador.resultados.map((d) => d.id).toList();

  test('no muestra el documento vacío de la base de datos', () {
    expect(ids(), ['aje', 'fut']);
  });

  test('filtrar por el segundo día de un horario encuentra el deporte', () {
    controlador.elegirDia('Mié');
    expect(ids(), ['fut']);
  });

  test('filtrar por el primer día también funciona', () {
    controlador.elegirDia('Lun');
    expect(ids(), ['fut']);
  });

  test('lee los nombres completos de los días', () {
    controlador.elegirDia('Jue');
    expect(ids(), ['aje']);
  });

  test('un día sin entrenamientos no devuelve deportes', () {
    controlador.elegirDia('Dom');
    expect(ids(), isEmpty);
  });

  test('filtra por etiqueta y por disciplina', () {
    expect(controlador.etiquetas, ['Principiante', 'Profesional', 'Torneos']);

    controlador.elegirEtiqueta('Torneos');
    expect(ids(), ['fut']);

    controlador.limpiarFiltros();
    controlador.elegirDisciplina('Ajedrez');
    expect(ids(), ['aje']);
  });

  test('la búsqueda de texto también encuentra por etiqueta', () {
    controlador.buscar('principiante');
    expect(ids(), ['aje']);
  });

  test('los filtros se pueden combinar y limpiar', () {
    controlador.elegirDia('Mié');
    controlador.elegirEtiqueta('Principiante');
    expect(ids(), isEmpty);

    controlador.limpiarFiltros();
    expect(ids(), ['aje', 'fut']);
    expect(controlador.hayFiltros, isFalse);
  });

  group('filtro por rango de horas', () {
    test('deja las disciplinas que entrenan dentro de la franja', () {
      // Ajedrez: 3:00–5:00 pm. Fútbol: 12:15–1:45 pm.
      controlador.elegirRangoHoras(14 * 60, 18 * 60);
      expect(controlador.filtraPorHoras, isTrue);
      expect(ids(), ['aje']);

      controlador.elegirRangoHoras(12 * 60, 14 * 60);
      expect(ids(), ['fut']);

      // Una franja que corta el entrenamiento por la mitad no sirve.
      controlador.elegirRangoHoras(16 * 60, 20 * 60);
      expect(ids(), isEmpty);
    });

    test('se combina con el día elegido', () {
      controlador.elegirRangoHoras(12 * 60, 18 * 60);
      expect(ids(), ['aje', 'fut']);
      controlador.elegirDia('Mar');
      expect(ids(), ['aje']);
      controlador.elegirDia('Mié');
      expect(ids(), ['fut']);
    });

    test('se quita con null y con limpiarFiltros', () {
      controlador.elegirRangoHoras(6 * 60, 7 * 60);
      expect(ids(), isEmpty);
      expect(controlador.hayFiltros, isTrue);
      controlador.elegirRangoHoras(null, null);
      expect(ids(), ['aje', 'fut']);

      controlador.elegirRangoHoras(6 * 60, 7 * 60);
      controlador.limpiarFiltros();
      expect(controlador.filtraPorHoras, isFalse);
      expect(ids(), ['aje', 'fut']);
    });
  });
}
