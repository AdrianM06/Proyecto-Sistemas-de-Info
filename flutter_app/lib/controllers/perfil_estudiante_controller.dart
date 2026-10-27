import 'package:flutter/foundation.dart';

import '../services/perfil_estudiante_service.dart';
import '../utils/app_validators.dart';

/// Controlador (la "C" de MVC) de la página de perfil del estudiante.
///
/// Carga el perfil, cambia la contraseña y retira disciplinas. La página
/// solo lee su estado y se redibuja con `notifyListeners()`.
class PerfilEstudianteController extends ChangeNotifier {
  PerfilEstudianteController({required PerfilEstudianteDataSource datos})
      : _datos = datos;

  final PerfilEstudianteDataSource _datos;

  bool _cargando = false;
  String? _error;
  PerfilEstudiante? _perfil;

  bool _cambiandoClave = false;
  String? _errorClave;
  String? _mensajeExito;

  String? _retirando;

  bool get cargando => _cargando;
  String? get error => _error;
  PerfilEstudiante? get perfil => _perfil;

  /// `true` mientras se procesa el cambio de contraseña.
  bool get cambiandoClave => _cambiandoClave;

  /// Error del formulario de cambio de clave (validación o Firebase).
  String? get errorClave => _errorClave;

  /// Mensaje de éxito después de cambiar la clave.
  String? get mensajeExito => _mensajeExito;

  /// Id de la inscripción que se está retirando, si hay una.
  String? get retirando => _retirando;

  Future<void> iniciar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _perfil = await _datos.cargarPerfil();
    } catch (e) {
      _error = 'No se pudo cargar tu perfil. Revisa tu conexión e intenta de nuevo.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> recargar() => iniciar();

  /// Limpia los mensajes del formulario al abrirlo de nuevo.
  void prepararCambioDeClave() {
    _errorClave = null;
    _mensajeExito = null;
    notifyListeners();
  }

  /// Valida los datos y cambia la contraseña. Devuelve `true` si se cambió.
  Future<bool> cambiarContrasena({
    required String actual,
    required String nueva,
    required String confirmacion,
  }) async {
    final errorValidacion = validarCambioDeClave(
      actual: actual,
      nueva: nueva,
      confirmacion: confirmacion,
    );
    if (errorValidacion != null) {
      _errorClave = errorValidacion;
      notifyListeners();
      return false;
    }

    _cambiandoClave = true;
    _errorClave = null;
    _mensajeExito = null;
    notifyListeners();
    try {
      await _datos.cambiarContrasena(actual: actual, nueva: nueva);
      _mensajeExito = '¡Tu contraseña se cambió con éxito!';
      return true;
    } on CambioClaveException catch (e) {
      _errorClave = e.mensaje;
      return false;
    } catch (e) {
      _errorClave = 'No se pudo cambiar la contraseña. Intenta de nuevo.';
      return false;
    } finally {
      _cambiandoClave = false;
      notifyListeners();
    }
  }

  /// Marca la inscripción como retirada y la quita de la lista.
  Future<bool> retirarDisciplina(DisciplinaInscrita disciplina) async {
    final perfil = _perfil;
    if (perfil == null || _retirando != null) return false;
    _retirando = disciplina.inscripcionId;
    _error = null;
    notifyListeners();
    try {
      await _datos.retirarDisciplina(disciplina.inscripcionId);
      _perfil = perfil.copiarCon(
        disciplinas: perfil.disciplinas
            .where((d) => d.inscripcionId != disciplina.inscripcionId)
            .toList(),
      );
      return true;
    } catch (e) {
      _error = 'No se pudo retirar la disciplina. Intenta de nuevo.';
      return false;
    } finally {
      _retirando = null;
      notifyListeners();
    }
  }

  /// Reglas del formulario de cambio de clave. Devuelve el primer error o
  /// `null` si todo está bien.
  static String? validarCambioDeClave({
    required String actual,
    required String nueva,
    required String confirmacion,
  }) {
    if (actual.isEmpty) return 'Escribe tu contraseña actual.';
    final errorNueva = AppValidators.validatePassword(nueva);
    if (errorNueva != null) return errorNueva;
    if (nueva != confirmacion) return 'Las contraseñas nuevas no coinciden.';
    if (nueva == actual) {
      return 'La nueva contraseña debe ser distinta a la actual.';
    }
    return null;
  }
}
