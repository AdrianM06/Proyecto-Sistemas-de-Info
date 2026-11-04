import 'package:flutter/foundation.dart';

import '../models/deporte.dart';
import '../services/buscador_service.dart';
import '../services/inscripcion_service.dart';
import '../utils/horarios.dart';

/// Días que se pueden elegir en el filtro del buscador.
const List<String> diasDeLaSemana = [
  'Lun',
  'Mar',
  'Mié',
  'Jue',
  'Vie',
  'Sáb',
  'Dom',
];

const Map<String, String> _sinAcentos = {
  'á': 'a',
  'é': 'e',
  'í': 'i',
  'ó': 'o',
  'ú': 'u',
  'ü': 'u',
  'ñ': 'n',
  'Á': 'a',
  'É': 'e',
  'Í': 'i',
  'Ó': 'o',
  'Ú': 'u',
  'Ü': 'u',
  'Ñ': 'n',
};

/// Minúsculas y sin acentos: "Fútbol Sala" → "futbol sala".
///
/// Se usa para que la búsqueda no dependa de tildes ni mayúsculas.
String normalizar(String texto) {
  final buffer = StringBuffer();
  for (final letra in texto.split('')) {
    buffer.write(_sinAcentos[letra] ?? letra);
  }
  return buffer.toString().toLowerCase().trim();
}

/// Controlador (la "C" de MVC) del buscador de deportes.
///
/// Pide la oferta deportiva una sola vez a un [BuscadorDataSource] y después
/// aplica la búsqueda y los filtros en memoria. La pantalla solo lee su
/// estado y se redibuja cuando el controlador llama a `notifyListeners()`.
class BuscadorController extends ChangeNotifier {
  /// Con [inscripciones] y [estudianteId] el buscador deja que el estudiante
  /// se inscriba en una disciplina; sin ellos solo muestra la oferta.
  BuscadorController({
    required BuscadorDataSource datos,
    InscripcionesDataSource? inscripciones,
    String? estudianteId,
  })  : _datos = datos,
        _inscripciones = inscripciones,
        _estudianteId = estudianteId;

  final BuscadorDataSource _datos;
  final InscripcionesDataSource? _inscripciones;
  final String? _estudianteId;

  Set<String> _misDeportes = const {};
  String? _inscribiendo;

  /// `true` si el estudiante puede inscribirse desde el buscador.
  bool get permiteInscribir => _inscripciones != null && _estudianteId != null;

  /// `true` si el estudiante ya tiene una inscripción activa en el deporte.
  bool estaInscrito(Deporte deporte) => _misDeportes.contains(deporte.id);

  /// Id del deporte que se está inscribiendo ahora, si hay uno.
  String? get inscribiendo => _inscribiendo;

  // ---------------------------------------------------------------- estado

  bool _cargando = false;
  String? _error;
  List<Deporte> _todos = const [];
  Map<String, int> _inscritos = const {};
  List<Deporte> _resultados = const [];
  List<String> _disciplinas = const [];
  List<String> _etiquetas = const [];

  String _texto = '';
  String? _disciplina;
  String? _etiqueta;
  String? _dia;
  bool _soloConCupos = false;

  bool get cargando => _cargando;
  String? get error => _error;
  String get texto => _texto;
  String? get disciplina => _disciplina;
  String? get etiqueta => _etiqueta;
  String? get dia => _dia;
  bool get soloConCupos => _soloConCupos;

  /// `true` si hay algún filtro o texto de búsqueda activo.
  bool get hayFiltros =>
      _texto.trim().isNotEmpty ||
      _disciplina != null ||
      _etiqueta != null ||
      _dia != null ||
      _soloConCupos;

  /// Todos los deportes cargados, sin filtrar.
  List<Deporte> get todos => List.unmodifiable(_todos);

  /// Deportes que cumplen todos los filtros activos, ordenados por nombre.
  List<Deporte> get resultados => List.unmodifiable(_resultados);

  /// Disciplinas distintas de la oferta, para los chips de filtro.
  List<String> get disciplinas => List.unmodifiable(_disciplinas);

  /// Etiquetas distintas de la oferta (por ejemplo "Torneos"), para los
  /// chips de filtro.
  List<String> get etiquetas => List.unmodifiable(_etiquetas);

  /// Inscripciones activas del deporte.
  int inscritosDe(Deporte deporte) => _inscritos[deporte.id] ?? 0;

  /// Cupos libres del deporte (nunca negativo).
  int cuposDisponiblesDe(Deporte deporte) {
    final libres = deporte.cupos - inscritosDe(deporte);
    return libres > 0 ? libres : 0;
  }

  // --------------------------------------------------------------- acciones

