import 'package:cloud_firestore/cloud_firestore.dart';

import 'conversores.dart';

/// Roles posibles de un usuario en Samán Deportivo.
enum RolUsuario { estudiante, entrenador, admin }

/// Convierte el texto guardado en Firestore (`estudiante`, `entrenador`,
/// `admin`) en un [RolUsuario]. Si no se reconoce, se asume `estudiante`.
RolUsuario rolDesdeTexto(String? valor) {
  switch (valor?.trim().toLowerCase()) {
    case 'entrenador':
      return RolUsuario.entrenador;
    case 'admin':
    case 'administrador':
      return RolUsuario.admin;
    default:
      return RolUsuario.estudiante;
  }
}

/// Modelo de un documento de la colección `users` de Cloud Firestore.
///
/// Campos según el documento del Hito 2: email, nombre, apellido, rol,
/// carnet, cedula, carrera, telefono, fotoUrl y estadoActivo. El id del documento
/// es el `uid` de Firebase Authentication.
class Usuario {
  const Usuario({
    required this.uid,
    required this.email,
    required this.nombre,
    required this.apellido,
    required this.rol,
    this.carnet,
    this.cedula,
    this.carrera,
    this.telefono,
    this.fotoUrl,
    this.estadoActivo = true,
  });

  final String uid;
  final String email;
  final String nombre;
  final String apellido;
  final RolUsuario rol;
  final String? carnet;
  final String? cedula;
  final String? carrera;
  final String? telefono;

  /// URL de la foto de perfil guardada en Firebase Storage.
  final String? fotoUrl;
  final bool estadoActivo;

  /// Nombre y apellido juntos, por ejemplo "Andrea Pérez".
  String get nombreCompleto => '$nombre $apellido'.trim();

  /// Iniciales para el avatar, por ejemplo "AP".
  String get iniciales {
    final partes = nombreCompleto
        .split(RegExp(r'\s+'))
        .where((parte) => parte.isNotEmpty)
        .toList();
    if (partes.isEmpty) return '?';
    final primera = partes.first[0];
    final ultima = partes.length > 1 ? partes.last[0] : '';
    return (primera + ultima).toUpperCase();
  }

  /// Patrón Factory Method: crea un [Usuario] a partir del mapa guardado en
  /// Firestore, tolerando campos faltantes o nulos.
  factory Usuario.fromJson(Map<String, dynamic> json, {required String uid}) {
    return Usuario(
      uid: uid,
      email: textoDe(json['email']),
      nombre: textoDe(json['nombre']),
      apellido: textoDe(json['apellido']),
      rol: rolDesdeTexto(textoOpcionalDe(json['rol'])),
      carnet: textoOpcionalDe(json['carnet']),
      cedula: textoOpcionalDe(json['cedula']),
      carrera: textoOpcionalDe(json['carrera']),
      telefono: textoOpcionalDe(json['telefono']),
      fotoUrl: textoOpcionalDe(json['fotoUrl']),
      estadoActivo: booleanoDe(json['estadoActivo'], porDefecto: true),
    );
  }

  /// Crea un [Usuario] directamente desde un documento de Firestore.
  factory Usuario.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Usuario.fromJson(doc.data() ?? const {}, uid: doc.id);
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'nombre': nombre,
        'apellido': apellido,
        'rol': rol.name,
        'carnet': carnet,
        'cedula': cedula,
        'carrera': carrera,
        'telefono': telefono,
        'fotoUrl': fotoUrl,
        'estadoActivo': estadoActivo,
      };

  /// Copia del usuario con algunos campos cambiados.
  Usuario copiarCon({String? nombre, String? apellido, String? fotoUrl}) {
    return Usuario(
      uid: uid,
      email: email,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      rol: rol,
      carnet: carnet,
      cedula: cedula,
      carrera: carrera,
      telefono: telefono,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      estadoActivo: estadoActivo,
    );
  }
}
