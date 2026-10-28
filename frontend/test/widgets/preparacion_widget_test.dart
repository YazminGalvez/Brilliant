import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juego_brilliant/mapa_uno.dart';

import '../helpers.dart';

void main() {
  group('Widgets: preparación de la partida', () {
    final celdasIniciales = mapaUno.celdasIniciales;
    const mensajeFaltantes =
        'Faltan números iniciales: ingresa del 1 al 6 sin repetir.';

    Finder celda(int fila, int columna) =>
        find.byKey(Key('cell-$fila-$columna'));

    Finder textoEnCelda((int, int) coordenada, String texto) => find.descendant(
      of: celda(coordenada.$1, coordenada.$2),
      matching: find.text(texto),
    );

    FilledButton botonInicio(WidgetTester tester) =>
        tester.widget<FilledButton>(find.byKey(const Key('start-game')));

    Finder opcionDelDialogo(String texto) => find.descendant(
      of: find.byType(SimpleDialog),
      matching: find.text(texto),
    );

    testWidgets(
      'Al abrir la pantalla Inicio está deshabilitado y se avisa que faltan números',
      (tester) async {
        await abrirPantallaNueva(tester);

        expect(find.byKey(const Key('start-game')), findsOneWidget);
        expect(botonInicio(tester).onPressed, isNull);
        expect(find.text(mensajeFaltantes), findsOneWidget);
      },
    );

    testWidgets(
      'Solo las seis celdas iniciales muestran un "+" y se pueden tocar',
      (tester) async {
        await abrirPantallaNueva(tester);

        for (var fila = 1; fila <= 7; fila++) {
          for (var columna = 1; columna <= 7; columna++) {
            final esInicial = celdasIniciales.contains((fila, columna));
            final razon = 'celda ($fila, $columna)';

            expect(
              tester.widget<InkWell>(celda(fila, columna)).onTap,
              esInicial ? isNotNull : isNull,
              reason: razon,
            );
            expect(
              textoEnCelda((fila, columna), '+'),
              esInicial ? findsOneWidget : findsNothing,
              reason: razon,
            );
          }
        }
      },
    );

    testWidgets(
      'El diálogo no ofrece los números ya usados en otra celda inicial',
      (tester) async {
        await abrirPantallaNueva(tester);
        await ingresarNumeroInicial(tester, celdasIniciales[0], 2);
        await ingresarNumeroInicial(tester, celdasIniciales[1], 5);

        final (fila, columna) = celdasIniciales[2];
        await tocar(tester, celda(fila, columna));

        expect(find.byType(SimpleDialog), findsOneWidget);
        for (final numero in [1, 3, 4, 6]) {
          expect(opcionDelDialogo('$numero'), findsOneWidget);
        }
        expect(opcionDelDialogo('2'), findsNothing);
        expect(opcionDelDialogo('5'), findsNothing);
      },
    );

    testWidgets('Elegir un número en el diálogo lo muestra en esa celda', (
      tester,
    ) async {
      await abrirPantallaNueva(tester);
      final coordenada = celdasIniciales[3];

      await ingresarNumeroInicial(tester, coordenada, 4);

      expect(find.byType(SimpleDialog), findsNothing);
      expect(textoEnCelda(coordenada, '4'), findsOneWidget);
      expect(textoEnCelda(coordenada, '+'), findsNothing);
    });

    testWidgets('Con cinco de los seis números Inicio sigue deshabilitado', (
      tester,
    ) async {
      await abrirPantallaNueva(tester);

      await ingresarNumerosIniciales(tester, cantidad: 5);

      expect(botonInicio(tester).onPressed, isNull);
      expect(find.text(mensajeFaltantes), findsOneWidget);
    });

    testWidgets('Con los números del 1 al 6 Inicio se habilita', (
      tester,
    ) async {
      await abrirPantallaNueva(tester);

      await ingresarNumerosIniciales(tester);

      expect(botonInicio(tester).onPressed, isNotNull);
      expect(find.text(mensajeFaltantes), findsNothing);
    });

    testWidgets('Vaciar una celda inicial vuelve a deshabilitar Inicio', (
      tester,
    ) async {
      await abrirPantallaNueva(tester);
      await ingresarNumerosIniciales(tester);
      expect(botonInicio(tester).onPressed, isNotNull);

      final coordenada = celdasIniciales[2];
      await vaciarCeldaInicial(tester, coordenada);

      expect(botonInicio(tester).onPressed, isNull);
      expect(textoEnCelda(coordenada, '3'), findsNothing);
      expect(textoEnCelda(coordenada, '+'), findsOneWidget);
      expect(find.text(mensajeFaltantes), findsOneWidget);
    });
  });
}
