import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Configuración de Firebase del proyecto `bdd-saman-deportivo`.
///
/// Son los datos públicos de la app web registrada en la consola de
/// Firebase (Configuración del proyecto → Tus apps → mi-app-web). No son
/// secretos: el acceso a los datos lo controlan las reglas de Firestore.
///
/// Para otras plataformas (Android, iOS, Windows) hay que registrarlas en la
/// consola y regenerar este archivo con `flutterfire configure`.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError(
      'Firebase solo está configurado para la versión web. '
      'Ejecuta "flutterfire configure" para agregar otras plataformas.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBo3e_eiv9tMzm178i3FOPR6XKB5DapFa4',
    appId: '1:985925687251:web:b0c8bb8c33de2d50c48126',
    messagingSenderId: '985925687251',
    projectId: 'bdd-saman-deportivo',
    authDomain: 'bdd-saman-deportivo.firebaseapp.com',
    databaseURL: 'https://bdd-saman-deportivo-default-rtdb.firebaseio.com',
    storageBucket: 'bdd-saman-deportivo.firebasestorage.app',
    measurementId: 'G-5KPLW65S2Q',
  );
}
