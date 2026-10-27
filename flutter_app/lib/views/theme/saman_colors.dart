import 'package:flutter/material.dart';

/// Paleta de la marca Samán Deportivo (manual de marca del Hito 1).
class SamanColors {
  SamanColors._();

  static const azul = Color(0xFF12306B); // Azul Metropolitano · primario
  static const azulNoche = Color(0xFF0B1B3F); // Texto y fondos oscuros
  static const naranja = Color(0xFFF28C1B); // Naranja Unimet · acento
  static const verde = Color(0xFF2E9D5B); // Verde Samán · secundario
  static const niebla = Color(0xFFF5F7FB); // Fondo de la app

  static const azul50 = Color(0xFFEEF2FA);
  static const azul100 = Color(0xFFD6E0F2);
  static const azul200 = Color(0xFFADC1E5);
  static const naranja50 = Color(0xFFFFF5EA);
  static const naranja700 = Color(0xFFB35D05);
  static const verde50 = Color(0xFFEAF7EF);
  static const verde700 = Color(0xFF1B6A3B);

  static const neutro200 = Color(0xFFE1E6EF);
  static const neutro500 = Color(0xFF5E6B84);
  static const neutro900 = Color(0xFF111827);

  static const error = Color(0xFFC73E3E);
  static const errorFondo = Color(0xFFFDECEC);

  /// Tema base de la app con la paleta de la marca.
  static ThemeData tema() {
    final esquema = ColorScheme.fromSeed(
      seedColor: azul,
      primary: azul,
      secondary: verde,
      tertiary: naranja,
      error: error,
      surface: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: niebla,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: azulNoche,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: neutro200),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neutro200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neutro200),
        ),
      ),
    );
  }
}
