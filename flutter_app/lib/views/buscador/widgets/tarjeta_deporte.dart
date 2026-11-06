import 'package:flutter/material.dart';

import '../../../models/deporte.dart';
import '../../theme/saman_colors.dart';
import '../admin/detalle_deporte_view.dart';

/// Tarjeta de un deporte en los resultados del buscador.
class TarjetaDeporte extends StatelessWidget {
  const TarjetaDeporte({
    super.key,
    required this.deporte,
    required this.cuposDisponibles,
    this.onTap,
  });

  final Deporte deporte;
  final int cuposDisponibles;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deporte.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: SamanColors.azulNoche,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      deporte.disciplina,
                      style: const TextStyle(color: SamanColors.neutro500),
                    ),
                    const SizedBox(height: 10),
                    _Dato(icono: Icons.schedule, texto: deporte.horariosTexto),
                    const SizedBox(height: 4),
                    _Dato(
                      icono: Icons.place_outlined,
                      texto: deporte.lugar.isEmpty
                          ? 'Lugar por definir'
                          : deporte.lugar,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              EtiquetaCupos(cuposDisponibles: cuposDisponibles),
            ],
          ),
        ),
      ),
    );
  }
}

/// Etiqueta con los cupos libres: verde si hay, naranja si quedan 3 o
/// menos y roja si no queda ninguno.
class EtiquetaCupos extends StatelessWidget {
  const EtiquetaCupos({super.key, required this.cuposDisponibles});

  final int cuposDisponibles;

  @override
  Widget build(BuildContext context) {
    final (texto, fondo, color) = switch (cuposDisponibles) {
      <= 0 => ('Sin cupos', SamanColors.errorFondo, SamanColors.error),
      <= 3 => (
          'Quedan $cuposDisponibles',
          SamanColors.naranja50,
          SamanColors.naranja700,
        ),
      _ => ('$cuposDisponibles cupos', SamanColors.verde50, SamanColors.verde700),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 16, color: SamanColors.azul),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(color: SamanColors.neutro900, fontSize: 13),
          ),
        ),
      ],
    );
  }
}



@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deporte.nombre), // Muestra el nombre de la disciplina
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 1. Información del Deporte (Puedes reutilizar tus widgets de tarjeta)
              Text(
                'Reseñas de la comunidad',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // 2. Formulario para comentar
              _construirFormulario(),
              const Divider(height: 32),

              // 3. Mostrar errores si la regla de negocio falla (ej. No inscrito)
              if (_controller.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _controller.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              // 4. Lista (Feed) de reseñas
              _construirListaResenas(),
            ],
          );
        },
      ),
    );
  }

Widget _construirFormulario() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selector de calificación simple
          DropdownButtonFormField<int>(
            value: _calificacion,
            decoration: const InputDecoration(
              labelText: 'Calificación',
              border: OutlineInputBorder(),
            ),
            items: [1, 2, 3, 4, 5].map((e) => DropdownMenuItem(
              value: e,
              child: Text('$e Estrellas'),
            )).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _calificacion = val);
            },
          ),
          const SizedBox(height: 12),
          // Input del comentario
          TextFormField(
            controller: _comentarioCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Cuéntanos tu experiencia',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) 
                ? 'El comentario es obligatorio' 
                : null,
          ),
          const SizedBox(height: 16),
          // Botón de guardado con manejo de estado
          FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            // Deshabilitar botón si ya se está enviando a Firebase
            onPressed: _controller.enviando ? null : _enviarResena,
            child: _controller.enviando 
                ? const SizedBox(
                    height: 20, width: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : const Text('Publicar Reseña'),
          ),
        ],
      ),
    );
  }

  Future<void> _enviarResena() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Llamamos a la lógica de negocio del controlador
    final exito = await _controller.publicarResena(
      _calificacion, 
      _comentarioCtrl.text,
    );

    if (exito) {
      _comentarioCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reseña publicada con éxito')),
        );
      }
    }
  }

  Widget _construirListaResenas() {
    if (_controller.cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    final resenas = _controller.resenas ?? [];
    if (resenas.isEmpty) {
      return const Text('Aún no hay reseñas. ¡Sé el primero en comentar!');
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // Evita conflicto de scroll con el ListView padre
      itemCount: resenas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final r = resenas[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.star, color: Colors.amber),
            title: Text('${r.calificacion} Estrellas'),
            subtitle: Text(r.comentario),
            trailing: Text(
              '${r.fecha.day}/${r.fecha.month}/${r.fecha.year}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}
