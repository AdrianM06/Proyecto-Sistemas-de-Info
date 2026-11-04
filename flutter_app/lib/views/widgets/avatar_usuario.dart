import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';

/// Foto de perfil redonda. Si no hay foto muestra las iniciales (o un ícono).
class AvatarUsuario extends StatelessWidget {
  const AvatarUsuario({
    super.key,
    this.fotoUrl,
    this.iniciales = '',
    this.radio = 18,
  });

  final String? fotoUrl;
  final String iniciales;
  final double radio;

  @override
  Widget build(BuildContext context) {
    final url = fotoUrl ?? '';
    return CircleAvatar(
      radius: radio,
      backgroundColor: const Color(0xFFE0E0E0),
      child: url.isEmpty
          ? _iniciales()
          : ClipOval(
              // En la web la imagen se dibuja con un <img>, así no depende de
              // la configuración CORS del bucket de Storage. Debe ser un
              // widget Image: pintarla como `backgroundImage` del CircleAvatar
              // lanza un error en cada fotograma y deja la pantalla a medias.
              child: Image.network(
                url,
                width: radio * 2,
                height: radio * 2,
                fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (context, error, stackTrace) => _iniciales(),
              ),
            ),
    );
  }

  Widget _iniciales() {
    return iniciales.isEmpty
        ? Icon(Icons.person, color: Colors.grey, size: radio * 1.4)
        : Text(
            iniciales,
            style: TextStyle(
              color: const Color(0xFF003087),
              fontWeight: FontWeight.w700,
              fontSize: radio * 0.8,
            ),
          );
  }
}

/// [AvatarUsuario] que se actualiza solo cuando cambia `users/{uid}`
/// (patrón Observer con los `snapshots()` de Firestore).
class AvatarUsuarioEnVivo extends StatelessWidget {
  const AvatarUsuarioEnVivo({super.key, required this.uid, this.radio = 18});

  final String uid;
  final double radio;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirestoreService.instance.users.doc(uid).snapshots(),
      builder: (context, snapshot) {
        final datos = snapshot.data?.data() ?? const <String, dynamic>{};
        final nombre = '${datos['nombre'] ?? ''} ${datos['apellido'] ?? ''}';
        final iniciales = nombre
            .trim()
            .split(RegExp(r'\s+'))
            .where((parte) => parte.isNotEmpty)
            .take(2)
            .map((parte) => parte[0].toUpperCase())
            .join();
        return AvatarUsuario(
          fotoUrl: datos['fotoUrl']?.toString(),
          iniciales: iniciales,
          radio: radio,
        );
      },
    );
  }
}
