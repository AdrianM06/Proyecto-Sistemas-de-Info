import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/deporte.dart';
import '../models/inscripcion.dart';
import '../models/usuario.dart';
import 'firestore_service.dart';

/// Disciplina en la que el estudiante tiene una inscripción activa.
class DisciplinaInscrita {
  const DisciplinaInscrita({
    required this.inscripcionId,
    required this.deporteId,
    required this.nombre,
  });

  final String inscripcionId;
  final String deporteId;
  final String nombre;
}

/// Datos que muestra la página de perfil del estudiante.
class PerfilEstudiante {
  const PerfilEstudiante({
    required this.usuario,
    this.saldo = 0,
    this.disciplinas = const [],
  });

  final Usuario usuario;

  /// Saldo en cuenta en bolívares (campo `saldo` del documento del usuario).
  final double saldo;
  final List<DisciplinaInscrita> disciplinas;

  PerfilEstudiante copiarCon({List<DisciplinaInscrita>? disciplinas}) {
    return PerfilEstudiante(
      usuario: usuario,
      saldo: saldo,
      disciplinas: disciplinas ?? this.disciplinas,
    );
  }
}

/// Error al cambiar la contraseña, con un mensaje listo para mostrar.
class CambioClaveException implements Exception {
  const CambioClaveException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Operaciones de datos de la página de perfil del estudiante.
///
/// El controlador depende de esta interfaz; así la página funciona con
/// Firebase ([PerfilEstudianteService]) o con datos de ejemplo
/// ([PerfilEstudianteDemoService]) en las pruebas.
abstract class PerfilEstudianteDataSource {
  /// Perfil del estudiante con la sesión abierta.
  Future<PerfilEstudiante> cargarPerfil();

  /// Cambia la contraseña. Lanza [CambioClaveException] si no se pudo.
  Future<void> cambiarContrasena({
    required String actual,
    required String nueva,
  });

  /// Marca la inscripción como `retirada`.
  Future<void> retirarDisciplina(String inscripcionId);
}

/// Implementación real con Firebase Authentication y Cloud Firestore.
class PerfilEstudianteService implements PerfilEstudianteDataSource {
  PerfilEstudianteService({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService.instance;

  final FirestoreService _firestore;

  /// Firestore permite como máximo 30 valores en una consulta `whereIn`.
  static const int _maximoPorConsulta = 30;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  Future<PerfilEstudiante> cargarPerfil() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No hay una sesión abierta.');
    }

    final doc = await _firestore.users.doc(user.uid).get();
    final datos = doc.data() ?? const <String, dynamic>{};
    final usuario = _usuarioConNombre(
      Usuario.fromJson(datos, uid: user.uid),
      datos,
      user.email ?? '',
    );

    final inscripciones = (await _firestore.enrollments
            .where('estudianteId', isEqualTo: user.uid)
            .get())
        .docs
        .map(Inscripcion.fromFirestore)
        .where((inscripcion) => inscripcion.estaActiva)
        .toList();

    final nombres = await _nombresDeDeportes(
      inscripciones.map((inscripcion) => inscripcion.deporteId).toSet().toList(),
    );

    final disciplinas = [
      for (final inscripcion in inscripciones)
        DisciplinaInscrita(
          inscripcionId: inscripcion.id,
          deporteId: inscripcion.deporteId,
          nombre: nombres[inscripcion.deporteId] ?? inscripcion.deporteId,
        ),
    ]..sort((a, b) => a.nombre.compareTo(b.nombre));

    final saldo = datos['saldo'];
    return PerfilEstudiante(
      usuario: usuario,
      saldo: saldo is num ? saldo.toDouble() : 0,
      disciplinas: disciplinas,
    );
  }

