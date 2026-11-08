import 'package:flutter/material.dart';

import '../../models/deporte.dart';
import '../../services/baja_disciplina_service.dart';
import '../../services/gestion_entrenadores_service.dart';
import 'crear_deporte_view.dart';

const _azul = Color(0xFF003B82);
const _naranja = Color(0xFFF58220);
const _rojo = Color(0xFFC62828);

/// Gestión de disciplinas del panel del administrador
/// (ruta `/admin/disciplinas`, solo para el rol admin).
///
/// Lista todas las disciplinas en tiempo real, con buscador. Al tocar
/// "Editar" se abre el formulario de la disciplina, donde se cambian el
/// nombre, los horarios, el lugar, los cupos, las etiquetas y los
/// entrenadores (con la validación de choques de horario). "Eliminar" borra la
/// disciplina después de advertir cuántos estudiantes inscritos la perderán.
class GestionDisciplinasView extends StatefulWidget {
  const GestionDisciplinasView({
    super.key,
    required this.datos,
    this.onEditar,
    this.baja,
  });

  /// Vista conectada a Firestore.
  factory GestionDisciplinasView.conFirebase({Key? key}) =>
      GestionDisciplinasView(
        key: key,
        datos: GestionEntrenadoresService(),
        baja: BajaDisciplinaService(),
      );

  final GestionEntrenadoresDataSource datos;

  /// Elimina disciplinas. Si es `null`, no aparece el botón "Eliminar".
  final BajaDisciplinaDataSource? baja;

  /// Abre el formulario de edición. Por defecto, [CrearDeporteView] con la
  /// disciplina; las pruebas pasan otro.
  final void Function(BuildContext context, Deporte deporte)? onEditar;

  @override
  State<GestionDisciplinasView> createState() => _GestionDisciplinasViewState();
}

class _GestionDisciplinasViewState extends State<GestionDisciplinasView> {
  late final Stream<List<Deporte>> _deportes;
  final _busqueda = TextEditingController();
  String _texto = '';

  /// Ids de las disciplinas en proceso de eliminación (revisando
  /// inscripciones, esperando confirmación o borrando): su botón se desactiva.
  final Set<String> _ocupadas = {};

  /// Ids de las disciplinas que se están borrando en Firestore (muestran un
  /// indicador de carga).
  final Set<String> _eliminando = {};

  @override
  void initState() {
    super.initState();
    _deportes = widget.datos.deportes();
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  void _editar(Deporte deporte) {
    final onEditar = widget.onEditar;
    if (onEditar != null) {
      onEditar(context, deporte);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CrearDeporteView(deporte: deporte),
      ),
    );
  }

