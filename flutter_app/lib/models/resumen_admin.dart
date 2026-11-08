/// Cifras generales del sistema para el resumen del panel del administrador
/// (caso de uso CU14: Visualizar Dashboard).
class ResumenAdmin {
  const ResumenAdmin({
    required this.estudiantes,
    required this.estudiantesDeshabilitados,
    required this.entrenadores,
    required this.disciplinas,
    required this.disciplinasSinEntrenador,
    required this.inscripcionesActivas,
    required this.cuposTotales,
  });

  /// Cuentas con `rol: "estudiante"`.
  final int estudiantes;

  /// Estudiantes con `estadoActivo: false` (no se pueden inscribir).
  final int estudiantesDeshabilitados;

  /// Cuentas con `rol: "entrenador"`.
  final int entrenadores;

  /// Disciplinas creadas en `sports`.
  final int disciplinas;

  /// Disciplinas que todavía no tienen ningún entrenador asignado.
  final int disciplinasSinEntrenador;

  /// Inscripciones con `estado: "activa"`.
  final int inscripcionesActivas;

  /// Suma de los cupos de todas las disciplinas.
  final int cuposTotales;

  /// Estudiantes que sí pueden inscribirse.
  int get estudiantesActivos {
    final activos = estudiantes - estudiantesDeshabilitados;
    return activos < 0 ? 0 : activos;
  }

  /// Fracción de los cupos ocupados (0 a 1), o `null` si no hay cupos.
  double? get ocupacion {
    if (cuposTotales <= 0) return null;
    final fraccion = inscripcionesActivas / cuposTotales;
    return fraccion > 1 ? 1 : fraccion;
  }

  /// Ocupación como porcentaje redondeado, por ejemplo "45 %".
  String get ocupacionTexto {
    final fraccion = ocupacion;
    if (fraccion == null) return 'Sin cupos definidos';
    return '${(fraccion * 100).round()} % de $cuposTotales cupos';
  }
}
