import 'package:flutter/material.dart';

import '../controllers/inicio_estudiante_controller.dart';
import '../services/inicio_estudiante_service.dart';
import 'entrenador/formato.dart';
import 'estudiante/calendario_entrenamientos.dart';
import 'estudiante/estudiante_scaffold.dart';
import 'theme/saman_colors.dart';

/// Inicio del estudiante (ruta `/estudiante`).
///
/// Usa [EstudianteScaffold]: el menú hamburguesa abre el menú lateral con
/// Inicio, Catálogo, Pagos, Mi perfil, Página principal y Cerrar sesión.
///
/// Muestra el calendario de entrenamientos y las disciplinas registradas del
/// estudiante. Ambos se actualizan en tiempo real con
/// [InicioEstudianteController]: al inscribirse o retirarse no hace falta
/// recargar la página.
class StudentView extends StatefulWidget {
  const StudentView({
    super.key,
    required this.controller,
    this.onCerrarSesion,
    this.onAbrirPerfil,
    this.onIrACatalogo,
    this.onIrALanding,
    this.avatar,
  });

  /// Vista conectada a Firestore.
  factory StudentView.conFirebase({
    Key? key,
    required String estudianteId,
    VoidCallback? onCerrarSesion,
    VoidCallback? onAbrirPerfil,
    VoidCallback? onIrACatalogo,
    VoidCallback? onIrALanding,
    Widget? avatar,
  }) {
    return StudentView(
      key: key,
      controller: InicioEstudianteController(
        datos: InicioEstudianteService(),
        estudianteId: estudianteId,
      ),
      onCerrarSesion: onCerrarSesion,
      onAbrirPerfil: onAbrirPerfil,
      onIrACatalogo: onIrACatalogo,
      onIrALanding: onIrALanding,
      avatar: avatar,
    );
  }

  /// La vista libera este controlador al cerrarse.
  final InicioEstudianteController controller;

  /// Botón "Cerrar sesión" (barra superior y menú). Si es `null`, no aparece.
  final VoidCallback? onCerrarSesion;

  /// Foto de perfil de la barra superior y "Mi perfil" del menú.
  final VoidCallback? onAbrirPerfil;

  /// "Catálogo" del menú: abre el buscador de deportes.
  final VoidCallback? onIrACatalogo;

  /// "Página principal" del menú: vuelve a la Landing Page.
  final VoidCallback? onIrALanding;

  /// Foto de perfil que se muestra arriba a la derecha.
  final Widget? avatar;

  @override
  State<StudentView> createState() => _StudentViewState();
}

class _StudentViewState extends State<StudentView> {
  InicioEstudianteController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.iniciar();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EstudianteScaffold(
      seccion: SeccionEstudiante.inicio,
      avatar: widget.avatar,
      onCatalogo: widget.onIrACatalogo,
      // El saldo y los pagos se consultan en el perfil.
      onPagos: widget.onAbrirPerfil,
      onPerfil: widget.onAbrirPerfil,
      onPaginaPrincipal: widget.onIrALanding,
      onCerrarSesion: widget.onCerrarSesion,
      acciones: [
        if (widget.onIrACatalogo != null) _botonCatalogo(context),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) => _contenido(),
            ),
          ),
        ),
      ),
    );
  }

  /// "Explorar catálogo" en la barra superior, junto a la foto de perfil. En
  /// pantallas angostas queda solo el ícono para no tapar el logo.
  Widget _botonCatalogo(BuildContext context) {
    final angosta = MediaQuery.sizeOf(context).width < 600;
    if (angosta) {
      return IconButton(
        key: const Key('inicio-ver-catalogo'),
        tooltip: 'Explorar el catálogo de disciplinas',
        onPressed: widget.onIrACatalogo,
        icon: const Icon(Icons.search, color: SamanColors.azul),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton.icon(
        key: const Key('inicio-ver-catalogo'),
        onPressed: widget.onIrACatalogo,
        icon: const Icon(Icons.search),
        label: const Text('Explorar catálogo'),
      ),
    );
  }

  /// Ancho a partir del cual el calendario y las disciplinas van lado a lado.
  static const double _anchoDosColumnas = 820;

  Widget _contenido() {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final calendario = _columnaCalendario();
        final disciplinas = _columnaDisciplinas();
        if (restricciones.maxWidth < _anchoDosColumnas) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [calendario, const SizedBox(height: 30), disciplinas],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 440, child: calendario),
            const SizedBox(width: 28),
            Expanded(child: disciplinas),
          ],
        );
      },
    );
  }

  Widget _columnaCalendario() {
    return Column(
      key: const Key('columna-calendario'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Calendario de entrenamientos',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        _proximo(),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: CalendarioEntrenamientos(controller: _controller),
            ),
          ),
        ),
      ],
    );
  }

  Widget _columnaDisciplinas() {
    return Column(
      key: const Key('columna-disciplinas'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Disciplinas registradas',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ..._disciplinas(),
      ],
    );
  }

  Widget _proximo() {
    final dia = _controller.proximoEntrenamiento;
    final texto = dia == null
        ? (_controller.disciplinas.isEmpty
              ? 'Inscríbete en una disciplina para ver tus entrenamientos.'
              : 'No tienes entrenamientos en los próximos 7 días.')
        : 'Próximo entrenamiento: ${fechaLarga(dia)} · '
              '${_controller.entrenamientosDe(dia).map((d) => d.nombre).join(', ')}';
    return Text(
      texto,
      key: const Key('proximo-entrenamiento'),
      style: const TextStyle(color: SamanColors.neutro500),
    );
  }

  List<Widget> _disciplinas() {
    if (_controller.error != null) {
      return [
        Card(
          color: Colors.white,
          child: ListTile(
            key: const Key('error-disciplinas'),
            leading: const Icon(Icons.cloud_off, color: SamanColors.error),
            title: Text(_controller.error!),
            trailing: TextButton(
              onPressed: _controller.iniciar,
              child: const Text('Reintentar'),
            ),
          ),
        ),
      ];
    }
    if (_controller.cargando) {
      return const [
        Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    final disciplinas = _controller.disciplinas;
    if (disciplinas.isEmpty) {
      return const [
        Card(
          color: Colors.white,
          child: ListTile(
            key: Key('sin-disciplinas'),
            leading: Icon(Icons.info_outline, color: SamanColors.neutro500),
            title: Text('Aún no estás inscrito en ninguna disciplina.'),
          ),
        ),
      ];
    }
    return [
      for (final deporte in disciplinas)
        Card(
          key: Key('disciplina-${deporte.id}'),
          color: Colors.white,
          child: ListTile(
            leading: Icon(
              Icons.check_circle,
              color: Colors.blue[900],
              size: 40,
            ),
            title: const Text(
              'Estás inscrito en',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            subtitle: Text(
              deporte.nombre,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            trailing: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(
                deporte.horariosTexto,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
        ),
    ];
  }
}
