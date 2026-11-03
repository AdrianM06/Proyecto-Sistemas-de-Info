import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'firestore_service.dart';

/// Error al subir la foto, con un mensaje listo para mostrar.
class FotoPerfilException implements Exception {
  const FotoPerfilException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Patrón Singleton: sube la foto de perfil a Firebase Storage y guarda su
/// URL en `users/{uid}.fotoUrl`.
///
/// Las fotos viven en `usuarios/{uid}/perfil_<fecha>.<ext>`. Cada subida
/// usa un nombre nuevo (así el navegador no muestra la foto vieja guardada
/// en caché) y luego borra la anterior. `storage.rules` solo deja que cada
/// usuario escriba en su propia carpeta, imágenes de hasta 2 MB.
class FotoPerfilService {
  FotoPerfilService._();
  static final FotoPerfilService instance = FotoPerfilService._();

  /// Tamaño máximo de la foto (igual que en `storage.rules`).
  static const int tamanoMaximo = 2 * 1024 * 1024;

  static const Map<String, String> _extensiones = {
    'image/jpeg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp',
  };

  /// Tipo MIME a partir del nombre del archivo, por si el selector de
  /// imágenes no lo informa.
  static String tipoDesdeNombre(String nombre) {
    final texto = nombre.toLowerCase();
    if (texto.endsWith('.png')) return 'image/png';
    if (texto.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  /// Revisa la imagen antes de subirla. Devuelve el error o `null`.
  static String? validar(Uint8List bytes, String tipo) {
    if (bytes.isEmpty) return 'La imagen está vacía.';
    if (bytes.length > tamanoMaximo) return 'La imagen pesa más de 2 MB.';
    if (!_extensiones.containsKey(tipo)) {
      return 'Usa una imagen JPG, PNG o WEBP.';
    }
    return null;
  }

  /// Sube la foto del usuario y devuelve su URL de descarga.
  Future<String> subir({
    required String uid,
    required Uint8List bytes,
    required String tipo,
  }) async {
    final error = validar(bytes, tipo);
    if (error != null) throw FotoPerfilException(error);

    final usuario = FirestoreService.instance.users.doc(uid);
    final anterior = (await usuario.get()).data()?['fotoUrl'];

    final nombre =
        'perfil_${DateTime.now().millisecondsSinceEpoch}.${_extensiones[tipo]}';
    final referencia = FirebaseStorage.instance.ref('usuarios/$uid/$nombre');
    try {
      await referencia.putData(
        bytes,
        SettableMetadata(contentType: tipo, cacheControl: 'public,max-age=86400'),
      );
    } on FirebaseException catch (e) {
      throw FotoPerfilException(
        e.code == 'unauthorized'
            ? 'No tienes permiso para cambiar esta foto.'
            : 'No se pudo subir la foto. Revisa tu conexión e intenta de nuevo.',
      );
    }
    final url = await referencia.getDownloadURL();

    await usuario.update({
      'fotoUrl': url,
      'fotoActualizada': FieldValue.serverTimestamp(),
    });

    if (anterior is String && anterior.isNotEmpty) {
      try {
        await FirebaseStorage.instance.refFromURL(anterior).delete();
      } catch (_) {
        // Si la foto vieja ya no existe, no pasa nada.
      }
    }
    return url;
  }
}
