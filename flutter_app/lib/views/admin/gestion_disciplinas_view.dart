import 'package:flutter/material.dart';

import '../../models/deporte.dart';
import '../../services/gestion_entrenadores_service.dart';
import 'crear_deporte_view.dart';

const _azul = Color(0xFF003B82);
const _naranja = Color(0xFFF58220);

/// Gestión de disciplinas del panel del administrador
/// (ruta `/admin/disciplinas`, solo para el rol admin).
///
/// Lista todas las disciplinas en tiempo real, con buscador. Al tocar
/// "Editar" se abre el formulario de la disciplina, donde se cambian el
/// nombre, los horarios, el lugar, los cupos, las etiquetas y los
/// entrenadores (con la validación de choques de horario).
class GestionDisciplinasView extends StatefulWidget {
  const GestionDisciplinasView({super.key, required this.datos, this.onEditar});

  /// Vista conectada a Firestore.
  factory GestionDisciplinasView.conFirebase({Key? key}) =>
      GestionDisciplinasView(key: key, datos: GestionEntrenadoresService());

  final GestionEntrenadoresDataSource datos;

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
