import '../models/deporte.dart';
import 'buscador_service.dart';

/// Fuente de datos de demostración para el buscador de deportes.
///
/// Guarda la oferta deportiva en memoria, así el buscador se puede probar y
/// presentar sin Firebase ni inicio de sesión. Se usa en
/// `lib/main_buscador_demo.dart` y en las pruebas.
class BuscadorDemoService implements BuscadorDataSource {
  BuscadorDemoService({this.latencia = const Duration(milliseconds: 300)});

  /// Tiempo de espera simulado de cada consulta.
  final Duration latencia;

  static const List<Deporte> _deportes = [
    Deporte(
      id: 'FUT-M01',
      nombre: 'Fútbol Masculino',
      disciplina: 'Fútbol',
      cupos: 25,
      entrenadorId: 'entrenador-demo',
      horarios: ['Lun 4:00–6:00 pm', 'Mié 4:00–6:00 pm'],
      lugar: 'Cancha principal',
    ),
    Deporte(
      id: 'FSA-01',
      nombre: 'Fútbol Sala Mixto',
      disciplina: 'Fútbol',
      cupos: 18,
      entrenadorId: 'entrenador-demo',
      horarios: ['Sáb 9:00–11:00 am'],
      lugar: 'Gimnasio cubierto',
    ),
    Deporte(
      id: 'BAL-M01',
      nombre: 'Baloncesto Masculino',
      disciplina: 'Baloncesto',
      cupos: 15,
      entrenadorId: 'entrenador-2',
      horarios: ['Mar 5:00–7:00 pm', 'Jue 5:00–7:00 pm'],
      lugar: 'Cancha techada',
    ),
    Deporte(
      id: 'VOL-F01',
      nombre: 'Voleibol Femenino',
      disciplina: 'Voleibol',
      cupos: 14,
      entrenadorId: 'entrenador-3',
      horarios: ['Mar 3:00–5:00 pm', 'Vie 3:00–5:00 pm'],
      lugar: 'Gimnasio cubierto',
    ),
    Deporte(
      id: 'NAT-01',
      nombre: 'Natación',
      disciplina: 'Natación',
      cupos: 20,
      entrenadorId: 'entrenador-4',
      horarios: ['Lun 7:00–8:30 am', 'Jue 7:00–8:30 am'],
      lugar: 'Piscina',
    ),
    Deporte(
      id: 'TEN-01',
      nombre: 'Tenis de Mesa',
      disciplina: 'Tenis de mesa',
      cupos: 10,
      entrenadorId: 'entrenador-5',
      horarios: ['Mié 2:00–4:00 pm'],
      lugar: 'Sala de usos múltiples',
    ),
    Deporte(
      id: 'AJE-01',
      nombre: 'Ajedrez',
      disciplina: 'Ajedrez',
      cupos: 30,
      entrenadorId: 'entrenador-6',
      horarios: ['Vie 1:00–3:00 pm'],
      lugar: 'Biblioteca, sala 2',
    ),
    Deporte(
      id: 'ATL-01',
      nombre: 'Atletismo',
      disciplina: 'Atletismo',
      cupos: 40,
      entrenadorId: 'entrenador-2',
      horarios: ['Mar 6:00–7:30 am', 'Sáb 7:00–9:00 am'],
      lugar: 'Pista de atletismo',
    ),
  ];

  /// Inscripciones activas de cada deporte. Voleibol Femenino está lleno.
  static const Map<String, int> _inscritos = {
    'FUT-M01': 8,
    'FSA-01': 3,
    'BAL-M01': 12,
    'VOL-F01': 14,
    'NAT-01': 17,
    'TEN-01': 4,
    'AJE-01': 11,
    'ATL-01': 22,
  };

  @override
  Future<List<Deporte>> todosLosDeportes() async {
    await Future<void>.delayed(latencia);
    return List.of(_deportes);
  }

  @override
  Future<Map<String, int>> inscritosPorDeporte() async {
    await Future<void>.delayed(latencia);
    return Map.of(_inscritos);
  }
}
