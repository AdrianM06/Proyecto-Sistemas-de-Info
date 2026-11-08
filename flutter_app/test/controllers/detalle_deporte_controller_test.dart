import 'package:flutter_app/controllers/detalle_deporte_controller.dart';
import 'package:flutter_app/models/resena.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/resenas_falsas.dart';

void main() {
  Future<void> esperar() => Future<void>.delayed(Duration.zero);

  DetalleDeporteController crear(ResenasFalsas datos, {String? estudiante}) =>
      DetalleDeporteController(
        datos: datos,
        deporteId: 'AJE-01',
        estudianteId: estudiante,
      );

  test('sin reseñas no hay promedio', () async {
    final datos = ResenasFalsas();
    final c = crear(datos)..iniciar();
    expect(c.cargando, isTrue);

    datos.emitir();
    await esperar();
    expect(c.cargando, isFalse);
    expect(c.promedio, isNull);
    expect(c.cantidad, 0);
    c.dispose();
  });

  test('el promedio se recalcula en tiempo real', () async {
    final datos = ResenasFalsas(
      iniciales: [resena('a', 5), resena('b', 4), resena('c', 3)],
    );
    final c = crear(datos)..iniciar();
    datos.emitir();
    await esperar();
    expect(c.promedio, 4.0);
    expect(c.cantidad, 3);

    datos.lista.add(resena('d', 1));
    datos.emitir();
    await esperar();
    expect(c.promedio, 3.25);
    expect(c.cantidad, 4);
    c.dispose();
  });

  test('reconoce la reseña del estudiante con sesión', () async {
    final datos = ResenasFalsas(iniciales: [resena('a', 5), resena('yo', 2)]);
    final c = crear(datos, estudiante: 'yo')..iniciar();
    datos.emitir();
    await esperar();
    expect(c.miResena?.rating, 2);
    c.dispose();
  });

  test('sin sesión solo se leen las reseñas', () async {
    final datos = ResenasFalsas();
    final c = crear(datos)..iniciar();
    datos.emitir();
    await esperar();

    expect(c.haySesion, isFalse);
    expect(c.puedeResenar, isFalse);
    expect(
      await c.publicar(rating: 5, comment: 'Hola'),
      contains('Inicia sesión'),
    );
    expect(datos.guardados, 0);
    c.dispose();
  });

  test('un estudiante que no participó no puede publicar', () async {
    final datos = ResenasFalsas(participa: false);
    final c = crear(datos, estudiante: 'yo')..iniciar();
    datos.emitir();
    await esperar();

    expect(c.puedeResenar, isFalse);
    expect(await c.publicar(rating: 5, comment: 'Hola'), contains('inscritos'));
    expect(datos.guardados, 0);
    c.dispose();
  });

  test('valida estrellas y comentario antes de enviar', () {
    expect(DetalleDeporteController.validar(0, 'Hola'), contains('estrellas'));
    expect(DetalleDeporteController.validar(6, 'Hola'), contains('estrellas'));
    expect(DetalleDeporteController.validar(4, '   '), contains('comentario'));
    expect(
      DetalleDeporteController.validar(4, 'a' * (Resena.largoMaximo + 1)),
      contains('500'),
    );
    expect(DetalleDeporteController.validar(4, 'Excelente'), isNull);
  });

  test('publica una reseña nueva y luego la actualiza', () async {
    final datos = ResenasFalsas();
    final c = crear(datos, estudiante: 'yo')..iniciar();
    datos.emitir();
    await esperar();

    expect(await c.publicar(rating: 4, comment: '  Muy buena  '), isNull);
    await esperar();
    expect(datos.ultimaEsNueva, isTrue);
    expect(datos.lista.single.comment, 'Muy buena');
    expect(c.miResena?.rating, 4);

    expect(await c.publicar(rating: 2, comment: 'Cambié de opinión'), isNull);
    await esperar();
    expect(datos.ultimaEsNueva, isFalse);
    expect(c.promedio, 2.0);
    c.dispose();
  });

  test('un error al guardar devuelve el mensaje del servicio', () async {
    final datos = ResenasFalsas()
      ..fallo = 'No tienes permiso para publicar esta reseña.';
    final c = crear(datos, estudiante: 'yo')..iniciar();
    datos.emitir();
    await esperar();

    expect(await c.publicar(rating: 3, comment: 'Ok'), contains('permiso'));
    expect(c.enviando, isFalse);
    c.dispose();
  });

  test('si la carga falla queda un mensaje de error', () async {
    final datos = ResenasFalsas();
    final c = crear(datos)..iniciar();
    datos.fallarCarga();
    await esperar();
    expect(c.errorCarga, isNotNull);
    expect(c.cargando, isFalse);
    c.dispose();
  });

  test('si la pantalla se cierra, las reseñas que llegan no fallan', () async {
    final datos = ResenasFalsas();
    final c = crear(datos, estudiante: 'yo')..iniciar();
    c.dispose();
    datos.emitir();
    await esperar();
  });
}
