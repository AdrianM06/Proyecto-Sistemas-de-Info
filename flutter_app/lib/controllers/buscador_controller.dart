import 'package:flutter/foundation.dart';

import '../models/deporte.dart';
import '../services/buscador_service.dart';

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
  BuscadorController({required BuscadorDataSource datos}) : _datos = datos;

  final BuscadorDataSource _datos;

  // ---------------------------------------------------------------- estado

  bool _cargando = false;
  String? _error;
  List<Deporte> _todos = const [];
  Map<String, int> _inscritos = const {};
  List<Deporte> _resultados = const [];
  List<String> _disciplinas = const [];

  String _texto = '';
  String? _disciplina;
  String? _dia;
  bool _soloConCupos = false;

  bool get cargando => _cargando;
  String? get error => _error;
  String get texto => _texto;
  String? get disciplina => _disciplina;
  String? get dia => _dia;
  bool get soloConCupos => _soloConCupos;

  /// `true` si hay algún filtro o texto de búsqueda activo.
  bool get hayFiltros =>
      _texto.trim().isNotEmpty ||
      _disciplina != null ||
      _dia != null ||
      _soloConCupos;

  /// Todos los deportes cargados, sin filtrar.
  List<Deporte> get todos => List.unmodifiable(_todos);

  /// Deportes que cumplen todos los filtros activos, ordenados por nombre.
  List<Deporte> get resultados => List.unmodifiable(_resultados);

  /// Disciplinas distintas de la oferta, para los chips de filtro.
  List<String> get disciplinas => List.unmodifiable(_disciplinas);

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
      _todos = datos[0] as List<Deporte>;
      _inscritos = datos[1] as Map<String, int>;
    } catch (e) {
      _todos = const [];
      _inscritos = const {};
      _error =
          'No se pudo cargar la oferta deportiva. Revisa tu conexión e intenta de nuevo.';
    } finally {
      _cargando = false;
      _calcularDisciplinas();
      _filtrar();
      notifyListeners();
    }
  }

  /// Vuelve a pedir la oferta deportiva.
  Future<void> recargar() => iniciar();

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

  void _filtrar() {
    final texto = normalizar(_texto);
    final disciplina = _disciplina == null ? null : normalizar(_disciplina!);
    final dia = _dia == null ? null : normalizar(_dia!);

    final filtrados = _todos.where((deporte) {
      if (texto.isNotEmpty &&
          !normalizar(deporte.nombre).contains(texto) &&
          !normalizar(deporte.disciplina).contains(texto) &&
          !normalizar(deporte.lugar).contains(texto)) {
        return false;
      }
      if (disciplina != null && normalizar(deporte.disciplina) != disciplina) {
        return false;
      }
      if (dia != null &&
          !deporte.horarios.any((horario) => normalizar(horario).startsWith(dia))) {
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
