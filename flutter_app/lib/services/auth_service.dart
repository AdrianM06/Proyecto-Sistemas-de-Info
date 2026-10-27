import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Roles que puede tener una cuenta (campo `rol` de la colección `users`).
class RolesUsuario {
  RolesUsuario._();

  static const String estudiante = 'estudiante';
  static const String entrenador = 'entrenador';

  /// Normaliza el texto guardado en Firestore. Cualquier valor desconocido
  /// se toma como estudiante.
  static String desdeTexto(Object? valor) {
    final texto = (valor ?? '').toString().trim().toLowerCase();
    return texto == entrenador ? entrenador : estudiante;
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

  /// `RolesUsuario.estudiante` o `RolesUsuario.entrenador`.
  final String rol;

  bool get esEntrenador => rol == RolesUsuario.entrenador;
  bool get esEstudiante => rol == RolesUsuario.estudiante;
}

/// Patrón Singleton: único punto de acceso a Firebase Authentication y al
/// perfil de los usuarios en Firestore (colección `users`).
class AuthService {
  AuthService._privateConstructor();
  static final AuthService instance = AuthService._privateConstructor();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// Usuario de Firebase Authentication con la sesión abierta, si hay uno.
  User? get usuarioActual => _auth.currentUser;

  /// Crea la cuenta en Firebase Authentication y guarda su perfil con el
  /// [rol] indicado (`estudiante` o `entrenador`) en `users/{uid}`.
  ///
  /// Si el carnet ya está registrado lanza una [FirebaseAuthException] con
  /// el código `carnet-already-in-use`. Si falla el guardado del perfil, se
  /// borra la cuenta recién creada para no dejar usuarios sin rol.
  Future<SesionUsuario> registerUser({
    required String email,
    required String username,
    required String carnet,
    required String password,
    required String rol,
  }) async {
    final correo = email.trim().toLowerCase();
    final carnetLimpio = carnet.trim();
    final rolLimpio = RolesUsuario.desdeTexto(rol);

    final carnetExistente = await _users
        .where('carnet', isEqualTo: carnetLimpio)
        .limit(1)
        .get();
    if (carnetExistente.docs.isNotEmpty) {
      throw FirebaseAuthException(
        code: 'carnet-already-in-use',
        message: 'Ese carnet ya está registrado.',
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
      await _users.doc(user.uid).set({
        'uid': user.uid,
        'email': correo,
        'username': username.trim(),
        'nombre': username.trim(),
        'apellido': '',
        'carnet': carnetLimpio,
        'rol': rolLimpio,
        'estadoActivo': true,
        'fechaRegistro': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      await user.delete();
      rethrow;
    }

    return SesionUsuario(
      uid: user.uid,
      email: correo,
      nombre: username.trim(),
      rol: rolLimpio,
    );
  }

  /// Registro de estudiantes (se mantiene por compatibilidad con el código
  /// que ya lo usaba).
  Future<SesionUsuario> registerStudent({
    required String email,
    required String username,
    required String carnet,
    required String password,
  }) {
    return registerUser(
      email: email,
      username: username,
      carnet: carnet,
      password: password,
      rol: RolesUsuario.estudiante,
    );
  }

  /// Inicia sesión con correo o carnet y contraseña en Firebase
  /// Authentication.
  Future<UserCredential> loginUser({
    required String accountIdentifier,
    required String password,
  }) async {
    String emailToUse = accountIdentifier.trim();

    // Si el identificador es numérico (carnet), se busca su correo en Firestore.
    if (RegExp(r'^[0-9]+$').hasMatch(emailToUse)) {
      final query = await _users
          .where('carnet', isEqualTo: emailToUse)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No se encontró ningún usuario con ese carnet.',
        );
      }
      emailToUse = (query.docs.first.data()['email'] ?? '').toString();
    }

    return _auth.signInWithEmailAndPassword(
      email: emailToUse,
      password: password,
    );
  }

  /// Valida las credenciales y devuelve la sesión con el rol guardado en
  /// la base de datos.
  Future<SesionUsuario> iniciarSesion({
    required String identificador,
    required String password,
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
    return obtenerSesion(user);
  }

  /// Lee el perfil `users/{uid}` y arma la sesión. Si el perfil no existe,
  /// el usuario se trata como estudiante.
  Future<SesionUsuario> obtenerSesion(User user) async {
    final doc = await _users.doc(user.uid).get();
    final datos = doc.data() ?? const <String, dynamic>{};
    final email = (datos['email'] ?? user.email ?? '').toString();
    return SesionUsuario(
      uid: user.uid,
      email: email,
      nombre: _nombreVisible(datos, email),
      rol: RolesUsuario.desdeTexto(datos['rol']),
    );
  }

  /// Sesión abierta actualmente (por ejemplo, al recargar la página), o
  /// `null` si nadie ha iniciado sesión.
  Future<SesionUsuario?> sesionActual() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return obtenerSesion(user);
  }

  /// Cierra la sesión actual.
  Future<void> signOut() async {
    await _auth.signOut();
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
