import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import '../utils/app_validators.dart';

/// Roles que puede tener una cuenta (campo `rol` de la colección `users`).
class RolesUsuario {
  RolesUsuario._();

  static const String estudiante = 'estudiante';
  static const String entrenador = 'entrenador';
  static const String admin = 'admin';

  /// Normaliza el texto guardado en Firestore. Cualquier valor desconocido
  /// se toma como estudiante (el rol con menos permisos).
  static String desdeTexto(Object? valor) {
    final texto = (valor ?? '').toString().trim().toLowerCase();
    if (texto == entrenador) return entrenador;
    if (texto == admin || texto == 'administrador') return admin;
    return estudiante;
  }

  /// Nombre del rol para mostrar en pantalla.
  static String nombreVisible(String rol) {
    switch (rol) {
      case admin:
        return 'administrador';
      case entrenador:
        return 'entrenador';
      default:
        return 'estudiante';
    }
  }
}

/// Datos mínimos del usuario que inició sesión: lo que necesita la
/// navegación para decidir a qué vista enviarlo.
class SesionUsuario {
  const SesionUsuario({
    required this.uid,
    required this.email,
    required this.nombre,
    required this.rol,
  });

  final String uid;
  final String email;
  final String nombre;

  /// `RolesUsuario.estudiante`, `RolesUsuario.entrenador` o
  /// `RolesUsuario.admin`.
  final String rol;

  bool get esEntrenador => rol == RolesUsuario.entrenador;
  bool get esEstudiante => rol == RolesUsuario.estudiante;
  bool get esAdmin => rol == RolesUsuario.admin;
}

/// Patrón Singleton: único punto de acceso a Firebase Authentication y al
/// perfil de los usuarios en Firestore (colección `users`).
class AuthService {
  AuthService._privateConstructor();
  static final AuthService instance = AuthService._privateConstructor();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _carnets =>
      _firestore.collection('carnets');
  CollectionReference<Map<String, dynamic>> get _cedulas =>
      _firestore.collection('cedulas');

  /// Usuario de Firebase Authentication con la sesión abierta, si hay uno.
  User? get usuarioActual => _auth.currentUser;

  // --------------------------------------------------------------- registro

  /// Registro público de **estudiantes**: valida todos los datos, revisa que
  /// el carnet y la cédula no estén registrados, crea la cuenta en Firebase
  /// Authentication y guarda en un solo lote (batch) el perfil
  /// `users/{uid}` y los índices `carnets/{carnet}` y `cedulas/{cedula}`.
  ///
  /// Los entrenadores los registra el administrador con
  /// [registrarEntrenador].
  ///
  /// Errores (como [FirebaseAuthException]): `datos-invalidos`,
  /// `carnet-already-in-use`, `cedula-already-in-use`,
  /// `email-already-in-use`, `weak-password`. Si falla el guardado del
  /// perfil se borra la cuenta recién creada para no dejar usuarios a medias.
  Future<SesionUsuario> registerUser({
    required String nombre,
    required String apellido,
    required String email,
    required String cedula,
    required String carnet,
    required String password,
  }) async {
    final error = AppValidators.validarRegistroEstudiante(
      nombre: nombre,
      apellido: apellido,
      email: email,
      cedula: cedula,
      carnet: carnet,
      password: password,
    );
    if (error != null) {
      throw FirebaseAuthException(code: 'datos-invalidos', message: error);
    }

    final nombreLimpio = AppValidators.limpiarNombre(nombre);
    final apellidoLimpio = AppValidators.limpiarNombre(apellido);
    final correo = email.trim().toLowerCase();
    final carnetLimpio = carnet.trim();
    final cedulaLimpia = AppValidators.normalizarCedula(cedula)!;

    if ((await _carnets.doc(carnetLimpio).get()).exists) {
      throw FirebaseAuthException(
        code: 'carnet-already-in-use',
        message: 'Ese carnet ya está registrado.',
      );
    }
    if ((await _cedulas.doc(cedulaLimpia).get()).exists) {
      throw FirebaseAuthException(
        code: 'cedula-already-in-use',
        message: 'Esa cédula ya está registrada.',
      );
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: correo,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-created',
        message: 'No se pudo crear la cuenta. Intenta de nuevo.',
      );
    }

