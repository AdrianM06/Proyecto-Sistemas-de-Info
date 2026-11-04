import 'package:flutter/material.dart';

import '../../controllers/inicio_estudiante_controller.dart';
import '../../models/conversores.dart';
import '../entrenador/formato.dart';
import '../theme/saman_colors.dart';

const _meses = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

const _inicialesDias = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

/// Calendario mensual con los días de entrenamiento de las disciplinas donde
/// el estudiante está inscrito.
///
/// Se redibuja solo cuando cambian las inscripciones o los horarios (ver
/// [InicioEstudianteController]). Al tocar un día se listan las disciplinas
/// que entrenan ese día.
class CalendarioEntrenamientos extends StatefulWidget {
  const CalendarioEntrenamientos({super.key, required this.controller});

  final InicioEstudianteController controller;

  @override
  State<CalendarioEntrenamientos> createState() =>
      _CalendarioEntrenamientosState();
}

class _CalendarioEntrenamientosState extends State<CalendarioEntrenamientos> {
  late DateTime _mes;
  late DateTime _seleccionado;

  InicioEstudianteController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    final hoy = _controller.hoy;
    _mes = DateTime(hoy.year, hoy.month);
    _seleccionado = hoy;
  }

  void _cambiarMes(int cantidad) {
    setState(() => _mes = DateTime(_mes.year, _mes.month + cantidad));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _encabezado(),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final inicial in _inicialesDias)
                  Expanded(
                    child: Center(
                      child: Text(
                        inicial,
                        style: const TextStyle(
                          color: SamanColors.neutro500,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            _cuadricula(),
            const Divider(height: 24),
            _detalleDelDia(),
          ],
        );
      },
    );
  }

  Widget _encabezado() {
    return Row(
      children: [
        IconButton(
          key: const Key('mes-anterior'),
          tooltip: 'Mes anterior',
          onPressed: () => _cambiarMes(-1),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            '${_meses[_mes.month - 1]} ${_mes.year}',
            key: const Key('titulo-mes'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          key: const Key('mes-siguiente'),
          tooltip: 'Mes siguiente',
          onPressed: () => _cambiarMes(1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _cuadricula() {
    final primero = DateTime(_mes.year, _mes.month);
    final diasDelMes = DateUtils.getDaysInMonth(_mes.year, _mes.month);
    final huecos = primero.weekday - 1;
    final hoy = _controller.hoy;

    final celdas = <Widget>[
      for (var i = 0; i < huecos; i++) const SizedBox.shrink(),
      for (var dia = 1; dia <= diasDelMes; dia++)
        _celda(DateTime(_mes.year, _mes.month, dia), hoy),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: celdas,
    );
  }

  Widget _celda(DateTime fecha, DateTime hoy) {
    final entrena = _controller.entrenamientosDe(fecha).isNotEmpty;
    final seleccionado = DateUtils.isSameDay(fecha, _seleccionado);
    final esHoy = DateUtils.isSameDay(fecha, hoy);

    final fondo = seleccionado
        ? SamanColors.azul
        : entrena
        ? SamanColors.naranja50
        : Colors.transparent;
    final color = seleccionado ? Colors.white : SamanColors.azulNoche;

    return InkWell(
      key: Key('dia-${claveDeFecha(fecha)}'),
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _seleccionado = fecha),
      child: Container(
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(10),
          border: esHoy && !seleccionado
              ? Border.all(color: SamanColors.azul, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${fecha.day}',
              style: TextStyle(
                color: color,
                fontWeight: entrena || esHoy
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              key: entrena ? Key('entrena-${claveDeFecha(fecha)}') : null,
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: entrena
                    ? (seleccionado ? Colors.white : SamanColors.naranja)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detalleDelDia() {
    final deportes = _controller.entrenamientosDe(_seleccionado);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fechaLarga(_seleccionado),
          key: const Key('fecha-seleccionada'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (deportes.isEmpty)
          const Text(
            'No tienes entrenamientos este día.',
            key: Key('sin-entrenamientos-dia'),
            style: TextStyle(color: SamanColors.neutro500),
          )
        else
          for (final deporte in deportes)
            Padding(
              key: Key('entrenamiento-${deporte.id}'),
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.sports_score,
                    size: 20,
                    color: SamanColors.naranja,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deporte.nombre,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          deporte.lugar.isEmpty
                              ? deporte.horariosTexto
                              : '${deporte.horariosTexto} · ${deporte.lugar}',
                          style: const TextStyle(
                            color: SamanColors.neutro500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
