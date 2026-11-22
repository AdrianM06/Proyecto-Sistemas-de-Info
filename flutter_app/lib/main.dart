import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'navigation/app_routes.dart';
import 'views/theme/saman_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('No se pudo inicializar Firebase: $e');
  }
  runApp(const UnimetSportsApp());
}

class UnimetSportsApp extends StatelessWidget {
  const UnimetSportsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final temaBase = SamanColors.tema();
    return MaterialApp(
      title: 'UNIMET Sports',
      debugShowCheckedModeBanner: false,
      theme: temaBase.copyWith(
        textTheme: temaBase.textTheme.apply(fontFamily: 'Roboto'),
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            for (final plataforma in TargetPlatform.values)
              plataforma: const _TransicionFundido(),
          },
        ),
      ),
      initialRoute: AppRoutes.landing,
      onGenerateRoute: AppRoutes.generarRuta,
    );
  }
}

class _TransicionFundido extends PageTransitionsBuilder {
  const _TransicionFundido();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    );
  }
}