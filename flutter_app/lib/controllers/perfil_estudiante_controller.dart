import 'package:flutter/foundation.dart';

import '../models/usuario.dart';
import '../services/foto_perfil_service.dart';
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

  bool _subiendoFoto = false;
  bool _guardandoDatos = false;
  bool _liberado = false;
  Uint8List? _vistaPreviaFoto;

  /// Foto elegida mientras se sube: la pantalla la muestra de inmediato, sin
  /// esperar a que Storage responda.
  Uint8List? get vistaPreviaFoto => _vistaPreviaFoto;

  /// `true` si la cuenta es de administrador. Los administradores no pueden
  /// cambiar su contraseña desde la app.
  bool get esAdmin => _perfil?.usuario.rol == RolUsuario.admin;

  @override
  void dispose() {
    _liberado = true;
    super.dispose();
  }

  /// Una subida o consulta puede terminar cuando la pantalla ya se cerró;
  /// avisar a un notificador liberado lanzaría un error.
  @override
  void notifyListeners() {
    if (!_liberado) super.notifyListeners();
  }

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

  /// `true` mientras se sube la foto de perfil.
  bool get subiendoFoto => _subiendoFoto;

  /// `true` mientras se guardan el nombre y el apellido.
  bool get guardandoDatos => _guardandoDatos;

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
    if (esAdmin) {
      _errorClave = 'Los administradores no pueden cambiar la contraseña.';
      notifyListeners();
      return false;
    }
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

  /// Guarda el nombre y el apellido. Devuelve el error o `null` si se
  /// guardó. El carnet y la cédula no se pueden cambiar.
  Future<String?> actualizarDatos({
    required String nombre,
    required String apellido,
  }) async {
    final perfil = _perfil;
    if (perfil == null) return 'Tu perfil aún no se ha cargado.';
    final error = AppValidators.validateNombre(nombre) ??
        AppValidators.validateApellido(apellido);
    if (error != null) return error;

    final nombreLimpio = AppValidators.limpiarNombre(nombre);
    final apellidoLimpio = AppValidators.limpiarNombre(apellido);
    _guardandoDatos = true;
    notifyListeners();
    try {
      await _datos.actualizarDatos(
        nombre: nombreLimpio,
        apellido: apellidoLimpio,
      );
      _perfil = PerfilEstudiante(
        usuario: perfil.usuario.copiarCon(
          nombre: nombreLimpio,
          apellido: apellidoLimpio,
        ),
        saldo: perfil.saldo,
        disciplinas: perfil.disciplinas,
      );
      return null;
    } catch (e) {
      return 'No se pudieron guardar tus datos. Intenta de nuevo.';
    } finally {
      _guardandoDatos = false;
      notifyListeners();
    }
  }

  /// Sube una foto de perfil nueva. Devuelve el error o `null` si se subió.
  Future<String?> cambiarFoto(Uint8List bytes, {required String tipo}) async {
    final perfil = _perfil;
    if (perfil == null || _subiendoFoto) return null;
    final error = FotoPerfilService.validar(bytes, tipo);
    if (error != null) return error;

    _subiendoFoto = true;
    _vistaPreviaFoto = bytes;
    notifyListeners();
    try {
      final url = await _datos.subirFotoPerfil(bytes, tipo: tipo);
      _perfil = PerfilEstudiante(
        usuario: (_perfil ?? perfil).usuario.copiarCon(fotoUrl: url),
        saldo: (_perfil ?? perfil).saldo,
        disciplinas: (_perfil ?? perfil).disciplinas,
      );
      return null;
    } on FotoPerfilException catch (e) {
      return e.mensaje;
    } catch (e) {
      return 'No se pudo subir la foto. Intenta de nuevo.';
    } finally {
      _subiendoFoto = false;
      _vistaPreviaFoto = null;
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