  void _avisar(String texto, {Color? color}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(backgroundColor: color, content: Text(texto)));
  }

  Future<void> _eliminar(Deporte deporte) async {
    final baja = widget.baja;
    if (baja == null || _ocupadas.contains(deporte.id)) return;
    setState(() => _ocupadas.add(deporte.id));
    try {
      int? conteo;
      try {
        conteo = await baja.inscripcionesActivas(deporte.id);
      } catch (_) {
        conteo = null;
      }
      if (!mounted) return;
      if (conteo == null) {
        _avisar(
          'No se pudo revisar las inscripciones. Intenta de nuevo.',
          color: _rojo,
        );
        return;
      }
      final int inscritos = conteo;

      final confirmar = await showDialog<bool>(
        context: context,
        builder: (contexto) => AlertDialog(
          key: const Key('dialogo-eliminar-disciplina'),
          icon: const Icon(Icons.warning_amber_rounded, color: _rojo, size: 36),
          title: Text('¿Eliminar ${deporte.nombre}?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                inscritos == 0
                    ? 'No tiene estudiantes inscritos.'
                    : inscritos == 1
                    ? '1 estudiante inscrito perderá su cupo.'
                    : '$inscritos estudiantes inscritos perderán su cupo.',
                key: const Key('aviso-inscritos-eliminar'),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: inscritos == 0 ? null : _rojo,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'También se borran sus reseñas. Las asistencias ya tomadas '
                'se conservan como historial. Esta acción no se puede '
                'deshacer.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(contexto).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: const Key('confirmar-eliminar-disciplina'),
              style: FilledButton.styleFrom(backgroundColor: _rojo),
              onPressed: () => Navigator.of(contexto).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
      if (confirmar != true || !mounted) return;

      setState(() => _eliminando.add(deporte.id));
      try {
        await baja.eliminar(deporte.id);
        if (mounted) {
          _avisar(
            'Se eliminó ${deporte.nombre}.',
            color: Colors.green[700],
          );
        }
      } on BajaDisciplinaException catch (e) {
        if (mounted) _avisar(e.mensaje, color: _rojo);
      } catch (_) {
        if (mounted) {
          _avisar(
            'No se pudo eliminar la disciplina. Intenta de nuevo.',
            color: _rojo,
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _ocupadas.remove(deporte.id);
          _eliminando.remove(deporte.id);
        });
      }
    }
  }

  static String _plano(String texto) {
    const origen = 'áéíóúüñ';
    const destino = 'aeiouun';
    final buffer = StringBuffer();
    for (final letra in texto.toLowerCase().split('')) {
      final i = origen.indexOf(letra);
      buffer.write(i == -1 ? letra : destino[i]);
    }
    return buffer.toString();
  }

  bool _coincide(Deporte deporte) {
    final texto = _plano(_texto.trim());
    if (texto.isEmpty) return true;
    return [
      deporte.nombre,
      deporte.disciplina,
      deporte.lugar,
      deporte.entrenadoresTexto,
      ...deporte.etiquetas,
    ].any((campo) => _plano(campo).contains(texto));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar disciplinas'),
        backgroundColor: _azul,
        foregroundColor: Colors.white,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  key: const Key('buscar-disciplina'),
                  controller: _busqueda,
                  onChanged: (valor) => setState(() => _texto = valor),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar por nombre, lugar, entrenador o etiqueta',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(child: _lista()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lista() {
    return StreamBuilder<List<Deporte>>(
      stream: _deportes,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No se pudieron cargar las disciplinas. '
                'Revisa tu conexión e intenta de nuevo.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final todas = [
          for (final deporte in snapshot.data!)
            if (deporte.nombre.trim().isNotEmpty &&
                deporte.nombre != 'Sin nombre')
              deporte,
        ]..sort((a, b) => _plano(a.nombre).compareTo(_plano(b.nombre)));
        final visibles = todas.where(_coincide).toList();

        if (todas.isEmpty) {
          return const Center(
            key: Key('sin-disciplinas-admin'),
            child: Text('Aún no hay disciplinas creadas.'),
          );
        }
        if (visibles.isEmpty) {
          return const Center(
            key: Key('sin-resultados-disciplinas'),
            child: Text('Ninguna disciplina coincide con la búsqueda.'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: visibles.length,
          separatorBuilder: (context, i) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _tarjeta(visibles[i]),
        );
      },
    );
  }

  Widget _tarjeta(Deporte deporte) {
    return Card(
      key: Key('disciplina-admin-${deporte.id}'),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deporte.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _azul,
                        ),
                      ),
                      if (deporte.disciplina.isNotEmpty)
                        Text(
                          deporte.disciplina,
                          style: const TextStyle(color: Colors.black54),
                        ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  key: Key('editar-disciplina-${deporte.id}'),
                  onPressed: () => _editar(deporte),
                  style: FilledButton.styleFrom(backgroundColor: _naranja),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                ),
                if (widget.baja != null)
                  _eliminando.contains(deporte.id)
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          key: Key('eliminar-disciplina-${deporte.id}'),
                          tooltip: 'Eliminar disciplina',
                          onPressed: _ocupadas.contains(deporte.id)
                              ? null
                              : () => _eliminar(deporte),
                          icon: const Icon(Icons.delete_outline, color: _rojo),
                        ),
              ],
            ),
            const SizedBox(height: 10),
            _dato(Icons.schedule, deporte.horariosTexto),
            _dato(
              Icons.place_outlined,
              deporte.lugar.isEmpty ? 'Lugar por definir' : deporte.lugar,
            ),
            _dato(
              Icons.sports_outlined,
              'Entrenadores: ${deporte.entrenadoresTexto}',
            ),
            _dato(Icons.people_outline, 'Cupos: ${deporte.cupos}'),
            if (deporte.etiquetas.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final etiqueta in deporte.etiquetas)
                    Chip(
                      label: Text(
                        '#$etiqueta',
                        style: const TextStyle(fontSize: 12),
                      ),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.orange.shade50,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dato(IconData icono, String texto) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: _azul),
          const SizedBox(width: 8),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}