    try {
      final lote = _firestore.batch()
        ..set(_users.doc(user.uid), {
          'uid': user.uid,
          'email': correo,
          'nombre': nombreLimpio,
          'apellido': apellidoLimpio,
          'cedula': cedulaLimpia,
          'carnet': carnetLimpio,
          'rol': RolesUsuario.estudiante,
          'estadoActivo': true,
          'fechaRegistro': FieldValue.serverTimestamp(),
        })
        ..set(_carnets.doc(carnetLimpio), {'uid': user.uid, 'email': correo})
        ..set(_cedulas.doc(cedulaLimpia), {'uid': user.uid});
      await lote.commit();
      await user.updateDisplayName('$nombreLimpio $apellidoLimpio');
    } on FirebaseException catch (e) {
      await user.delete();
      if (e.code == 'permission-denied') {
        // Las reglas rechazan el lote si el carnet o la cédula ya existen.
        throw FirebaseAuthException(
          code: 'datos-duplicados',
          message: 'El carnet o la cédula ya están registrados.',
        );
      }
      rethrow;
    } catch (e) {
      await user.delete();
      rethrow;
    }

    return SesionUsuario(
      uid: user.uid,
      email: correo,
      nombre: '$nombreLimpio $apellidoLimpio',
      rol: RolesUsuario.estudiante,
    );
  }

  // ---------------------------------------------------------- inicio de sesión

  /// Inicia sesión con correo o carnet y contraseña en Firebase
  /// Authentication.
  Future<UserCredential> loginUser({
    required String accountIdentifier,
    required String password,
  }) async {
    final identificador = accountIdentifier.trim();
    final emailToUse = RegExp(r'^[0-9]+$').hasMatch(identificador)
        ? await _correoDelCarnet(identificador)
        : identificador.toLowerCase();

    return _auth.signInWithEmailAndPassword(
      email: emailToUse,
      password: password,
    );
  }

  /// Busca el correo asociado a un carnet en el índice `carnets`.
  Future<String> _correoDelCarnet(String carnet) async {
    final indice = await _carnets.doc(carnet).get();
    final correo = (indice.data()?['email'] ?? '').toString();
    if (correo.isNotEmpty) return correo;
    throw FirebaseAuthException(
      code: 'user-not-found',
      message: 'No encontramos ese carnet. Inicia sesión con tu correo.',
    );
  }

  /// Valida las credenciales y devuelve la sesión con el rol guardado en la
  /// base de datos.
  ///
  /// Si se indica [rolEsperado] (la opción elegida en el login) y la cuenta
  /// tiene otro rol, se cierra la sesión y se lanza `rol-incorrecto`. Así
  /// solo entra al panel de administración quien tiene `rol: "admin"`.
  Future<SesionUsuario> iniciarSesion({
    required String identificador,
    required String password,
    String? rolEsperado,
  }) async {
    final credential = await loginUser(
      accountIdentifier: identificador,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No se pudo iniciar sesión.',
      );
    }
    final sesion = await obtenerSesion(user);

    if (rolEsperado != null && sesion.rol != rolEsperado) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'rol-incorrecto',
        message: rolEsperado == RolesUsuario.admin
            ? 'Esta cuenta no tiene permisos de administrador.'
            : 'Esta cuenta está registrada como '
                  '${RolesUsuario.nombreVisible(sesion.rol)}. Elige esa '
                  'opción para entrar.',
      );
    }
    return sesion;
  }

  /// Lee el perfil `users/{uid}` y arma la sesión. Si el perfil no existe,
  /// el usuario se trata como estudiante.
  Future<SesionUsuario> obtenerSesion(User user) async {
    final doc = await _users.doc(user.uid).get();
    final datos = doc.data() ?? const <String, dynamic>{};
    final email = (datos['email'] ?? user.email ?? '').toString();
    unawaited(_completarIndiceDeCarnet(user.uid, datos));
    return SesionUsuario(
      uid: user.uid,
      email: email,
      nombre: _nombreVisible(datos, email),
      rol: RolesUsuario.desdeTexto(datos['rol']),
    );
  }

  /// Las cuentas creadas antes del índice `carnets` lo reciben al entrar,
  /// para que también puedan iniciar sesión con el carnet.
  Future<void> _completarIndiceDeCarnet(
    String uid,
    Map<String, dynamic> datos,
  ) async {
    final carnet = (datos['carnet'] ?? '').toString().trim();
    final email = (datos['email'] ?? '').toString().trim();
    if (AppValidators.validateCarnet(carnet) != null || email.isEmpty) return;
    try {
      final indice = _carnets.doc(carnet);
      if (!(await indice.get()).exists) {
        await indice.set({'uid': uid, 'email': email});
      }
    } catch (_) {
      // No es crítico: el usuario puede seguir entrando con su correo.
    }
  }

  /// Sesión abierta actualmente (por ejemplo, al recargar la página), o
  /// `null` si nadie ha iniciado sesión. En la web espera a que Firebase
  /// recupere la sesión guardada antes de responder.
  Future<SesionUsuario?> sesionActual() async {
    var user = _auth.currentUser;
    user ??= await _auth
        .authStateChanges()
        .first
        .timeout(const Duration(seconds: 5), onTimeout: () => null);
    if (user == null) return null;
    return obtenerSesion(user);
  }

  /// Cierra la sesión actual.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ------------------------------------------------ panel del administrador

  /// Nombre de la app secundaria de Firebase con la que el admin crea
  /// cuentas. Así la cuenta nueva no reemplaza la sesión del admin.
  static const String _appRegistro = 'registro-entrenadores';

  /// Lanza una excepción si quien tiene la sesión abierta no es admin.
  Future<User> _verificarAdmin() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-autorizado',
        message: 'Tu sesión expiró. Vuelve a iniciar sesión.',
      );
    }
    final doc = await _users.doc(user.uid).get();
    if (RolesUsuario.desdeTexto(doc.data()?['rol']) != RolesUsuario.admin) {
      throw FirebaseAuthException(
        code: 'no-autorizado',
        message: 'Solo un administrador puede registrar entrenadores.',
      );
    }
    return user;
  }

  Future<FirebaseAuth> _authSecundario() async {
    FirebaseApp app;
    try {
      app = Firebase.app(_appRegistro);
    } catch (_) {
      app = await Firebase.initializeApp(
        name: _appRegistro,
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    return FirebaseAuth.instanceFor(app: app);
  }

  /// Registra un entrenador. Solo lo puede hacer un admin con sesión abierta.
  ///
  /// La cuenta se crea con una instancia secundaria de Firebase Auth para no
  /// cerrar la sesión del admin. El perfil se guarda en `users/{uid}` con
  /// `rol: "entrenador"` y, si se indica [deporteId], el entrenador queda
  /// asignado a esa disciplina (`sports/{deporteId}.entrenadorId`).
  /// Devuelve el uid del entrenador nuevo.
  Future<String> registrarEntrenador({
    required String email,
    required String nombre,
    required String apellido,
    required String password,
    String cedula = '',
    String telefono = '',
    String? deporteId,
  }) async {
    final error = AppValidators.validateNombre(nombre) ??
        AppValidators.validateApellido(apellido) ??
        AppValidators.validateEmail(email) ??
        (cedula.trim().isEmpty ? null : AppValidators.validateCedula(cedula)) ??
        AppValidators.validatePassword(password);
    if (error != null) {
      throw FirebaseAuthException(code: 'datos-invalidos', message: error);
    }

    final admin = await _verificarAdmin();
    final correo = email.trim().toLowerCase();

    final authRegistro = await _authSecundario();
    final credential = await authRegistro.createUserWithEmailAndPassword(
      email: correo,
      password: password,
    );
    final entrenador = credential.user;
    if (entrenador == null) {
      throw FirebaseAuthException(
        code: 'user-not-created',
        message: 'No se pudo crear la cuenta. Intenta de nuevo.',
      );
    }

    try {
      await _users.doc(entrenador.uid).set({
        'uid': entrenador.uid,
        'email': correo,
        'nombre': AppValidators.limpiarNombre(nombre),
        'apellido': AppValidators.limpiarNombre(apellido),
        'cedula': cedula.trim().isEmpty
            ? ''
            : AppValidators.normalizarCedula(cedula),
        'telefono': telefono.trim(),
        'rol': RolesUsuario.entrenador,
        'estadoActivo': true,
        'creadoPor': admin.uid,
        'fechaRegistro': FieldValue.serverTimestamp(),
      });
      if (deporteId != null && deporteId.isNotEmpty) {
        await _firestore
            .collection('sports')
            .doc(deporteId)
            .update({'entrenadorId': entrenador.uid});
      }
    } catch (e) {
      await entrenador.delete();
      rethrow;
    } finally {
      await authRegistro.signOut();
    }
    return entrenador.uid;
  }

  static String _nombreVisible(Map<String, dynamic> datos, String email) {
    final nombre = (datos['nombre'] ?? '').toString().trim();
    final apellido = (datos['apellido'] ?? '').toString().trim();
    final completo = [nombre, apellido].where((p) => p.isNotEmpty).join(' ');
    if (completo.isNotEmpty) return completo;
    final username = (datos['username'] ?? '').toString().trim();
    if (username.isNotEmpty) return username;
    return email.contains('@') ? email.split('@').first : 'Usuario';
  }
}
