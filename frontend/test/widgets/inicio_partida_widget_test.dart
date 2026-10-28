import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/lanzamiento_dados.dart';
import 'package:juego_brilliant/mapa_uno.dart';

import '../helpers.dart';

void main() {
  group('Widgets: inicio de la partida', () {
    final celdasIniciales = mapaUno.celdasIniciales;

    Finder celda(int fila, int columna) =>
        find.byKey(Key('cell-$fila-$columna'));

    testWidgets(
      'Antes de Inicio no aparecen los dados ni los paneles de historial',
      (tester) async {
        await abrirPantallaNueva(tester);
        await ingresarNumerosIniciales(tester);

        expect(find.byType(LanzamientoDados), findsNothing);
        expect(find.byKey(const Key('roll-dice-button')), findsNothing);
        expect(find.byKey(const Key('dice-roll-history-panel')), findsNothing);
        expect(find.byKey(const Key('movement-history-panel')), findsNothing);
      },
    );

    testWidgets(
      'Tocar Inicio con los seis números arranca la partida y quita el botón',
      (tester) async {
        await abrirPantallaNueva(tester);
        await ingresarNumerosIniciales(tester);

        await tocar(tester, find.byKey(const Key('start-game')));

        expect(find.byKey(const Key('roll-dice-button')), findsOneWidget);
        expect(find.byKey(const Key('start-game')), findsNothing);
        expect(find.byKey(const Key('dice-roll-history-panel')), findsOneWidget);
        expect(find.byKey(const Key('movement-history-panel')), findsOneWidget);
      },
    );

    testWidgets(
      'Después de comenzar tocar una celda inicial no abre el diálogo',
      (tester) async {
        await abrirPantallaNueva(tester);
        await ingresarNumerosIniciales(tester);
        await tocar(tester, find.byKey(const Key('start-game')));

        for (final (fila, columna) in celdasIniciales) {
          expect(tester.widget<InkWell>(celda(fila, columna)).onTap, isNull);
          await tocar(tester, celda(fila, columna));
          expect(find.byType(SimpleDialog), findsNothing);
        }
      },
    );

    testWidgets('Una partida ya iniciada se abre directamente en juego', (
      tester,
    ) async {
      await abrirPartida(tester, partidaEnJuego());

      expect(find.byKey(const Key('roll-dice-button')), findsOneWidget);
      expect(find.byKey(const Key('start-game')), findsNothing);
      expect(find.text('Partida en curso'), findsOneWidget);
    });

    testWidgets(
      'Antes de comenzar las celdas que no son iniciales no se pueden tocar',
      (tester) async {
        await abrirPantallaNueva(tester);

        for (var fila = 1; fila <= 7; fila++) {
          for (var columna = 1; columna <= 7; columna++) {
            if (celdasIniciales.contains((fila, columna))) continue;
            expect(
              tester.widget<InkWell>(celda(fila, columna)).onTap,
              isNull,
              reason: 'celda ($fila, $columna)',
            );
          }
        }

        await tocar(tester, celda(4, 4));
        expect(find.byType(SimpleDialog), findsNothing);
      },
    );
  });
}
