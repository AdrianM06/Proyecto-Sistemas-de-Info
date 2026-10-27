import '../models/asistencia.dart';
import '../models/conversores.dart';
import '../models/deporte.dart';
import '../models/usuario.dart';
import 'entrenador_service.dart';

/// Fuente de datos de demostración para la vista del entrenador.
///
/// Guarda todo en memoria con datos de ejemplo, así la vista se puede probar
/// y presentar sin Firebase ni inicio de sesión. Se usa en
/// `lib/main_entrenador_demo.dart` y en las pruebas.
class EntrenadorDemoService implements EntrenadorDataSource {
  EntrenadorDemoService({
    this.latencia = const Duration(milliseconds: 300),
    DateTime? hoy,
  }) : _hoy = soloFecha(hoy ?? DateTime.now()) {
    _crearHistorialDeEjemplo();
  }

  /// Id del entrenador de ejemplo.
  static const String entrenadorDemoId = 'entrenador-demo';

  /// Nombre del entrenador de ejemplo.
  static const String entrenadorDemoNombre = 'Carlos Gutiérrez';

  /// Tiempo de espera simulado de cada consulta.
  final Duration latencia;
  final DateTime _hoy;

  final List<Deporte> _deportes = const [
    Deporte(
      id: 'FUT-M01',
      nombre: 'Fútbol Masculino',
      disciplina: 'Fútbol',
      cupos: 25,
      entrenadorId: entrenadorDemoId,
      horarios: ['Lun 4:00–6:00 pm', 'Mié 4:00–6:00 pm'],
      lugar: 'Cancha principal',
    ),
    Deporte(
      id: 'FSA-01',
      nombre: 'Fútbol Sala Mixto',
      disciplina: 'Fútbol Sala',
      cupos: 18,
      entrenadorId: entrenadorDemoId,
      horarios: ['Sáb 9:00–11:00 am'],
      lugar: 'Polideportivo',
    ),
    Deporte(
      id: 'BAL-M01',
      nombre: 'Baloncesto Masculino',
      disciplina: 'Baloncesto',
      cupos: 20,
      entrenadorId: 'otro-entrenador',
      horarios: ['Mar 5:00–7:00 pm'],
      lugar: 'Polideportivo',
    ),
  ];

  final List<Usuario> _estudiantes = const [
    Usuario(uid: 'est-01', email: 'andrea.perez@correo.unimet.edu.ve', nombre: 'Andrea', apellido: 'Pérez', rol: RolUsuario.estudiante, carnet: '20221110342'),
    Usuario(uid: 'est-02', email: 'luis.hernandez@correo.unimet.edu.ve', nombre: 'Luis', apellido: 'Hernández', rol: RolUsuario.estudiante, carnet: '20231110117'),
    Usuario(uid: 'est-03', email: 'valentina.rojas@correo.unimet.edu.ve', nombre: 'Valentina', apellido: 'Rojas', rol: RolUsuario.estudiante, carnet: '20211110589'),
    Usuario(uid: 'est-04', email: 'diego.morales@correo.unimet.edu.ve', nombre: 'Diego', apellido: 'Morales', rol: RolUsuario.estudiante, carnet: '20231110823'),
    Usuario(uid: 'est-05', email: 'camila.suarez@correo.unimet.edu.ve', nombre: 'Camila', apellido: 'Suárez', rol: RolUsuario.estudiante, carnet: '20221110456'),
    Usuario(uid: 'est-06', email: 'jose.diaz@correo.unimet.edu.ve', nombre: 'José Gregorio', apellido: 'Díaz', rol: RolUsuario.estudiante, carnet: '20201110231'),
    Usuario(uid: 'est-07', email: 'sofia.marquez@correo.unimet.edu.ve', nombre: 'Sofía', apellido: 'Márquez', rol: RolUsuario.estudiante, carnet: '20231110962'),
    Usuario(uid: 'est-08', email: 'sebastian.useche@correo.unimet.edu.ve', nombre: 'Sebastián', apellido: 'Useche', rol: RolUsuario.estudiante, carnet: '20221110704'),
  ];

  /// Estudiantes inscritos (inscripción activa) en cada deporte.
  final Map<String, List<String>> _inscritos = const {
    'FUT-M01': ['est-01', 'est-02', 'est-03', 'est-04', 'est-05', 'est-06', 'est-07', 'est-08'],
    'FSA-01': ['est-02', 'est-05', 'est-07'],
    'BAL-M01': ['est-04'],
  };

  final Map<String, Asistencia> _asistencias = {};

  void _crearHistorialDeEjemplo() {
    // Cuatro sesiones anteriores de Fútbol Masculino, una por semana.
    const presentesPorSesion = [
      ['est-01', 'est-02', 'est-03', 'est-04', 'est-05', 'est-07', 'est-08'],
      ['est-01', 'est-02', 'est-04', 'est-05', 'est-07'],
      ['est-01', 'est-02', 'est-03', 'est-04', 'est-07', 'est-08'],
      ['est-01', 'est-03', 'est-04', 'est-05', 'est-06', 'est-07'],
    ];
    for (var semana = 0; semana < presentesPorSesion.length; semana++) {
      final fecha = _hoy.subtract(Duration(days: 7 * (semana + 1)));
      final asistencia = Asistencia(
        deporteId: 'FUT-M01',
        fecha: fecha,
        entrenadorId: entrenadorDemoId,
        presentes: presentesPorSesion[semana],
      );
      _asistencias[asistencia.id] = asistencia;
    }
  }

  Future<void> _esperar() =>
      latencia == Duration.zero ? Future.value() : Future.delayed(latencia);

  @override
  Future<List<Deporte>> deportesDelEntrenador(String entrenadorId) async {
    await _esperar();
    return _deportes
        .where((deporte) => deporte.entrenadorId == entrenadorId)
        .toList();
  }

  @override
  Future<List<Usuario>> nominaDelDeporte(String deporteId) async {
    await _esperar();
    final ids = _inscritos[deporteId] ?? const [];
    final nomina = _estudiantes.where((e) => ids.contains(e.uid)).toList()
      ..sort((a, b) => a.apellido.compareTo(b.apellido));
    return nomina;
  }

  @override
  Future<Asistencia?> asistenciaDelDia(String deporteId, DateTime fecha) async {
    await _esperar();
    return _asistencias[Asistencia.idPara(deporteId, fecha)];
  }

  @override
  Future<List<Asistencia>> historialDeAsistencia(String deporteId) async {
    await _esperar();
    return _asistencias.values
        .where((asistencia) => asistencia.deporteId == deporteId)
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  @override
  Future<void> guardarAsistencia(Asistencia asistencia) async {
    await _esperar();
    _asistencias[asistencia.id] = asistencia;
  }
}
