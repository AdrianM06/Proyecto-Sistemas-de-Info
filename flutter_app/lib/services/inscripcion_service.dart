import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/deporte.dart';
import '../models/inscripcion.dart';
import 'firestore_service.dart';

class InscripcionException implements Exception {
  const InscripcionException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

abstract class InscripcionesDataSource {
  Future<Set<String>> deportesInscritos(String estudianteId);

  Future<void> inscribir({
    required String estudianteId,
    required Deporte deporte,
  });

  Future<void> cancelar({
    required String estudianteId,
    required String deporteId,
  });
}

class InscripcionService implements InscripcionesDataSource {
  InscripcionService({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService.instance;

  final FirestoreService _firestore;

  @override
  Future<Set<String>> deportesInscritos(String estudianteId) async {
    final resultado = await _firestore.enrollments
        .where('estudianteId', isEqualTo: estudianteId)
        .get();

    return {
      for (final doc in resultado.docs)
        if (Inscripcion.fromFirestore(doc).estaActiva)
          Inscripcion.fromFirestore(doc).deporteId,
    };
  }

  @override
  Future<void> inscribir({
    required String estudianteId,
    required Deporte deporte,
  }) async {
    try {
      final userDoc = await _firestore.users.doc(estudianteId).get();
      if (!userDoc.exists) {
        throw const InscripcionException('No se encontró el registro de tu usuario.');
      }

      final userData = userDoc.data() ?? {};
      final bool estadoActivo = userData['estadoActivo'] ?? true;
      if (!estadoActivo) {
        throw const InscripcionException(
          'Tu cuenta se encuentra inactiva o suspendida. Comunícate con la coordinación deportiva.',
        );
      }

      final snapshot = await _firestore.enrollments
          .where('deporteId', isEqualTo: deporte.id)
          .get();

      final inscripcionesActivas = snapshot.docs
          .map(Inscripcion.fromFirestore)
          .where((i) => i.estaActiva)
          .toList();

      if (inscripcionesActivas.any((i) => i.estudianteId == estudianteId)) {
        throw InscripcionException('Ya estás inscrito en ${deporte.nombre}.');
      }

      if (inscripcionesActivas.length >= deporte.cupos) {
        throw InscripcionException(
          'Lo sentimos, ${deporte.nombre} ya no tiene cupos disponibles '
          '(${inscripcionesActivas.length}/${deporte.cupos}).',
        );
      }
      await _firestore.enrollments.add({
        'estudianteId': estudianteId,
        'deporteId': deporte.id,
        'estado': EstadoInscripcion.activa.name,
        'fechaInscripcion': FieldValue.serverTimestamp(),
      });
    } on InscripcionException {
      rethrow;
    } on FirebaseException catch (e) {
      throw InscripcionException(
        e.code == 'permission-denied'
            ? 'No tienes permisos para inscribirte. Vuelve a iniciar sesión.'
            : 'Error de conexión con la base de datos (${e.code}).',
      );
    } catch (e) {
      throw const InscripcionException(
        'No se pudo procesar la inscripción. Intenta nuevamente.',
      );
    }
  }

  @override
  Future<void> cancelar({
    required String estudianteId,
    required String deporteId,
  }) async {
    try {
      final snapshot = await _firestore.enrollments
          .where('estudianteId', isEqualTo: estudianteId)
          .where('deporteId', isEqualTo: deporteId)
          .get();

      final docsActivos = snapshot.docs.where((doc) {
        final data = doc.data();
        return (data['estado'] ?? '').toString().toLowerCase() == 'activa';
      }).toList();

      if (docsActivos.isEmpty) {
        throw const InscripcionException('No tienes una inscripción activa en este deporte.');
      }

      for (final doc in docsActivos) {
        await doc.reference.update({
          'estado': EstadoInscripcion.retirada.name,
          'fechaRetiro': FieldValue.serverTimestamp(),
        });
      }
    } on InscripcionException {
      rethrow;
    } catch (e) {
      throw const InscripcionException('No se pudo cancelar la inscripción.');
    }
  }
}