  @override
  Future<void> cambiarContrasena({
    required String actual,
    required String nueva,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw const CambioClaveException(
        'Tu sesión expiró. Vuelve a iniciar sesión.',
      );
    }
    try {
      // Firebase exige confirmar la contraseña actual antes de cambiarla.
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: actual),
      );
      await user.updatePassword(nueva);
    } on FirebaseAuthException catch (e) {
      throw CambioClaveException(_mensajeDeError(e.code));
    }
  }

  @override
  Future<void> retirarDisciplina(String inscripcionId) {
    return _firestore.enrollments.doc(inscripcionId).update({
      'estado': 'retirada',
      'fechaRetiro': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, String>> _nombresDeDeportes(List<String> ids) async {
    final nombres = <String, String>{};
    for (var i = 0; i < ids.length; i += _maximoPorConsulta) {
      final grupo = ids.sublist(
        i,
        i + _maximoPorConsulta > ids.length ? ids.length : i + _maximoPorConsulta,
      );
      final resultado = await _firestore.sports
          .where(FieldPath.documentId, whereIn: grupo)
          .get();
      for (final doc in resultado.docs) {
        nombres[doc.id] = Deporte.fromFirestore(doc).nombre;
      }
    }
    return nombres;
  }

  /// Las cuentas creadas antes guardaban el nombre en `username`.
  static Usuario _usuarioConNombre(
    Usuario usuario,
    Map<String, dynamic> datos,
    String emailSesion,
  ) {
    final email = usuario.email.isNotEmpty ? usuario.email : emailSesion;
    var nombre = usuario.nombre;
    if (usuario.nombreCompleto.isEmpty) {
      final username = (datos['username'] ?? '').toString().trim();
      nombre = username.isNotEmpty
          ? username
          : (email.contains('@') ? email.split('@').first : 'Estudiante');
    }
    return Usuario(
      uid: usuario.uid,
      email: email,
      nombre: nombre,
      apellido: usuario.apellido,
      rol: usuario.rol,
      carnet: usuario.carnet,
      cedula: usuario.cedula,
      carrera: usuario.carrera,
      telefono: usuario.telefono,
      estadoActivo: usuario.estadoActivo,
    );
  }

  static String _mensajeDeError(String codigo) {
    switch (codigo) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'La contraseña actual no es correcta.';
      case 'weak-password':
        return 'La nueva contraseña es muy débil.';
      case 'requires-recent-login':
        return 'Por seguridad, cierra sesión y vuelve a entrar antes de cambiar la clave.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento e intenta de nuevo.';
      case 'network-request-failed':
        return 'Sin conexión. Revisa tu internet e intenta de nuevo.';
      default:
        return 'No se pudo cambiar la contraseña. Intenta de nuevo.';
    }
  }
}

/// Datos de ejemplo en memoria para la demo y las pruebas.
class PerfilEstudianteDemoService implements PerfilEstudianteDataSource {
  PerfilEstudianteDemoService({
    this.latencia = const Duration(milliseconds: 300),
    this.saldo = 0,
    String contrasena = contrasenaDemo,
  }) : _contrasena = contrasena;

  /// Contraseña inicial de la cuenta de ejemplo.
  static const String contrasenaDemo = 'Clave1234';

  final Duration latencia;
  final double saldo;
  String _contrasena;

  final List<DisciplinaInscrita> _disciplinas = [
    const DisciplinaInscrita(
      inscripcionId: 'insc-01',
      deporteId: 'FUT-M01',
      nombre: 'Fútbol Masculino',
    ),
    const DisciplinaInscrita(
      inscripcionId: 'insc-02',
      deporteId: 'NAT-01',
      nombre: 'Natación',
    ),
  ];

  /// Contraseña vigente (para revisar en las pruebas).
  String get contrasenaActual => _contrasena;

  @override
  Future<PerfilEstudiante> cargarPerfil() async {
    await Future<void>.delayed(latencia);
    return PerfilEstudiante(
      usuario: const Usuario(
        uid: 'est-01',
        email: 'andrea.perez@correo.unimet.edu.ve',
        nombre: 'Andrea',
        apellido: 'Pérez',
        rol: RolUsuario.estudiante,
        carnet: '20221110342',
        carrera: 'Ingeniería de Sistemas',
      ),
      saldo: saldo,
      disciplinas: List.of(_disciplinas),
    );
  }

  @override
  Future<void> cambiarContrasena({
    required String actual,
    required String nueva,
  }) async {
    await Future<void>.delayed(latencia);
    if (actual != _contrasena) {
      throw const CambioClaveException('La contraseña actual no es correcta.');
    }
    _contrasena = nueva;
  }

  @override
  Future<void> retirarDisciplina(String inscripcionId) async {
    await Future<void>.delayed(latencia);
    _disciplinas.removeWhere((d) => d.inscripcionId == inscripcionId);
  }
}
