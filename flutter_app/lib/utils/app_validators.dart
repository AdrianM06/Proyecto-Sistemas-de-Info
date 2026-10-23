class AppValidators {
  // Disallows emojis across Unicode blocks
  static final RegExp _emojiRegex = RegExp(
    r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
    unicode: true,
  );

  // Strictly alphanumeric + underscores (no special characters or spaces)
  static final RegExp _alphanumericRegex = RegExp(r'^[a-zA-Z0-9_]+$');

  // UNIMET email domain validation (@unimet.edu.ve and @correo.unimet.edu.ve)
  static final RegExp _unimetEmailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@(correo\.)?unimet\.edu\.ve$',
  );

  // Numeric only for Carnet Universitario
  static final RegExp _numericRegex = RegExp(r'^[0-9]+$');

  /// Validates Carnet Universitario
  static String? validateCarnet(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El carnet es obligatorio';
    }
    final trimmed = value.trim();
    if (_emojiRegex.hasMatch(trimmed)) {
      return 'El carnet no puede contener emojis';
    }
    if (!_numericRegex.hasMatch(trimmed)) {
      return 'El carnet solo debe contener números';
    }
    if (trimmed.length < 5 || trimmed.length > 12) {
      return 'El carnet debe tener entre 5 y 12 dígitos';
    }
    return null;
  }

  /// Validates UNIMET institutional email
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo es obligatorio';
    }
    final trimmed = value.trim().toLowerCase();
    if (_emojiRegex.hasMatch(trimmed)) {
      return 'El correo no puede contener emojis';
    }
    if (!_unimetEmailRegex.hasMatch(trimmed)) {
      return 'Debe ser un correo institucional (@unimet.edu.ve o @correo.unimet.edu.ve)';
    }
    return null;
  }

  /// Validates generic Username (if used instead of Carnet/Email)
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

  /// Validates Password strength & disallows emojis / illegal control chars
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
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Debe incluir al menos una letra mayúscula';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Debe incluir al menos un número';
    }
    return null;
  }
}