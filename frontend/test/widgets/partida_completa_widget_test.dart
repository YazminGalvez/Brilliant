import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('Widgets: partida completa', () {
    Finder celda(int fila, int columna) =>
        find.byKey(Key('cell-$fila-$columna'));

    Finder lanzamiento(int numero) =>
        find.byKey(Key('dice-roll-history-item-$numero'));

    Finder movimiento(int numero) =>
        find.byKey(Key('movement-history-item-$numero'));

    Future<void> comenzarPartidaNueva(
      WidgetTester tester,
      List<int> dados,
    ) async {
      await abrirPantallaNueva(tester, random: DadosFijos(dados));
      await ingresarNumerosIniciales(tester);
      await tocar(tester, find.byKey(const Key('start-game')));
    }

    Future<void> jugarTurno(
      WidgetTester tester, {
      required int ancla,
      required (int, int) destino,
    }) async {
      await lanzarDados(tester);
      await elegirAncla(tester, ancla);
      await tocarDestino(tester, destino.$1, destino.$2);
    }

    testWidgets('Se juega un turno completo solo con los botones', (
      tester,
    ) async {
      await comenzarPartidaNueva(tester, [1, 2]);
      expect(find.byKey(const Key('start-game')), findsNothing);
      expect(find.byKey(const Key('roll-dice-button')), findsOneWidget);

      await jugarTurno(tester, ancla: 1, destino: (1, 2));

      expect(
        find.descendant(of: celda(1, 2), matching: find.text('2')),
        findsOneWidget,
      );
      expect(find.text('Tirada 1: 1 y 2'), findsOneWidget);
      expect(lanzamiento(1), findsOneWidget);
      expect(lanzamiento(2), findsNothing);
      expect(
        find.text('Tirada 1: colocaste el 2 en fila 1, columna 2 (ancla 1)'),
        findsOneWidget,
      );
      expect(movimiento(1), findsOneWidget);
      expect(movimiento(2), findsNothing);
    });

    testWidgets('Tres turnos seguidos hacen crecer los dos historiales', (
      tester,
    ) async {
      await comenzarPartidaNueva(tester, [1, 2, 3, 4, 5, 6]);

      await jugarTurno(tester, ancla: 1, destino: (1, 2));
      expect(lanzamiento(1), findsOneWidget);
      expect(movimiento(1), findsOneWidget);
      expect(lanzamiento(2), findsNothing);
      expect(movimiento(2), findsNothing);

      await jugarTurno(tester, ancla: 3, destino: (4, 1));
      expect(lanzamiento(2), findsOneWidget);
      expect(movimiento(2), findsOneWidget);
      expect(lanzamiento(3), findsNothing);
      expect(movimiento(3), findsNothing);

      await jugarTurno(tester, ancla: 5, destino: (6, 2));
      expect(lanzamiento(3), findsOneWidget);
      expect(movimiento(3), findsOneWidget);
      expect(lanzamiento(4), findsNothing);
      expect(movimiento(4), findsNothing);

      expect(
        find.descendant(of: celda(1, 2), matching: find.text('2')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: celda(4, 1), matching: find.text('4')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: celda(6, 2), matching: find.text('6')),
        findsOneWidget,
      );
      expect(find.text('Tirada 3: 5 y 6'), findsOneWidget);
      expect(
        find.text('Tirada 3: colocaste el 6 en fila 6, columna 2 (ancla 5)'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Se puede jugar desde una partida casi terminada hasta el final',
      (tester) async {
        await abrirPartida(
          tester,
          partidaCasiTerminada(),
          random: DadosFijos([1, 3]),
        );
        expect(find.byKey(const Key('game-over-panel')), findsNothing);

        await jugarTurno(tester, ancla: 1, destino: (7, 7));

        expect(
          find.descendant(of: celda(7, 7), matching: find.text('3')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('game-over-panel')), findsOneWidget);
        expect(find.text('Partida terminada'), findsOneWidget);
        expect(find.text('Fin del juego'), findsOneWidget);
      },
    );
  });
}
