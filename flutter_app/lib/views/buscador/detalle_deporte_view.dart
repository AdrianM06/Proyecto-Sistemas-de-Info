import 'package:flutter/material.dart';

import '../../controllers/detalle_deporte_controller.dart';
import '../../models/deporte.dart';
import '../../models/resena.dart';
import '../../services/resena_service.dart';
import '../entrenador/formato.dart';
import '../theme/saman_colors.dart';
import '../widgets/estrellas.dart';

/// Detalle de una disciplina con sus reseñas.
///
/// Muestra los datos de la disciplina, el promedio de estrellas en tiempo
/// real, el formulario para que el estudiante publique o edite su reseña
/// (solo si participó en la disciplina) y la lista de reseñas.
class DetalleDeporteView extends StatefulWidget {
  const DetalleDeporteView({
    super.key,
    required this.deporte,
    required this.controller,
  });

  /// Vista conectada a Firestore. [estudianteId] es `null` si no hay un
  /// estudiante con sesión: entonces solo se leen las reseñas.
  factory DetalleDeporteView.conFirebase({
    Key? key,
    required Deporte deporte,
    String? estudianteId,
  }) {
    return DetalleDeporteView(
      key: key,
      deporte: deporte,
      controller: DetalleDeporteController(
        datos: ResenasService(),
        deporteId: deporte.id,
        estudianteId: estudianteId,
      ),
    );
  }

  final Deporte deporte;

  /// La vista libera este controlador al cerrarse.
  final DetalleDeporteController controller;

  @override
  State<DetalleDeporteView> createState() => _DetalleDeporteViewState();
}

class _DetalleDeporteViewState extends State<DetalleDeporteView> {
  final _comentario = TextEditingController();
  int _rating = 0;
  bool _formularioRelleno = false;
  String? _errorFormulario;

  DetalleDeporteController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_rellenarConMiResena);
    _controller.iniciar();
  }

  @override
  void dispose() {
    _controller.removeListener(_rellenarConMiResena);
    _controller.dispose();
    _comentario.dispose();
    super.dispose();
  }

  /// Si el estudiante ya publicó, el formulario arranca con su reseña para
  /// que pueda editarla.
  void _rellenarConMiResena() {
    final mia = _controller.miResena;
    if (_formularioRelleno || mia == null) return;
    _formularioRelleno = true;
    setState(() {
      _rating = mia.rating;
      _comentario.text = mia.comment;
    });
  }

  Future<void> _publicar() async {
    final eraNueva = _controller.miResena == null;
    final error =
        DetalleDeporteController.validar(_rating, _comentario.text) ??
        await _controller.publicar(rating: _rating, comment: _comentario.text);
    if (!mounted) return;
    setState(() => _errorFormulario = error);
    if (error == null) {
      _formularioRelleno = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green[700],
          content: Text(
            eraNueva ? 'Tu reseña se publicó.' : 'Tu reseña se actualizó.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.deporte.nombre)),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _datosDeporte(),
                const SizedBox(height: 16),
                _resumen(),
                const SizedBox(height: 16),
                _formulario(),
                const SizedBox(height: 24),
                Text(
                  'Reseñas de estudiantes',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ..._lista(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _datosDeporte() {
    final deporte = widget.deporte;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (deporte.disciplina.isNotEmpty)
              Text(
                deporte.disciplina,
                style: const TextStyle(color: SamanColors.neutro500),
              ),
            const SizedBox(height: 8),
            _dato(Icons.schedule, deporte.horariosTexto),
            const SizedBox(height: 4),
            _dato(
              Icons.place_outlined,
              deporte.lugar.isEmpty ? 'Lugar por definir' : deporte.lugar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dato(IconData icono, String texto) {
    return Row(
      children: [
        Icon(icono, size: 18, color: SamanColors.azul),
        const SizedBox(width: 8),
        Expanded(child: Text(texto)),
      ],
    );
  }

  Widget _resumen() {
    final promedio = _controller.promedio;
    final cantidad = _controller.cantidad;
    return Row(
      children: [
        Text(
          promedio == null
              ? '–'
              : promedio.toStringAsFixed(1).replaceAll('.', ','),
          key: const Key('promedio-resenas'),
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: SamanColors.azulNoche,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EstrellasFijas(valor: promedio ?? 0, tamano: 22),
            Text(
              cantidad == 1 ? '1 reseña' : '$cantidad reseñas',
              key: const Key('cantidad-resenas'),
              style: const TextStyle(color: SamanColors.neutro500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _aviso(Key key, String texto) {
    return Card(
      key: key,
      child: ListTile(
        leading: const Icon(Icons.info_outline, color: SamanColors.neutro500),
        title: Text(texto),
      ),
    );
  }

  Widget _formulario() {
    if (!_controller.haySesion) {
      return _aviso(
        const Key('aviso-sin-sesion'),
        'Inicia sesión como estudiante para dejar tu reseña.',
      );
    }
    if (_controller.verificando) return const LinearProgressIndicator();
    if (!_controller.puedeResenar) {
      return _aviso(
        const Key('aviso-sin-participacion'),
        'Solo pueden opinar los estudiantes que se han inscrito en esta '
        'disciplina.',
      );
    }

    final enviando = _controller.enviando;
    final editando = _controller.miResena != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              editando ? 'Editar tu reseña' : 'Tu reseña',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            SelectorEstrellas(
              valor: _rating,
              onChanged: enviando
                  ? null
                  : (valor) => setState(() => _rating = valor),
            ),
            const SizedBox(height: 4),
            TextField(
              key: const Key('campo-comentario'),
              controller: _comentario,
              enabled: !enviando,
              maxLines: 4,
              maxLength: Resena.largoMaximo,
              decoration: const InputDecoration(
                labelText: 'Comentario',
                hintText:
                    'Cuéntales a otros estudiantes cómo fue tu experiencia',
                border: OutlineInputBorder(),
              ),
            ),
            if (_errorFormulario != null) ...[
              Text(
                _errorFormulario!,
                key: const Key('error-resena'),
                style: TextStyle(color: Colors.red[700]),
              ),
              const SizedBox(height: 8),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                key: const Key('boton-publicar-resena'),
                onPressed: enviando ? null : _publicar,
                child: enviando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(editando ? 'Actualizar reseña' : 'Publicar reseña'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _lista() {
    if (_controller.errorCarga != null) {
      return [
        Text(_controller.errorCarga!, key: const Key('error-carga-resenas')),
      ];
    }
    if (_controller.cargando) {
      return const [Center(child: CircularProgressIndicator())];
    }
    final resenas = _controller.resenas;
    if (resenas.isEmpty) {
      return const [
        Text(
          'Aún no hay reseñas. Sé el primero en opinar.',
          key: Key('sin-resenas'),
          style: TextStyle(color: SamanColors.neutro500),
        ),
      ];
    }
    return [
      for (final resena in resenas)
        Card(
          key: Key('resena-${resena.estudianteId}'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        resena.estudianteId == _controller.estudianteId
                            ? '${resena.autor} (tú)'
                            : resena.autor,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      resena.createdAt == null
                          ? 'Ahora'
                          : fechaCorta(resena.createdAt!),
                      style: const TextStyle(
                        color: SamanColors.neutro500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                EstrellasFijas(valor: resena.rating.toDouble()),
                const SizedBox(height: 6),
                Text(resena.comment),
              ],
            ),
          ),
        ),
    ];
  }
}
