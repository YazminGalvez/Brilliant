import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juego_brilliant/partida.dart';

import '../helpers.dart';

void main() {
  group('Widgets: fin de la partida', () {
    final panelFin = find.byKey(const Key('game-over-panel'));
    final puntuacionFinal = find.byKey(const Key('final-score'));
    final puntuacionTotal = find.byKey(const Key('total-score'));
    final botonLanzar = find.byKey(const Key('roll-dice-button'));
    final botonInicio = find.byKey(const Key('start-game'));
    final botonNuevaPartida = find.byKey(const Key('new-game-button'));

    String? textoDe(WidgetTester tester, Finder finder) =>
        tester.widget<Text>(finder).data;

    Future<Partida> llenarUltimaCelda(
      WidgetTester tester, {
      List<int> dadosSiguientes = const [],
    }) async {
      final partida = partidaCasiTerminada();
      await abrirPartida(
        tester,
        partida,
        random: DadosFijos([1, 3, ...dadosSiguientes]),
      );
      await lanzarDados(tester);
      await elegirAncla(tester, 1);
      await tocarDestino(tester, 7, 7);
      return partida;
    }

    Future<void> ingresarNumerosDelMapaVerde(WidgetTester tester) async {
      await ingresarNumeroInicial(tester, (1, 1), 1);
      await ingresarNumeroInicial(tester, (1, 2), 2);
      await ingresarNumeroInicial(tester, (1, 3), 3);
      await ingresarNumeroInicial(tester, (1, 4), 4);
      await ingresarNumeroInicial(tester, (1, 5), 5);
      await ingresarNumeroInicial(tester, (1, 6), 6);
    }

    testWidgets(
      'Llenar la última celda muestra el panel de fin con la puntuación final',
      (tester) async {
        final partida = partidaCasiTerminada();
        await abrirPartida(tester, partida, random: DadosFijos([1, 3]));
        expect(panelFin, findsNothing);

        await lanzarDados(tester);
        await elegirAncla(tester, 1);
        await tocarDestino(tester, 7, 7);

        expect(partida.estado, EstadoPartida.terminada);
        expect(panelFin, findsOneWidget);
        expect(
          find.descendant(
            of: panelFin,
            matching: find.text('Partida terminada'),
          ),
          findsOneWidget,
        );
        expect(
          textoDe(tester, puntuacionFinal),
          'Puntuación final: ${partida.puntuacionTotal} de '
          '${partida.puntuacionMaxima}',
        );
        expect(textoDe(tester, puntuacionFinal), 'Puntuación final: 4 de 4');
      },
    );

    testWidgets(
      'Al terminar la partida no se puede lanzar ni aparece saltar turno',
      (tester) async {
        await llenarUltimaCelda(tester);

        expect(tester.widget<FilledButton>(botonLanzar).onPressed, isNull);
        expect(find.byKey(const Key('skip-turn-button')), findsNothing);
        expect(find.byKey(const Key('no-moves-message')), findsNothing);
      },
    );

    testWidgets('La puntuación final coincide con el marcador total', (
      tester,
    ) async {
      final partida = await llenarUltimaCelda(tester);

      expect(
        textoDe(tester, puntuacionTotal),
        'Puntuación total: ${partida.puntuacionTotal}',
      );
      expect(
        textoDe(tester, puntuacionFinal),
        startsWith('Puntuación final: ${partida.puntuacionTotal} de'),
      );
    });

    testWidgets(
      'Nueva partida regresa a la preparación con las celdas vacías y sin puntos',
      (tester) async {
        final partida = await llenarUltimaCelda(tester);

        await tocar(tester, botonNuevaPartida);

        expect(partida.estado, EstadoPartida.preparando);
        expect(botonInicio, findsOneWidget);
        expect(tester.widget<FilledButton>(botonInicio).onPressed, isNull);
        expect(panelFin, findsNothing);
        expect(botonLanzar, findsNothing);
        expect(partida.tablero.valoresColocados, isEmpty);
        expect(find.text('+'), findsNWidgets(6));
        for (var numero = 1; numero <= 6; numero++) {
          expect(find.text('$numero'), findsNothing);
        }
        expect(partida.puntuacionTotal, 0);
        expect(puntuacionTotal, findsNothing);
      },
    );

    testWidgets(
      'Después de Nueva partida se puede volver a preparar y comenzar a jugar',
      (tester) async {
        final partida = await llenarUltimaCelda(
          tester,
          dadosSiguientes: [1, 2],
        );
        await tocar(tester, botonNuevaPartida);

        await ingresarNumerosDelMapaVerde(tester);
        expect(tester.widget<FilledButton>(botonInicio).onPressed, isNotNull);
        await tocar(tester, botonInicio);

        expect(partida.estado, EstadoPartida.jugando);
        expect(botonInicio, findsNothing);
        expect(textoDe(tester, puntuacionTotal), 'Puntuación total: 0');
        expect(find.text('Aún no hay lanzamientos.'), findsOneWidget);
        expect(find.text('Aún no hay movimientos.'), findsOneWidget);

        await lanzarDados(tester);
        await elegirAncla(tester, 1);
        await tocarDestino(tester, 2, 1);

        expect(partida.tablero.obtenerCelda(1, 0).valor, 2);
        expect(find.text('Tirada 1: 1 y 2'), findsOneWidget);
      },
    );
  });
}
