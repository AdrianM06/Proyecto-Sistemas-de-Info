import 'package:flutter_app/utils/app_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('correo estudiantil (registro)', () {
    test('acepta solo @correo.unimet.edu.ve', () {
      expect(
        AppValidators.validateEmailEstudiante('ana.perez@correo.unimet.edu.ve'),
        isNull,
      );
      expect(
        AppValidators.validateEmailEstudiante('  Ana.Perez@CORREO.unimet.edu.ve '),
        isNull,
      );
    });

    test('rechaza otros dominios', () {
      for (final correo in [
        'ana@gmail.com',
        'ana@unimet.edu.ve',
        'ana@correo.unimet.edu.ve.com',
        'ana@correo-unimet.edu.ve',
        'correo.unimet.edu.ve',
      ]) {
        expect(
          AppValidators.validateEmailEstudiante(correo),
          'Usa tu correo estudiantil (@correo.unimet.edu.ve)',
          reason: correo,
        );
      }
    });

    test('es obligatorio y no admite espacios', () {
      expect(AppValidators.validateEmailEstudiante(''), 'El correo es obligatorio');
      expect(AppValidators.validateEmailEstudiante(null), 'El correo es obligatorio');
      expect(
        AppValidators.validateEmailEstudiante('ana perez@correo.unimet.edu.ve'),
        'El correo no puede tener espacios ni emojis',
      );
    });

    test('el login acepta también el correo del personal', () {
      expect(AppValidators.validateEmail('prof@unimet.edu.ve'), isNull);
      expect(AppValidators.validateEmail('ana@correo.unimet.edu.ve'), isNull);
      expect(AppValidators.validateEmail('ana@gmail.com'), isNotNull);
    });
  });

  group('carnet universitario', () {
    final hoy = DateTime(2026, 11, 3);

    test('acepta 11 dígitos que empiezan por el año de ingreso', () {
      expect(AppValidators.validateCarnet('20221110045', hoy: hoy), isNull);
      expect(AppValidators.validateCarnet(' 20261110001 ', hoy: hoy), isNull);
    });

    test('rechaza formatos incorrectos', () {
      expect(AppValidators.validateCarnet('', hoy: hoy), 'El carnet es obligatorio');
      expect(
        AppValidators.validateCarnet('2022A110045', hoy: hoy),
        'El carnet solo debe contener números',
      );
      expect(
        AppValidators.validateCarnet('2022111004', hoy: hoy),
        'El carnet debe tener 11 dígitos',
      );
      expect(
        AppValidators.validateCarnet('202211100451', hoy: hoy),
        'El carnet debe tener 11 dígitos',
      );
      expect(
        AppValidators.validateCarnet('19981110045', hoy: hoy),
        'El carnet debe empezar por el año de ingreso (20XX)',
      );
      expect(
        AppValidators.validateCarnet('20991110045', hoy: hoy),
        'El año de ingreso del carnet (2099) no es válido',
      );
    });
  });

  group('cédula', () {
    test('acepta los formatos comunes y los normaliza', () {
      for (final cedula in ['27123456', 'V27123456', 'V-27123456', 'v-27.123.456']) {
        expect(AppValidators.validateCedula(cedula), isNull, reason: cedula);
        expect(AppValidators.normalizarCedula(cedula), 'V-27123456');
      }
      expect(AppValidators.normalizarCedula('E-81234567'), 'E-81234567');
    });

    test('rechaza cédulas inválidas', () {
      expect(AppValidators.validateCedula(''), 'La cédula es obligatoria');
      for (final cedula in ['12345', 'X-12345678', '1234567890', 'V-12a45678', '000123']) {
        expect(AppValidators.validateCedula(cedula), isNotNull, reason: cedula);
        expect(AppValidators.normalizarCedula(cedula), isNull, reason: cedula);
      }
    });
  });

  group('nombre y apellido', () {
    test('aceptan letras con acentos, espacios y guiones', () {
      expect(AppValidators.validateNombre('María José'), isNull);
      expect(AppValidators.validateApellido("D'Agostino-Núñez"), isNull);
    });

    test('rechazan vacíos, números y textos muy largos', () {
      expect(AppValidators.validateNombre('  '), 'El nombre es obligatorio');
      expect(AppValidators.validateNombre('A'), 'El nombre debe tener al menos 2 letras');
      expect(AppValidators.validateApellido('P3rez'), 'El apellido solo puede tener letras');
      expect(
        AppValidators.validateNombre('A' * 41),
        'El nombre no puede pasar de 40 caracteres',
      );
    });

    test('limpiarNombre deja espacios simples', () {
      expect(AppValidators.limpiarNombre('  ana   maría '), 'ana maría');
    });
  });

  group('contraseña', () {
    test('exige 8 caracteres, una mayúscula y un número', () {
      expect(AppValidators.validatePassword('Clave1234'), isNull);
      expect(AppValidators.validatePassword(''), 'La contraseña es obligatoria');
      expect(
        AppValidators.validatePassword('Cl1'),
        'La contraseña debe tener al menos 8 caracteres',
      );
      expect(
        AppValidators.validatePassword('clave1234'),
        'Debe incluir al menos una letra mayúscula',
      );
      expect(
        AppValidators.validatePassword('ClaveSegura'),
        'Debe incluir al menos un número',
      );
    });

    test('la confirmación debe coincidir', () {
      expect(AppValidators.validateConfirmacion('Clave1234', 'Clave1234'), isNull);
      expect(
        AppValidators.validateConfirmacion('Clave12345', 'Clave1234'),
        'Las contraseñas no coinciden',
      );
      expect(AppValidators.validateConfirmacion('', 'Clave1234'), 'Repite la contraseña');
    });
  });

  group('identificador del login', () {
    test('acepta correo Unimet o carnet', () {
      expect(AppValidators.validateIdentificadorLogin('ana@correo.unimet.edu.ve'), isNull);
      expect(AppValidators.validateIdentificadorLogin('20221110045'), isNull);
    });

    test('rechaza vacíos y formatos incorrectos', () {
      expect(
        AppValidators.validateIdentificadorLogin(''),
        'Escribe tu correo o tu carnet',
      );
      expect(AppValidators.validateIdentificadorLogin('123'), isNotNull);
      expect(AppValidators.validateIdentificadorLogin('ana@gmail.com'), isNotNull);
    });
  });

  test('validarRegistroEstudiante devuelve el primer error o null', () {
    String? validar({
      String nombre = 'Ana',
      String apellido = 'Pérez',
      String email = 'ana@correo.unimet.edu.ve',
      String cedula = 'V-27123456',
      String carnet = '20221110045',
      String password = 'Clave1234',
    }) {
      return AppValidators.validarRegistroEstudiante(
        nombre: nombre,
        apellido: apellido,
        email: email,
        cedula: cedula,
        carnet: carnet,
        password: password,
      );
    }

    expect(validar(), isNull);
    expect(validar(nombre: ''), 'El nombre es obligatorio');
    expect(validar(apellido: ''), 'El apellido es obligatorio');
    expect(validar(email: 'ana@gmail.com'), contains('@correo.unimet.edu.ve'));
    expect(validar(cedula: ''), 'La cédula es obligatoria');
    expect(validar(carnet: '123'), 'El carnet debe tener 11 dígitos');
    expect(validar(password: 'corta'), isNotNull);
  });
}
