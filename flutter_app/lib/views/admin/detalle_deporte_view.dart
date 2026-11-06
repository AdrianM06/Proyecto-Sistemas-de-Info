import 'package:flutter/material.dart';
import '../models/deporte.dart';
import '../controllers/detalle_deporte_controller.dart';
import '../services/resena_service.dart';

class DetalleDeporteView extends StatefulWidget {
  const DetalleDeporteView({
    super.key,
    required this.deporte,
    required this.estudianteId,
  });

  final Deporte deporte;
  final String estudianteId;

  @override
  State<DetalleDeporteView> createState() => _DetalleDeporteViewState();
}

class _DetalleDeporteViewState extends State<DetalleDeporteView> {
  late DetalleDeporteController _controller;
  
  // Controladores para el formulario de reseña
  final _formKey = GlobalKey<FormState>();
  final _comentarioCtrl = TextEditingController();
  int _calificacion = 5; // Por defecto 5 estrellas

  @override
  void initState() {
    super.initState();
    // Inicializamos el controlador inyectando sus dependencias
    _controller = DetalleDeporteController(
      deporteId: widget.deporte.id,
      estudianteId: widget.estudianteId,
      datos: ResenasService(),
    );
    // Arrancamos la escucha en tiempo real de Firebase
    _controller.iniciar();
  }

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Continuación de la clase abajo...
