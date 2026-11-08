import 'package:flutter/material.dart';
import 'package:flutter_app/controllers/buscador_controller.dart';
import 'package:flutter_app/controllers/detalle_deporte_controller.dart';
import 'package:flutter_app/models/deporte.dart';
import 'package:flutter_app/services/buscador_demo_service.dart';
import 'package:flutter_app/views/buscador/buscador_screen.dart';
import 'package:flutter_app/views/buscador/detalle_deporte_view.dart';
import 'package:flutter_app/views/theme/saman_colors.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/resenas_falsas.dart';

const _ajedrez = Deporte(
  id: 'AJE-01',
  nombre: 'Ajedrez',
  disciplina: 'Ajedrez',
  cupos: 30,
  entrenadorId: '',
  horarios: ['Vie 1:00–3:00 pm'],
  lugar: 'Biblioteca, sala 2',
);

void main() {
  late ResenasFalsas datos;

  Future<void> abrir(WidgetTester tester, {String? estudiante}) async {
    tester.view.physicalSize = const Size(1000, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: SamanColors.tema(),
        home: DetalleDeporteView(
          deporte: _ajedrez,
          controller: DetalleDeporteController(
            datos: datos,
            deporteId: _ajedrez.id,
            estudianteId: estudiante,
          ),
        ),
      ),
    );
    datos.emitir();
    await tester.pumpAndSettle();
  }

  String? texto(WidgetTester tester, String clave) =>
      tester.widget<Text>(find.byKey(Key(clave))).data;

  testWidgets('muestra el promedio, la cantidad y la lista de reseñas', (
    tester,
  ) async {
    datos = ResenasFalsas(
      iniciales: [resena('a', 5), resena('b', 4), resena('c', 4)],
    );
    await abrir(tester);

    expect(texto(tester, 'promedio-resenas'), '4,3');
    expect(texto(tester, 'cantidad-resenas'), '3 reseñas');
    expect(find.byKey(const Key('resena-a')), findsOneWidget);
    expect(find.byKey(const Key('resena-c')), findsOneWidget);
  });

  testWidgets('sin reseñas invita a opinar', (tester) async {
    datos = ResenasFalsas();
    await abrir(tester);

    expect(texto(tester, 'promedio-resenas'), '–');
    expect(find.byKey(const Key('sin-resenas')), findsOneWidget);
  });

  testWidgets('sin sesión no se muestra el formulario', (tester) async {
    datos = ResenasFalsas();
    await abrir(tester);

    expect(find.byKey(const Key('aviso-sin-sesion')), findsOneWidget);
    expect(find.byKey(const Key('boton-publicar-resena')), findsNothing);
  });

  testWidgets('quien no participó en la disciplina no puede opinar', (
    tester,
  ) async {
    datos = ResenasFalsas(participa: false);
    await abrir(tester, estudiante: 'yo');

    expect(find.byKey(const Key('aviso-sin-participacion')), findsOneWidget);
    expect(find.byKey(const Key('boton-publicar-resena')), findsNothing);
  });

  testWidgets('no se envía sin estrellas ni sin comentario', (tester) async {
    datos = ResenasFalsas();
    await abrir(tester, estudiante: 'yo');

    await tester.tap(find.byKey(const Key('boton-publicar-resena')));
    await tester.pumpAndSettle();
    expect(texto(tester, 'error-resena'), 'Elige de 1 a 5 estrellas.');

    await tester.tap(find.byKey(const Key('estrella-4')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('boton-publicar-resena')));
    await tester.pumpAndSettle();
    expect(texto(tester, 'error-resena'), 'Escribe un comentario.');
    expect(datos.guardados, 0);
  });

  testWidgets('publicar una reseña la agrega y actualiza el promedio', (
    tester,
  ) async {
    datos = ResenasFalsas(iniciales: [resena('a', 2)]);
    await abrir(tester, estudiante: 'yo');
    expect(texto(tester, 'promedio-resenas'), '2,0');

    await tester.tap(find.byKey(const Key('estrella-4')));
    await tester.enterText(
      find.byKey(const Key('campo-comentario')),
      'Buen ambiente y horarios cómodos',
    );
    await tester.tap(find.byKey(const Key('boton-publicar-resena')));
    await tester.pumpAndSettle();

    expect(datos.guardados, 1);
    expect(find.text('Tu reseña se publicó.'), findsOneWidget);
    expect(texto(tester, 'promedio-resenas'), '3,0');
    expect(find.text('Andrea Pérez (tú)'), findsOneWidget);
    expect(find.text('Actualizar reseña'), findsOneWidget);
  });

  testWidgets('si ya opinó, el formulario carga su reseña para editarla', (
    tester,
  ) async {
    datos = ResenasFalsas(iniciales: [resena('yo', 3, comment: 'Regular')]);
    await abrir(tester, estudiante: 'yo');

    expect(find.text('Editar tu reseña'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('campo-comentario')))
          .controller!
          .text,
      'Regular',
    );
    expect(find.text('Actualizar reseña'), findsOneWidget);
  });

  testWidgets('el catálogo abre las reseñas de la disciplina', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: SamanColors.tema(),
        home: BuscadorScreen(
          controller: BuscadorController(
            datos: BuscadorDemoService(latencia: Duration.zero),
            estudianteId: 'est-01',
          ),
          paginaDeResenas: (deporte, estudianteId) =>
              Text('Reseñas de ${deporte.id} para $estudianteId'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tarjeta-AJE-01')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('boton-ver-resenas')));
    await tester.pumpAndSettle();
    expect(find.text('Reseñas de AJE-01 para est-01'), findsOneWidget);
  });
}
