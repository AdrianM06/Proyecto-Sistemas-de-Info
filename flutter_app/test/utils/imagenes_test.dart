import 'package:flutter/material.dart';
import 'package:flutter_app/utils/imagenes.dart';
import 'package:flutter_app/views/estudiante/estudiante_scaffold.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pixelesFisicos multiplica por la densidad de la pantalla', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    late int pixeles;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            pixeles = pixelesFisicos(context, 40);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(pixeles, 110);
  });

  testWidgets('el logo de la barra se decodifica al tamaño en que se ve', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: EstudianteScaffold(
          seccion: SeccionEstudiante.inicio,
          body: SizedBox.shrink(),
        ),
      ),
    );

    final logo = tester
        .widgetList<Image>(find.byType(Image))
        .firstWhere((imagen) => imagen.image is ResizeImage);
    final redimensionada = logo.image as ResizeImage;
    // 40 px lógicos × 2 = 80 px, en lugar de los 2000 px del archivo.
    expect(redimensionada.height, 80);
    expect(
      (redimensionada.imageProvider as AssetImage).assetName,
      'assets/images/unimet_sports_logo.png',
    );
  });
}
