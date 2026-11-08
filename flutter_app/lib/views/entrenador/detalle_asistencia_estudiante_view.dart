import 'package:flutter/material.dart';

import '../../controllers/entrenador_controller.dart';
import '../../models/usuario.dart';
import '../theme/saman_colors.dart';
import 'formato.dart';
import 'widgets/entrenador_widgets.dart';

/// Detalle de la asistencia de un estudiante (se abre al tocarlo en la
/// nómina o en "Estudiantes en riesgo").
///
/// Muestra el porcentaje total y, mes por mes, cada sesión de la disciplina:
/// si asistió y la fecha y hora exactas del registro. Los registros viejos,
/// que no guardaban la hora, dicen "Hora no registrada".
class DetalleAsistenciaEstudianteView extends StatefulWidget {
  const DetalleAsistenciaEstudianteView({
    super.key,
    required this.controller,
    required this.estudiante,
  });

  final EntrenadorController controller;
  final Usuario estudiante;

  @override
  State<DetalleAsistenciaEstudianteView> createState() =>
      _DetalleAsistenciaEstudianteViewState();
}

class _DetalleAsistenciaEstudianteViewState
    extends State<DetalleAsistenciaEstudianteView> {
  EntrenadorController get _controller => widget.controller;
  late DateTime _mes;

  @override
  void initState() {
    super.initState();
    _mes = _controller.mesesConSesiones.first;
  }

  @override
  Widget build(BuildContext context) {
    final deporte = _controller.deporteActual;
    return Scaffold(
      appBar: AppBar(title: const Text('Asistencia del estudiante')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final meses = _controller.mesesConSesiones;
          if (!meses.contains(_mes)) _mes = meses.first;
          final indice = meses.indexOf(_mes);
          final detalle = _controller.asistenciaMensualDe(
            widget.estudiante.uid,
            _mes,
          );
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _encabezado(deporte?.nombre),
                  const SizedBox(height: 16),
                  _selectorDeMes(
                    // La lista va del más reciente al más antiguo.
                    anterior: indice + 1 < meses.length
                        ? meses[indice + 1]
                        : null,
                    siguiente: indice > 0 ? meses[indice - 1] : null,
                  ),
                  const SizedBox(height: 8),
                  _resumenDelMes(detalle),
                  const SizedBox(height: 8),
                  if (detalle.registros.isEmpty)
                    const Padding(
                      key: Key('sin-sesiones-mes'),
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'No hubo sesiones con asistencia guardada en este mes.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: SamanColors.neutro500),
                      ),
                    )
                  else
                    Card(
                      child: Column(
                        children: [
                          for (final registro in detalle.registros.reversed)
                            _fila(registro),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _encabezado(String? disciplina) {
    final estudiante = widget.estudiante;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            AvatarIniciales(usuario: estudiante, radio: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    estudiante.nombreCompleto,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Carnet ${estudiante.carnet ?? '—'}'
                    '${disciplina == null ? '' : ' · $disciplina'}',
                    style: const TextStyle(color: SamanColors.neutro500),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 12, color: SamanColors.neutro500),
                ),
                EtiquetaPorcentaje(
                  key: const Key('porcentaje-total'),
                  valor: _controller.porcentajeDe(estudiante.uid),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectorDeMes({DateTime? anterior, DateTime? siguiente}) {
    final titulo = mesYAnio(_mes);
    return Row(
      children: [
        IconButton(
          key: const Key('mes-anterior'),
          tooltip: 'Mes anterior',
          onPressed: anterior == null
              ? null
              : () => setState(() => _mes = anterior),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            titulo[0].toUpperCase() + titulo.substring(1),
            key: const Key('titulo-mes-asistencia'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          key: const Key('mes-siguiente'),
          tooltip: 'Mes siguiente',
          onPressed: siguiente == null
              ? null
              : () => setState(() => _mes = siguiente),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _resumenDelMes(AsistenciaMensual detalle) {
    final texto = detalle.sesiones == 0
        ? 'Sin sesiones'
        : 'Asistió a ${detalle.asistencias} de ${detalle.sesiones} '
              '${detalle.sesiones == 1 ? 'sesión' : 'sesiones'} · '
              '${detalle.faltas} '
              '${detalle.faltas == 1 ? 'falta' : 'faltas'}';
    return Row(
      children: [
        Expanded(
          child: Text(
            texto,
            key: const Key('resumen-mes'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        EtiquetaPorcentaje(
          key: const Key('porcentaje-mes'),
          valor: detalle.porcentaje,
        ),
      ],
    );
  }

  Widget _fila(RegistroDeAsistencia registro) {
    final momento = registro.hora;
    final String detalle;
    if (!registro.presente) {
      detalle = 'No asistió';
    } else if (momento == null) {
      detalle = 'Hora no registrada';
    } else if (momento.year == registro.fecha.year &&
        momento.month == registro.fecha.month &&
        momento.day == registro.fecha.day) {
      detalle = 'Registrada a las ${hora(momento)}';
    } else {
      // Asistencia tomada otro día (por ejemplo, al día siguiente).
      detalle = 'Registrada el ${fechaYHora(momento)}';
    }
    return ListTile(
      key: Key('registro-${registro.fecha.toIso8601String().substring(0, 10)}'),
      leading: Icon(
        registro.presente ? Icons.check_circle : Icons.cancel,
        color: registro.presente ? Colors.green[700] : Colors.red[700],
      ),
      title: Text(
        fechaCorta(registro.fecha),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        detalle,
        style: TextStyle(
          color: registro.presente && momento == null
              ? SamanColors.neutro500
              : null,
          fontStyle: registro.presente && momento == null
              ? FontStyle.italic
              : null,
        ),
      ),
      trailing: Text(
        registro.presente ? 'Presente' : 'Ausente',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: registro.presente ? Colors.green[700] : Colors.red[700],
        ),
      ),
    );
  }
}

/// Abre el detalle de asistencia de [estudiante] en la disciplina actual.
Future<void> abrirDetalleAsistencia(
  BuildContext context,
  EntrenadorController controller,
  Usuario estudiante,
) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DetalleAsistenciaEstudianteView(
        controller: controller,
        estudiante: estudiante,
      ),
    ),
  );
}
