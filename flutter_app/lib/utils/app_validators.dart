/// Validaciones de los formularios de Samán Deportivo.
///
/// Todas devuelven `null` si el valor es válido o el mensaje de error que se
/// muestra debajo del campo. El registro las vuelve a aplicar en
/// `AuthService` antes de escribir en Firebase, y las reglas de Firestore
/// (`firestore.rules`) repiten las mismas condiciones del lado del servidor.
class AppValidators {
  AppValidators._();

  // Bloques Unicode de emojis.
  static final RegExp _emojiRegex = RegExp(
    r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
    unicode: true,
  );

  // Letras, números y guiones bajos.
  static final RegExp _alphanumericRegex = RegExp(r'^[a-zA-Z0-9_]+$');

  /// Correos de la Unimet (estudiantes y personal).
  static final RegExp _unimetEmailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@(correo\.)?unimet\.edu\.ve$',
  );

  /// Correo estudiantil de la Unimet: el único permitido en el registro.
  static final RegExp _correoEstudianteRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@correo\.unimet\.edu\.ve$',
  );

  static final RegExp _numericRegex = RegExp(r'^[0-9]+$');

  /// Carnet Unimet: 11 dígitos que empiezan por el año de ingreso (20XX).
  static final RegExp _carnetRegex = RegExp(r'^20[0-9]{9}$');

  /// Nombre o apellido: letras (con acentos), espacios, apóstrofo y guion.
  static final RegExp _nombreRegex = RegExp(r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ' -]+$");

  /// Cédula venezolana: V o E opcional, guion opcional y 6 a 9 dígitos.
  static final RegExp _cedulaRegex = RegExp(r'^([VE])?-?([0-9]{6,9})$');

  /// Dominio que se exige en el registro de estudiantes.
  static const String dominioEstudiantes = '@correo.unimet.edu.ve';

  /// Primer año de ingreso aceptado en el carnet.
  static const int primerAnioCarnet = 2000;

  // ------------------------------------------------------------- carnet

  /// Carnet universitario: exactamente 11 dígitos, empieza por un año de
  /// ingreso válido (por ejemplo 20221110045).
  static String? validateCarnet(String? value, {DateTime? hoy}) {
    if (value == null || value.trim().isEmpty) {
      return 'El carnet es obligatorio';
    }
    final carnet = value.trim();
    if (_emojiRegex.hasMatch(carnet)) {
      return 'El carnet no puede contener emojis';
    }
    if (!_numericRegex.hasMatch(carnet)) {
      return 'El carnet solo debe contener números';
    }
    if (carnet.length != 11) {
      return 'El carnet debe tener 11 dígitos';
    }
    if (!_carnetRegex.hasMatch(carnet)) {
      return 'El carnet debe empezar por el año de ingreso (20XX)';
    }
    final anio = int.parse(carnet.substring(0, 4));
    final anioActual = (hoy ?? DateTime.now()).year;
    if (anio < primerAnioCarnet || anio > anioActual + 1) {
      return 'El año de ingreso del carnet ($anio) no es válido';
    }
    return null;
  }

  // ------------------------------------------------------------- correos

  /// Correo institucional de la Unimet (estudiantes o personal). Se usa en
  /// el login y en la recuperación de contraseña.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo es obligatorio';
    }
    final correo = value.trim().toLowerCase();
    if (_emojiRegex.hasMatch(correo)) {
      return 'El correo no puede contener emojis';
    }
    if (!_unimetEmailRegex.hasMatch(correo)) {
      return 'Debe ser un correo institucional (@unimet.edu.ve o @correo.unimet.edu.ve)';
    }
    return null;
  }

  /// Correo del registro de estudiantes: solo `@correo.unimet.edu.ve`.
  static String? validateEmailEstudiante(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo es obligatorio';
    }
    final correo = value.trim().toLowerCase();
    if (_emojiRegex.hasMatch(correo) || correo.contains(' ')) {
      return 'El correo no puede tener espacios ni emojis';
    }
    if (!_correoEstudianteRegex.hasMatch(correo)) {
      return 'Usa tu correo estudiantil ($dominioEstudiantes)';
    }
    return null;
  }

  /// Campo del login: acepta un correo Unimet o un carnet.
  static String? validateIdentificadorLogin(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Escribe tu correo o tu carnet';
    }
    final texto = value.trim();
    if (_numericRegex.hasMatch(texto)) return validateCarnet(texto);
    return validateEmail(texto);
  }

  // --------------------------------------------------- nombre y apellido

  static String? validateNombre(String? value) =>
      _validarNombrePropio(value, 'El nombre');

  static String? validateApellido(String? value) =>
      _validarNombrePropio(value, 'El apellido');

  static String? _validarNombrePropio(String? value, String campo) {
    final texto = (value ?? '').trim();
    if (texto.isEmpty) return '$campo es obligatorio';
    if (_emojiRegex.hasMatch(texto)) return '$campo no puede contener emojis';
    if (texto.length < 2) return '$campo debe tener al menos 2 letras';
    if (texto.length > 40) return '$campo no puede pasar de 40 caracteres';
    if (!_nombreRegex.hasMatch(texto)) {
      return '$campo solo puede tener letras';
    }
    return null;
  }

  // -------------------------------------------------------------- cédula

  /// Cédula venezolana: 12345678, V12345678, V-12345678 o E-12.345.678.
  static String? validateCedula(String? value) {
    final texto = _limpiarCedula(value);
    if (texto.isEmpty) return 'La cédula es obligatoria';
    final coincidencia = _cedulaRegex.firstMatch(texto);
    if (coincidencia == null) {
      return 'Escribe una cédula válida (ej. V-12345678)';
    }
    final numero = int.parse(coincidencia.group(2)!);
    if (numero < 100000) return 'Escribe una cédula válida (ej. V-12345678)';
    return null;
  }

  /// Formato con el que se guarda la cédula: `V-12345678` o `E-12345678`.
  /// Devuelve `null` si la cédula no es válida.
  static String? normalizarCedula(String? value) {
    if (validateCedula(value) != null) return null;
    final coincidencia = _cedulaRegex.firstMatch(_limpiarCedula(value))!;
    final letra = coincidencia.group(1) ?? 'V';
    final numero = int.parse(coincidencia.group(2)!);
    return '$letra-$numero';
  }

  static String _limpiarCedula(String? value) =>
      (value ?? '').trim().toUpperCase().replaceAll('.', '').replaceAll(' ', '');

  /// Deja un nombre con espacios simples: "  ana   maría " -> "ana maría".
  static String limpiarNombre(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');

  // ----------------------------------------------------------- usuario

  /// Nombre de usuario genérico (letras, números y guion bajo).
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre de usuario es obligatorio';
    }
    final trimmed = value.trim();
    if (_emojiRegex.hasMatch(trimmed)) {
      return 'No se permiten emojis';
    }
    if (!_alphanumericRegex.hasMatch(trimmed)) {
      return 'Solo se permiten letras, números y guiones bajos (_)';
    }
    if (trimmed.length < 4 || trimmed.length > 20) {
      return 'Debe tener entre 4 y 20 caracteres';
    }
    return null;
  }

  // ---------------------------------------------------------- contraseña

  /// Contraseña: mínimo 8 caracteres, una mayúscula y un número; sin emojis.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (_emojiRegex.hasMatch(value)) {
      return 'La contraseña no puede contener emojis';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    if (value.length > 64) {
      return 'La contraseña no puede pasar de 64 caracteres';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Debe incluir al menos una letra mayúscula';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Debe incluir al menos un número';
    }
    return null;
  }

  /// Confirmación de la contraseña.
  static String? validateConfirmacion(String? value, String original) {
    if (value == null || value.isEmpty) return 'Repite la contraseña';
    if (value != original) return 'Las contraseñas no coinciden';
    return null;
  }

  // ---------------------------------------------------- registro completo

  /// Revisa todos los datos del registro de un estudiante. Devuelve el
  /// primer error encontrado o `null`. `AuthService` la usa como última
  /// barrera antes de escribir en Firebase.
  static String? validarRegistroEstudiante({
    required String nombre,
    required String apellido,
    required String email,
    required String cedula,
    required String carnet,
    required String password,
  }) {
    return validateNombre(nombre) ??
        validateApellido(apellido) ??
        validateEmailEstudiante(email) ??
        validateCedula(cedula) ??
        validateCarnet(carnet) ??
        validatePassword(password);
  }
}
