import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('Widgets: historial de lanzamientos', () {
    final panel = find.byKey(const Key('dice-roll-history-panel'));

    Finder item(int numero) =>
        find.byKey(Key('dice-roll-history-item-$numero'));

    void usarPantalla(WidgetTester tester, Size tamano) {
      tester.view.physicalSize = tamano;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    testWidgets('Un historial vacío dice que aún no hay lanzamientos', (
      tester,
    ) async {
      await abrirPartida(tester, partidaEnJuego(), random: DadosFijos([]));

      expect(panel, findsOneWidget);
      expect(find.byKey(const Key('dice-roll-history-empty')), findsOneWidget);
      expect(find.text('Aún no hay lanzamientos.'), findsOneWidget);
      expect(find.byKey(const Key('dice-roll-history-list')), findsNothing);
    });

    testWidgets('Después de lanzar aparece la tirada 1 con los valores fijos', (
      tester,
    ) async {
      await abrirPartida(tester, partidaEnJuego(), random: DadosFijos([2, 5]));

      await lanzarDados(tester);

      expect(find.byKey(const Key('dice-roll-history-empty')), findsNothing);
      expect(find.byKey(const Key('dice-roll-history-list')), findsOneWidget);
      expect(
        find.descendant(of: item(1), matching: find.text('Tirada 1: 2 y 5')),
        findsOneWidget,
      );
    });

    testWidgets(
      'Varios lanzamientos seguidos se listan con el más reciente arriba',
      (tester) async {
        await abrirPartida(
          tester,
          partidaEnJuego(),
          random: DadosFijos([1, 2, 3, 4, 5, 6]),
        );

        await lanzarDados(tester);
        await lanzarDados(tester);
        await lanzarDados(tester);

        expect(find.text('Tirada 1: 1 y 2'), findsOneWidget);
        expect(find.text('Tirada 2: 3 y 4'), findsOneWidget);
        expect(find.text('Tirada 3: 5 y 6'), findsOneWidget);
        expect(
          tester.getTopLeft(item(3)).dy,
          lessThan(tester.getTopLeft(item(2)).dy),
        );
        expect(
          tester.getTopLeft(item(2)).dy,
          lessThan(tester.getTopLeft(item(1)).dy),
        );
      },
    );

    testWidgets(
      'En pantalla ancha el historial queda a la derecha del tablero',
      (tester) async {
        usarPantalla(tester, const Size(1200, 1000));

        await abrirPartida(tester, partidaEnJuego());

        final tablero = tester.getRect(find.byKey(const Key('cell-1-7')));
        expect(tester.getRect(panel).left, greaterThan(tablero.right));
        expect(
          tester.getRect(panel).top,
          lessThan(tester.getRect(find.byKey(const Key('cell-7-7'))).bottom),
        );
      },
    );

    testWidgets('En pantalla angosta el historial queda debajo del tablero', (
      tester,
    ) async {
      usarPantalla(tester, const Size(700, 1000));

      await abrirPartida(tester, partidaEnJuego());

      final tablero = tester.getRect(find.byKey(const Key('cell-7-1')));
      expect(tester.getRect(panel).top, greaterThan(tablero.bottom));
    });

    testWidgets('El historial solo aparece cuando la partida ya comenzó', (
      tester,
    ) async {
      await abrirPantallaNueva(tester);
      await ingresarNumerosIniciales(tester);
      expect(panel, findsNothing);

      await tocar(tester, find.byKey(const Key('start-game')));

      expect(panel, findsOneWidget);
    });
  });
}