  /// Carga los deportes y sus inscritos.
  Future<void> iniciar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final datos = await Future.wait([
        _datos.todosLosDeportes(),
        _datos.inscritosPorDeporte(),
      ]);
      // Los documentos de `sports` sin nombre son registros vacíos que no
      // se pueden inscribir; no se muestran.
      _todos = (datos[0] as List<Deporte>)
          .where((deporte) => deporte.nombre.trim().isNotEmpty)
          .where((deporte) => deporte.nombre != 'Sin nombre')
          .toList();
      _inscritos = datos[1] as Map<String, int>;
      await _cargarMisDeportes();
    } catch (e) {
      _todos = const [];
      _inscritos = const {};
      _error =
          'No se pudo cargar la oferta deportiva. Revisa tu conexión e intenta de nuevo.';
    } finally {
      _cargando = false;
      _calcularDisciplinas();
      _calcularEtiquetas();
      _filtrar();
      notifyListeners();
    }
  }

  /// Vuelve a pedir la oferta deportiva.
  Future<void> recargar() => iniciar();

  /// Inscribe al estudiante en [deporte]. Devuelve el mensaje de error o
  /// `null` si quedó inscrito.
  Future<String?> inscribirse(Deporte deporte) async {
    final inscripciones = _inscripciones;
    final estudianteId = _estudianteId;
    if (inscripciones == null || estudianteId == null) {
      return 'Inicia sesión como estudiante para inscribirte.';
    }
    if (_inscribiendo != null) return null;
    if (estaInscrito(deporte)) return 'Ya estás inscrito en ${deporte.nombre}.';

    _inscribiendo = deporte.id;
    notifyListeners();
    try {
      await inscripciones.inscribir(
        estudianteId: estudianteId,
        deporte: deporte,
      );
      _misDeportes = {..._misDeportes, deporte.id};
      _inscritos = {..._inscritos, deporte.id: inscritosDe(deporte) + 1};
      _filtrar();
      return null;
    } on InscripcionException catch (e) {
      return e.mensaje;
    } catch (e) {
      return 'No se pudo completar la inscripción. Intenta de nuevo.';
    } finally {
      _inscribiendo = null;
      notifyListeners();
    }
  }

  /// Carga los deportes donde el estudiante ya está inscrito. Si falla, el
  /// catálogo se muestra igual y el servicio revisa al inscribirse.
  Future<void> _cargarMisDeportes() async {
    final inscripciones = _inscripciones;
    final estudianteId = _estudianteId;
    if (inscripciones == null || estudianteId == null) return;
    try {
      _misDeportes = await inscripciones.deportesInscritos(estudianteId);
    } catch (_) {
      _misDeportes = const {};
    }
  }

  void buscar(String texto) {
    _texto = texto;
    _filtrar();
    notifyListeners();
  }

  /// Elige una disciplina; elegir la misma que ya está activa la quita.
  void elegirDisciplina(String? disciplina) {
    _disciplina = disciplina == _disciplina ? null : disciplina;
    _filtrar();
    notifyListeners();
  }

  /// Elige una etiqueta; elegir la misma que ya está activa la quita.
  void elegirEtiqueta(String? etiqueta) {
    _etiqueta = etiqueta == _etiqueta ? null : etiqueta;
    _filtrar();
    notifyListeners();
  }

  /// Elige un día de [diasDeLaSemana]; elegir el mismo lo quita.
  void elegirDia(String? dia) {
    _dia = dia == _dia ? null : dia;
    _filtrar();
    notifyListeners();
  }

  void cambiarSoloConCupos(bool valor) {
    _soloConCupos = valor;
    _filtrar();
    notifyListeners();
  }

  void limpiarFiltros() {
    _texto = '';
    _disciplina = null;
    _etiqueta = null;
    _dia = null;
    _soloConCupos = false;
    _filtrar();
    notifyListeners();
  }

  // ---------------------------------------------------------------- internos

  void _calcularDisciplinas() {
    final unicas = <String, String>{};
    for (final deporte in _todos) {
      final disciplina = deporte.disciplina.trim();
      if (disciplina.isEmpty) continue;
      unicas.putIfAbsent(normalizar(disciplina), () => disciplina);
    }
    final claves = unicas.keys.toList()..sort();
    _disciplinas = [for (final clave in claves) unicas[clave]!];
  }

  void _calcularEtiquetas() {
    final unicas = <String, String>{};
    for (final deporte in _todos) {
      for (final etiqueta in deporte.etiquetas) {
        final limpia = etiqueta.trim();
        if (limpia.isEmpty) continue;
        unicas.putIfAbsent(normalizar(limpia), () => limpia);
      }
    }
    final claves = unicas.keys.toList()..sort();
    _etiquetas = [for (final clave in claves) unicas[clave]!];
  }

  void _filtrar() {
    final texto = normalizar(_texto);
    final disciplina = _disciplina == null ? null : normalizar(_disciplina!);
    final etiqueta = _etiqueta == null ? null : normalizar(_etiqueta!);
    final dia = _dia == null ? null : numeroDeDia(_dia!);

    final filtrados = _todos.where((deporte) {
      if (texto.isNotEmpty &&
          !normalizar(deporte.nombre).contains(texto) &&
          !normalizar(deporte.disciplina).contains(texto) &&
          !normalizar(deporte.lugar).contains(texto) &&
          !deporte.etiquetas.any((e) => normalizar(e).contains(texto))) {
        return false;
      }
      if (disciplina != null && normalizar(deporte.disciplina) != disciplina) {
        return false;
      }
      if (etiqueta != null &&
          !deporte.etiquetas.any((e) => normalizar(e) == etiqueta)) {
        return false;
      }
      // Los horarios son texto libre ("Lun y Mié 12:15 PM - 1:45 PM"): se
      // leen todos los días que nombran, no solo el primero.
      if (dia != null && !deporte.diasDeEntrenamiento.contains(dia)) {
        return false;
      }
      if (_soloConCupos && cuposDisponiblesDe(deporte) == 0) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => normalizar(a.nombre).compareTo(normalizar(b.nombre)));

    _resultados = filtrados;
  }
}
