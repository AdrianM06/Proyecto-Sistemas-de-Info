import 'package:flutter/foundation.dart';

import '../models/deporte.dart';
import '../services/buscador_service.dart';
import '../services/inscripcion_service.dart';
import '../utils/horarios.dart';

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

String normalizar(String texto) {
  final buffer = StringBuffer();
  for (final letra in texto.split('')) {
    buffer.write(_sinAcentos[letra] ?? letra);
  }
  return buffer.toString().toLowerCase().trim();
}

class BuscadorController extends ChangeNotifier {
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

  bool get permiteInscribir => _inscripciones != null && _estudianteId != null;
  bool estaInscrito(Deporte deporte) => _misDeportes.contains(deporte.id);
  String? get inscribiendo => _inscribiendo;

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

  bool get hayFiltros =>
      _texto.trim().isNotEmpty ||
      _disciplina != null ||
      _etiqueta != null ||
      _dia != null ||
      _soloConCupos;

  List<Deporte> get todos => List.unmodifiable(_todos);
  List<Deporte> get resultados => List.unmodifiable(_resultados);
  List<String> get disciplinas => List.unmodifiable(_disciplinas);
  List<String> get etiquetas => List.unmodifiable(_etiquetas);

  int inscritosDe(Deporte deporte) => _inscritos[deporte.id] ?? 0;

  int cuposDisponiblesDe(Deporte deporte) {
    final libres = deporte.cupos - inscritosDe(deporte);
    return libres > 0 ? libres : 0;
  }

  Future<void> iniciar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final datos = await Future.wait([
        _datos.todosLosDeportes(),
        _datos.inscritosPorDeporte(),
      ]);
      _todos = (datos[0] as List<Deporte>)
          .where((deporte) => deporte.nombre.trim().isNotEmpty)
          .where((deporte) => deporte.nombre != 'Sin nombre')
          .toList();
      _inscritos = datos[1] as Map<String, int>;
      await _cargarMisDeportes();
    } catch (e) {
      _todos = const [];
      _inscritos = const {};
      _error = 'No se pudo cargar la oferta deportiva.';
    } finally {
      _cargando = false;
      _calcularDisciplinas();
      _calcularEtiquetas();
      _filtrar();
      notifyListeners();
    }
  }

  Future<void> recargar() => iniciar();

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
      return 'No se pudo completar la inscripción.';
    } finally {
      _inscribiendo = null;
      notifyListeners();
    }
  }

  Future<String?> cancelarInscripcion(Deporte deporte) async {
    final inscripciones = _inscripciones;
    final estudianteId = _estudianteId;
    if (inscripciones == null || estudianteId == null) return null;

    _inscribiendo = deporte.id;
    notifyListeners();
    try {
      await inscripciones.cancelar(
        estudianteId: estudianteId,
        deporteId: deporte.id,
      );
      _misDeportes = _misDeportes.where((id) => id != deporte.id).toSet();
      final actual = inscritosDe(deporte);
      _inscritos = {
        ..._inscritos,
        deporte.id: actual > 0 ? actual - 1 : 0,
      };
      _filtrar();
      return null;
    } on InscripcionException catch (e) {
      return e.mensaje;
    } catch (e) {
      return 'No se pudo cancelar la inscripción.';
    } finally {
      _inscribiendo = null;
      notifyListeners();
    }
  }

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

  void elegirDisciplina(String? disciplina) {
    _disciplina = disciplina == _disciplina ? null : disciplina;
    _filtrar();
    notifyListeners();
  }

  void elegirEtiqueta(String? etiqueta) {
    _etiqueta = etiqueta == _etiqueta ? null : etiqueta;
    _filtrar();
    notifyListeners();
  }

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