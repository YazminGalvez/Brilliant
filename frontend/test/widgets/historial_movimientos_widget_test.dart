import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/panel_historial_movimientos.dart';
import 'package:juego_brilliant/historial_movimientos.dart';

import '../helpers.dart';

void main() {
  group('Widgets: historial de movimientos', () {
    final panel = find.byKey(const Key('movement-history-panel'));

    Finder item(int numero) => find.byKey(Key('movement-history-item-$numero'));

    Finder textoEnItem(int numero, String texto) =>
        find.descendant(of: item(numero), matching: find.text(texto));

    testWidgets('Un historial vacío dice que aún no hay movimientos', (
      tester,
    ) async {
      await abrirPartida(tester, partidaEnJuego());

      expect(panel, findsOneWidget);
      expect(find.byKey(const Key('movement-history-empty')), findsOneWidget);
      expect(find.text('Aún no hay movimientos.'), findsOneWidget);
      expect(find.byKey(const Key('movement-history-list')), findsNothing);
    });

    testWidgets(
      'Al colocar un número se anota con su fila y columna contadas desde 1',
      (tester) async {
        await abrirPartida(
          tester,
          partidaEnJuego(),
          random: DadosFijos([1, 2]),
        );
        await lanzarDados(tester);
        await elegirAncla(tester, 1);

        await tocarDestino(tester, 1, 2);

        expect(find.byKey(const Key('movement-history-list')), findsOneWidget);
        expect(
          textoEnItem(
            1,
            'Tirada 1: colocaste el 2 en fila 1, columna 2 (ancla 1)',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('Al saltar el turno se anota que saltaste el turno', (
      tester,
    ) async {
      await abrirPartida(
        tester,
        partidaCasiTerminada(),
        random: DadosFijos([2, 3]),
      );
      await lanzarDados(tester);

      await tocar(tester, find.byKey(const Key('skip-turn-button')));

      expect(textoEnItem(1, 'Tirada 1: saltaste el turno'), findsOneWidget);
    });

    testWidgets(
      'Al completar una zona se anotan en orden la colocación, la zona y los puntos',
      (tester) async {
        final partida = partidaEnJuego();
        partida.tablero.colocarDato(1, 2, 1);
        partida.tablero.colocarDato(1, 3, 1);
        await abrirPartida(tester, partida, random: DadosFijos([1, 1]));
        await lanzarDados(tester);
        await elegirAncla(tester, 1);

        await tocarDestino(tester, 3, 4);

        expect(
          textoEnItem(
            1,
            'Tirada 1: colocaste el 1 en fila 3, columna 4 (ancla 1)',
          ),
          findsOneWidget,
        );
        expect(
          textoEnItem(2, 'Tirada 1: completaste la zona azul'),
          findsOneWidget,
        );
        expect(textoEnItem(3, 'Tirada 1: ganaste 7 puntos'), findsOneWidget);
        expect(item(4), findsNothing);
      },
    );

    testWidgets('Ganar un solo punto se anota en singular', (tester) async {
      final historial = HistorialMovimientos()
        ..registrarPuntosGanados(numeroTirada: 1, puntos: 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PanelHistorialMovimientos(
              historial: historial,
              nombreDeZona: (_) => 'Verde',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(textoEnItem(1, 'Tirada 1: ganaste 1 punto'), findsOneWidget);
    });

    testWidgets('El movimiento más reciente aparece arriba', (tester) async {
      await abrirPartida(
        tester,
        partidaEnJuego(),
        random: DadosFijos([1, 2, 3, 4]),
      );
      await lanzarDados(tester);
      await elegirAncla(tester, 1);
      await tocarDestino(tester, 1, 2);
      await lanzarDados(tester);
      await elegirAncla(tester, 3);

      await tocarDestino(tester, 4, 1);

      expect(
        textoEnItem(
          2,
          'Tirada 2: colocaste el 4 en fila 4, columna 1 (ancla 3)',
        ),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(item(2)).dy,
        lessThan(tester.getTopLeft(item(1)).dy),
      );
    });

    testWidgets(
      'El panel de movimientos queda debajo del de lanzamientos en pantalla angosta y ancha',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final lanzamientos = find.byKey(const Key('dice-roll-history-panel'));

        tester.view.physicalSize = const Size(700, 1000);
        await abrirPartida(tester, partidaEnJuego());
        expect(
          tester.getRect(panel).top,
          greaterThan(tester.getRect(lanzamientos).bottom),
        );

        tester.view.physicalSize = const Size(1200, 1000);
        await tester.pumpAndSettle();
        expect(
          tester.getRect(panel).top,
          greaterThan(tester.getRect(lanzamientos).bottom),
        );
        expect(tester.getRect(panel).left, tester.getRect(lanzamientos).left);
      },
    );
  });
}
