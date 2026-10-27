import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/models/asistencia.dart';
import 'package:flutter_app/models/deporte.dart';
import 'package:flutter_app/models/inscripcion.dart';
import 'package:flutter_app/models/usuario.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pruebas del patrón Factory Method: los modelos deben construirse bien
/// aunque a los documentos de Firestore les falten campos o traigan tipos
/// distintos.
void main() {
  group('Deporte.fromJson', () {
    test('lee todos los campos del documento', () {
      final deporte = Deporte.fromJson({
        'nombre': 'Fútbol Masculino',
        'disciplina': 'Fútbol',
        'cupos': 25,
        'entrenadorId': 'ent-1',
        'horarios': ['Lun 4:00–6:00 pm', 'Mié 4:00–6:00 pm'],
        'lugar': 'Cancha principal',
      }, id: 'FUT-M01');

      expect(deporte.id, 'FUT-M01');
      expect(deporte.cupos, 25);
      expect(deporte.horarios, hasLength(2));
      expect(deporte.horariosTexto, 'Lun 4:00–6:00 pm · Mié 4:00–6:00 pm');
    });

    test('tolera campos faltantes, nulos o con otro tipo', () {
      final deporte = Deporte.fromJson({'cupos': '18', 'horarios': null}, id: 'X');

      expect(deporte.nombre, 'Sin nombre');
      expect(deporte.cupos, 18);
      expect(deporte.horarios, isEmpty);
      expect(deporte.horariosTexto, 'Horario por definir');
    });

    test('acepta horarios guardados como mapas', () {
      final deporte = Deporte.fromJson({
        'horarios': [
          {'dia': 'Sáb', 'horaInicio': '9:00', 'horaFin': '11:00'},
        ],
      }, id: 'FSA-01');

      expect(deporte.horarios.single, 'Sáb 9:00–11:00');
    });
  });

  group('Usuario.fromJson', () {
    test('lee el rol y arma el nombre completo y las iniciales', () {
      final usuario = Usuario.fromJson({
        'nombre': 'Andrea',
        'apellido': 'Pérez',
        'rol': 'entrenador',
        'carnet': 20221110342,
      }, uid: 'u1');

      expect(usuario.rol, RolUsuario.entrenador);
      expect(usuario.nombreCompleto, 'Andrea Pérez');
      expect(usuario.iniciales, 'AP');
      expect(usuario.carnet, '20221110342');
      expect(usuario.estadoActivo, isTrue);
    });

    test('un rol desconocido se toma como estudiante', () {
      expect(Usuario.fromJson({'rol': 'otro'}, uid: 'u2').rol, RolUsuario.estudiante);
    });
  });

  group('Inscripcion.fromJson', () {
    test('reconoce inscripciones activas y retiradas', () {
      final activa = Inscripcion.fromJson({'estado': 'activa'}, id: 'i1');
      final retirada = Inscripcion.fromJson({'estado': 'Retirada'}, id: 'i2');

      expect(activa.estaActiva, isTrue);
      expect(retirada.estaActiva, isFalse);
    });
  });

  group('Asistencia', () {
    test('el id combina el deporte y la fecha sin hora', () {
      expect(
        Asistencia.idPara('FUT-M01', DateTime(2026, 10, 21, 16, 30)),
        'FUT-M01_2026-10-21',
      );
    });

    test('ida y vuelta con Firestore conserva los datos', () {
      final original = Asistencia(
        deporteId: 'FUT-M01',
        fecha: DateTime(2026, 10, 21, 18),
        entrenadorId: 'ent-1',
        presentes: ['est-01', 'est-02'],
      );
      final json = original.toJson();
      expect(json['fecha'], isA<Timestamp>());

      final copia = Asistencia.fromJson(json, id: original.id);
      expect(copia.fecha, DateTime(2026, 10, 21));
      expect(copia.presentes, ['est-01', 'est-02']);
      expect(copia.estaPresente('est-02'), isTrue);
      expect(copia.estaPresente('est-03'), isFalse);
    });
  });
}
