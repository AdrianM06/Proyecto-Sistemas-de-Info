import 'package:flutter/material.dart';

import '../../models/resumen_admin.dart';
import '../../services/resumen_admin_service.dart';

const _azul = Color(0xFF003B82);
const _naranja = Color(0xFFF58220);
const _rojo = Color(0xFFC62828);

/// Resumen en números y gráficos del panel del administrador (CU14), con un
/// botón para actualizar las cifras.
class PanelResumenAdmin extends StatefulWidget {
  const PanelResumenAdmin({super.key, required this.datos});

  /// Panel conectado a Firestore.
  factory PanelResumenAdmin.conFirebase({Key? key}) =>
      PanelResumenAdmin(key: key, datos: ResumenAdminService());

  final ResumenAdminDataSource datos;

  @override
  State<PanelResumenAdmin> createState() => _PanelResumenAdminState();
}

class _PanelResumenAdminState extends State<PanelResumenAdmin> {
  late Future<ResumenAdmin> _resumen;
  DateTime? _actualizado;

  @override
  void initState() {
    super.initState();
    _resumen = _pedir();
  }

  Future<ResumenAdmin> _pedir() async {
    final resumen = await widget.datos.cargar();
    _actualizado = DateTime.now();
    return resumen;
  }

  void _actualizar() {
    setState(() {
      _resumen = _pedir();
    });
  }

