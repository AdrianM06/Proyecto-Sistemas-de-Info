import 'package:cloud_firestore/cloud_firestore.dart';

// Importa tus conversores tal como lo haces en usuario.dart y deporte.dart
import 'conversores.dart'; 

/// Modelo de un documento de la subcolección `reviews` en Firestore.
class Resena {
  const Resena({
    required this.id,
    required this.estudianteId,
    required this.calificacion,
    required this.comentario,
    required this.fecha,
  });

  final String id;
  final String estudianteId; // Para vincularlo con el autor
  final int calificacion;    // Ej. 1 a 5 estrellas
  final String comentario;
  final DateTime fecha;      // Cuándo se publicó

  /// Patrón Factory Method: crea una [Resena] a partir de un mapa, 
  /// usando los conversores de tu proyecto.
  factory Resena.fromJson(Map<String, dynamic> json, {required String id}) {
    return Resena(
      id: id,
      // Se usan los conversores textoDe y enteroDe que ya tienes en conversores.dart
      estudianteId: textoDe(json['estudianteId']),
      calificacion: enteroDe(json['calificacion'], porDefecto: 5), 
      comentario: textoDe(json['comentario']),
      // Firestore guarda las fechas como Timestamp, debemos pasarlo a DateTime de Dart
      fecha: (json['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Crea una [Resena] directamente desde un documento de Firestore.
  factory Resena.fromFirestore(DocumentSnapshot> doc) {
    return Resena.fromJson(doc.data() ?? const {}, id: doc.id);
  }

  /// Convierte el objeto a un mapa para guardarlo en la base de datos.
  Map<String, dynamic> toJson() => {
        'estudianteId': estudianteId,
        'calificacion': calificacion,
        'comentario': comentario,
        // Convertimos el DateTime de Dart de vuelta a Timestamp para Firebase
        'fecha': Timestamp.fromDate(fecha), 
      };
}