  static String _hora(DateTime fecha) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(fecha.hour)}:${dos(fecha.minute)}';
  }

  static String _plural(int n, String singular, String plural) =>
      '$n ${n == 1 ? singular : plural}';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ResumenAdmin>(
      future: _resumen,
      builder: (context, snapshot) {
        final cargando = snapshot.connectionState != ConnectionState.done;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Resumen',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (!cargando && snapshot.hasData && _actualizado != null)
                  Text(
                    'Actualizado a las ${_hora(_actualizado!)}',
                    key: const Key('resumen-hora'),
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                IconButton(
                  key: const Key('resumen-actualizar'),
                  tooltip: 'Actualizar cifras',
                  onPressed: cargando ? null : _actualizar,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (cargando)
              const Padding(
                key: Key('resumen-cargando'),
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (snapshot.hasError || !snapshot.hasData)
              _error()
            else
              _tarjetas(snapshot.data!),
          ],
        );
      },
    );
  }

  Widget _error() {
    return Card(
      key: const Key('resumen-error'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, color: _rojo),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No se pudo cargar el resumen. Revisa tu conexión.',
              ),
            ),
            TextButton(
              key: const Key('resumen-reintentar'),
              onPressed: _actualizar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetas(ResumenAdmin r) {
    final tarjetas = [
      _TarjetaCifra(
        key: const Key('resumen-estudiantes'),
        icono: Icons.school_outlined,
        titulo: 'Estudiantes',
        valor: r.estudiantes,
        detalle:
            '${_plural(r.estudiantesActivos, 'activo', 'activos')} · '
            '${_plural(r.estudiantesDeshabilitados, 'deshabilitado', 'deshabilitados')}',
      ),
      _TarjetaCifra(
        key: const Key('resumen-entrenadores'),
        icono: Icons.sports_outlined,
        titulo: 'Entrenadores',
        valor: r.entrenadores,
        detalle: r.entrenadores == 0
            ? 'Regístralos desde "Registrar entrenador"'
            : 'Cuentas creadas por el administrador',
      ),
      _TarjetaCifra(
        key: const Key('resumen-disciplinas'),
        icono: Icons.sports_soccer_outlined,
        titulo: 'Disciplinas',
        valor: r.disciplinas,
        detalle: r.disciplinasSinEntrenador == 0
            ? 'Todas tienen entrenador'
            : '${_plural(r.disciplinasSinEntrenador, 'disciplina', 'disciplinas')} '
                  'sin entrenador',
        alerta: r.disciplinasSinEntrenador > 0,
      ),
      _TarjetaCifra(
        key: const Key('resumen-inscripciones'),
        icono: Icons.how_to_reg_outlined,
        titulo: 'Inscripciones activas',
        valor: r.inscripcionesActivas,
        detalle: 'Ocupación: ${r.ocupacionTexto}',
        progreso: r.ocupacion,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columnas = constraints.maxWidth >= 900
                ? 4
                : (constraints.maxWidth >= 420 ? 2 : 1);
            const espacio = 12.0;
            final ancho =
                (constraints.maxWidth - espacio * (columnas - 1)) / columnas;
            return Wrap(
              spacing: espacio,
              runSpacing: espacio,
              children: [
                for (final tarjeta in tarjetas)
                  SizedBox(width: ancho, child: tarjeta),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            const espacio = 12.0;
            final columnas = constraints.maxWidth >= 620 ? 2 : 1;
            final ancho =
                (constraints.maxWidth - espacio * (columnas - 1)) / columnas;
            return Wrap(
              spacing: espacio,
              runSpacing: espacio,
              children: [
                SizedBox(
                  width: ancho,
                  child: _GraficoBarras(
                    key: const Key('grafico-estudiantes'),
                    titulo: 'Estado de estudiantes',
                    barras: r.estudiantes == 0
                        ? const []
                        : [
                            _DatoBarra(
                              clave: 'grafico-estudiantes-activos',
                              etiqueta: 'Activos',
                              valor: r.estudiantesActivos,
                              fraccion: r.estudiantesActivos / r.estudiantes,
                              color: _azul,
                            ),
                            _DatoBarra(
                              clave: 'grafico-estudiantes-deshabilitados',
                              etiqueta: 'Deshabilitados',
                              valor: r.estudiantesDeshabilitados,
                              fraccion: (r.estudiantesDeshabilitados /
                                      r.estudiantes)
                                  .clamp(0.0, 1.0),
                              color: _naranja,
                            ),
                          ],
                    mensajeVacio: 'No hay estudiantes registrados.',
                  ),
                ),
                SizedBox(
                  width: ancho,
                  child: _GraficoBarras(
                    key: const Key('grafico-cupos'),
                    titulo: 'Ocupación de cupos',
                    barras: r.cuposTotales <= 0
                        ? const []
                        : [
                            _DatoBarra(
                              clave: 'grafico-cupos-ocupados',
                              etiqueta: 'Ocupados',
                              valor: r.inscripcionesActivas,
                              fraccion: r.ocupacion!,
                              color: _naranja,
                            ),
                            _DatoBarra(
                              clave: 'grafico-cupos-disponibles',
                              etiqueta: 'Disponibles',
                              valor: (r.cuposTotales - r.inscripcionesActivas)
                                  .clamp(0, r.cuposTotales),
                              fraccion: (1 - r.ocupacion!).clamp(0.0, 1.0),
                              color: _azul,
                            ),
                          ],
                    mensajeVacio: 'No hay cupos definidos.',
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DatoBarra {
  const _DatoBarra({
    required this.clave,
    required this.etiqueta,
    required this.valor,
    required this.fraccion,
    required this.color,
  });

  final String clave;
  final String etiqueta;
  final int valor;
  final double fraccion;
  final Color color;
}

class _GraficoBarras extends StatelessWidget {
  const _GraficoBarras({
    super.key,
    required this.titulo,
    required this.barras,
    required this.mensajeVacio,
  });

  final String titulo;
  final List<_DatoBarra> barras;
  final String mensajeVacio;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 16),
          if (barras.isEmpty)
            Text(mensajeVacio, style: const TextStyle(color: Colors.black54))
          else
            for (var i = 0; i < barras.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              _BarraGrafico(dato: barras[i]),
            ],
        ],
      ),
    );
  }
}

class _BarraGrafico extends StatelessWidget {
  const _BarraGrafico({required this.dato});

  final _DatoBarra dato;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                dato.etiqueta,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ),
            Text(
              '${dato.valor}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            key: Key(dato.clave),
            value: dato.fraccion,
            minHeight: 10,
            color: dato.color,
            backgroundColor: const Color(0xFFF1F3F7),
          ),
        ),
      ],
    );
  }
}

class _TarjetaCifra extends StatelessWidget {
  const _TarjetaCifra({
    super.key,
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.detalle,
    this.alerta = false,
    this.progreso,
  });

  final IconData icono;
  final String titulo;
  final int valor;
  final String detalle;
  final bool alerta;

  /// Barra de ocupación (0 a 1). Si es `null` no se dibuja.
  final double? progreso;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: _naranja, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$valor',
            key: const Key('resumen-valor'),
            style: const TextStyle(
              color: _azul,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (progreso != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progreso,
                minHeight: 6,
                color: _naranja,
                backgroundColor: const Color(0xFFF1F3F7),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              if (alerta) ...[
                const Icon(Icons.warning_amber_rounded, color: _rojo, size: 16),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  detalle,
                  style: TextStyle(
                    fontSize: 12,
                    color: alerta ? _rojo : Colors.black54,
                    fontWeight: alerta ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
